
require 'json'

require_relative '../Libs/ColorUtils.rb'
require_relative '../Libs/MQTTSubscriber.rb'

module ColorSpeak
class Server
	def initialize(led, mqtt)
		@led = led;
		@mqtt = mqtt;

		@userColor = Color.RGB(0, 0, 0);
		@speaking = false;

		@speechQueue = Hash.new() do |h, k|
			h[k] = Array.new();
		end

		@mqtt.subscribeTo "Room/TTS/+" do |t, data|
			h = JSON.parse(data);
			return unless h.key? "text";

			begin
				c = h.key?("color") ? Color.from_s(h["color"]) : nil;
			rescue
				c = nil;
			end
			queueWords(t[0], h["text"], c);
		end

		@mqtt.subscribeTo "Room/Light/Set/Color" do |t, data|
			@userColor = Color.from_s(data);
			updateDefaultColor();
		end

		@mqtt.subscribeTo "Room/Light/Set/Switch" do |t, data|
			@lightOn = (data == "on")
			updateDefaultColor();
		end

		@mqtt.subscribeTo "Room/Commands" do |tList, data|
			if(data == "e") then
				@lightOn = not(@lightOn);
				updateDefaultColor();
			elsif(data == "ld") then
				@lightOn = true;
				@userColor = Color.RGB(0, 0, 0);
				updateDefaultColor();
			elsif(data =~ /lh([\d]{1,3})/) then
				@lightOn = true;
				@userColor = Color.HSV($~[1].to_i);
				updateDefaultColor();
			elsif(data =~ /l([\da-f]{6})/) then
				@lightOn = true;
				@userColor = Color.from_s("#" + $~[1]);
				updateDefaultColor();
			end
		end

		Thread.new() {
			while true do 
				sleep 10
				updateDefaultColor(10) unless (@skipUpdateColor or not(@lightOn))
				@skipUpdateColor = false;
			end
		}.abort_on_exception = true
	end

	def get_recommended_color()
		return Color.daylight if @userColor.black?
		return Color.daylight(@userColor.get_brightness/255.0) if @userColor.white?
		return @userColor;
	end

	def get_current_color()
		return Color.RGB(0, 0, 0) unless @lightOn;
		return get_recommended_color();
	end

	def updateDefaultColor(fadeSpeed = 3)
		@skipUpdateColor = true;
		rColor = get_current_color

		@mqtt.publishTo "Room/Light/Color",  rColor.to_s, retain: true, qos: 1;
		@mqtt.publishTo "Room/Light/Switch", @lightOn ? "on" : "off", retain: true, qos: 1;
		@led.sendRGB(rColor, fadeSpeed) unless @speaking;
	end

	def queueWords(id, t, c = nil)
		@speechQueue[id].push({t: t, c: c});

		return if @speaking;

		@speaking = true;
		@speechThread = Thread.new() {
			speakOutQueue();
		}
		@speechThread.abort_on_exception = true;
	end

	def speakOutQueue()
		@speaking = true;

		speechBrightness = [get_recommended_color().get_brightness, 50].max();

		until @speechQueue.empty?
			k = @speechQueue.keys[0];
			v = @speechQueue[k];
			while h = v.shift
				next if h[:t] =~ /[^\w\s\.,-:+']/;

				@led.sendRGB(h[:c] ? h[:c].set_brightness(speechBrightness) : get_current_color, 0.5);
				system('espeak -s 140 -g 3 -a 200 "' + h[:t] + '" --stdout 2>/dev/null | aplay >/dev/null 2>&1');
			end

			@speechQueue.delete k;
		end

		@speaking = false;
		updateDefaultColor(0.5);
	end
end

class Client
	def initialize(mqtt, topic)
		@mqtt = mqtt;

		@topic = topic;
	end

	def speak(t, c = nil)
		outData = {
			text: t
		};
		outData[:color] = c if c;

		@mqtt.publishTo "Room/TTS/#{@topic}", outData.to_json;
	end
end
end


require 'json'

require_relative '../Libs/ColorUtils.rb'
require_relative '../Libs/MQTTSubscriber.rb'
require_relative '../Libs/Waitpoint.rb'

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

		@newMessageWaitpoint = Xasin::Waitpoint.new();

		@mqtt.subscribeTo "Room/TTS/+" do |t, data|
			h = JSON.parse(data, symbolize_names: true);

			begin
				h[:color] = h.key?(:color) ? Color.from_s(h[:color]) : nil;
			rescue
				h[:color] = nil;
			end
			queue_message(t[0], h);
		end

		@mqtt.subscribeTo "Room/Light/Set/Color" do |t, data|
			@userColor = Color.from_s(data);
			update_current_color();
		end

		@mqtt.subscribeTo "Room/Light/Set/Switch" do |t, data|
			@lightOn = (data == "on")
			update_current_color();
		end

		@mqtt.subscribeTo "Room/Commands" do |tList, data|
			if(data == "e") then
				@lightOn = not(@lightOn);
				update_current_color();
			elsif(data == "ld") then
				@lightOn = true;
				@userColor = Color.RGB(0, 0, 0);
				update_current_color();
			elsif(data =~ /lh([\d]{1,3})/) then
				@lightOn = true;
				@userColor = Color.HSV($~[1].to_i);
				update_current_color();
			elsif(data =~ /l([\da-f]{6})/) then
				@lightOn = true;
				@userColor = Color.from_s("#" + $~[1]);
				update_current_color();
			end
		end

		Thread.new() do
			while true do
				sleep 10
				update_current_color(10) unless (@skipUpdateColor or not(@lightOn))
				@skipUpdateColor = false;
			end
		end

		Thread.new do
			speak_out_queue();
		end.abort_on_exception = true;
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

	def update_current_color(fadeSpeed = 3)
		@skipUpdateColor = true;
		rColor = get_current_color

		@mqtt.publishTo "Room/Light/Color",  rColor.to_s, retain: true, qos: 1;
		@mqtt.publishTo "Room/Light/Switch", @lightOn ? "on" : "off", retain: true, qos: 1;
		@led.sendRGB(rColor, fadeSpeed) unless @speaking;
	end

	def queue_message(id, data)
		@speechQueue.delete id if(data[:single]);

		@speechQueue[id].push(data);

		@newMessageWaitpoint.fire();
	end

	def speak_out_queue()
		@newMessageWaitpoint.wait();

		until @speechQueue.empty?
			k = @speechQueue.keys[0];
			v = @speechQueue[k];
			while h = v.shift
				next unless h.has_key? :text
				next if h[:text] =~ /[^\w\s\.,-:+']/;

				@speaking = true;
					speechBrightness = [get_recommended_color().get_brightness, 50].max();
					@led.sendRGB(h[:color] ? h[:color].set_brightness(speechBrightness) : get_current_color, 0.5);
					system('espeak -s 140 -g 3 -a 200"' + h[:text] + '" --stdout 2>/dev/null | aplay >/dev/null 2>&1');
				@speaking = false;
			end

			@speechQueue.delete k;
		end

		update_current_color(0.5);
	end
end

class Client
	def initialize(mqtt, topic)
		@mqtt = mqtt;

		@topic = topic;
	end

	def speak(t, c = nil, single: nil, notoast: false)
		outData = {
			text: t
		};
		outData[:color] 	= c 		if c;
		outData[:single] 	= true 	if single;
		outData[:notoast] = true	if notoast;

		@mqtt.publishTo "Room/TTS/#{@topic}", outData.to_json;
	end
end
end

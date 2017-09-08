
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

			c = h.key?("color") ? Color.from_s(h["color"]) : nil;
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

		Thread.new() {
			sleep 60;
			updateDefaultColor();
		}
	end

	def get_recommended_color()
		return Color.RGB(0, 0, 0) unless @lightOn;

		return Color.daylight if @userColor.black?
		return Color.daylight(@userColor.get_brightness/255.0) if @userColor.white?
		return @userColor;
	end

	def updateDefaultColor()
		rColor = get_recommended_color();

		@mqtt.publishTo "Room/Light/Color", rColor.to_s, retain: true;
		@led.sendRGB(rColor, 3) unless @speaking;
	end

	def queueWords(id, t, c)
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

				@led.sendRGB(h[:c] ? h[:c].set_brightness(speechBrightness) : @defaultC, 0.5);
				system('espeak -s 150 -g 3 "' + h[:t] + '" --stdout 2>/dev/null | aplay >/dev/null 2>&1');
			end

			@speechQueue.delete k;
		end

		@speaking = false;
		updateDefaultColor();
	end
end

class Client
	def initialize(mqtt, topic)
		@mqtt = mqtt;

		@topic = topic;
	end

	def speak(t, c = Color.RGB(255, 255, 255))
		@mqtt.publishTo "Room/TTS/#{@topic}", {text: t, color: c.to_s}.to_json;
	end
end
end

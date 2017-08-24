
require 'json'
require_relative 'Libs/ColorUtils.rb'

class ColorSpeak
	def initialize(led, mqtt)
		@led = led;
		@mqtt = mqtt;

		@defaultC = Color.temperature(7000);
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
			if(data == "#000000") then
				@defaultC.set_brightness(0);
			else
				@defaultC = Color.from_s(data).set_brightness(@defaultC.get_brightness);
			end

			updateDefaultColor();
		end

		@mqtt.subscribeTo "Room/Light/Set/Brightness" do |t, data|
			@defaultC.set_brightness(data.to_i);
			updateDefaultColor();
		end
	end

	def updateDefaultColor()
		@mqtt.publishTo "Room/Light/Color", @defaultC.to_s;
		@mqtt.publishTo "Room/Light/Brightness", @defaultC.get_brightness;

		@led.sendRGB(@defaultC, 3) unless @speaking;
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

		until @speechQueue.empty?
			k = @speechQueue.keys[0];
			v = @speechQueue[k];
			while h = v.shift
				next if h[:t] =~ /[^\w\s\.,-:+']/;

				@led.sendRGB(h[:c] ? h[:c].set_brightness([@defaultC.get_brightness, 20].max) : @defaultC, 0.5);
				system('espeak -s 150 -g 3 "' + h[:t] + '" --stdout 2>/dev/null | aplay >/dev/null 2>&1');
			end

			@speechQueue.delete k;
		end

		@led.sendRGB(@defaultC, 0.5);
		@speaking = false;
	end
end


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

		mqtt.subscribeTo "TTS/+" do |t, data|
			h = JSON.parse(data);
			return unless h.key? "text";

			queueWords(t[0], ["text"], Color.fromString(h["color"]));
		end
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

				@led.sendRGB(h[:c], 0.5) unless h[:c] == nil;
				system('espeak -s 150 -g 3 "' + h[:t] + '" --stdout | aplay &> /dev/null');
			end

			@speechQueue.delete k;
		end
		@led.sendRGB(@defaultC, 0.5);
		@speaking = false;
	end
end

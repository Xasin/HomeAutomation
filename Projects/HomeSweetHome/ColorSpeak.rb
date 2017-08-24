
require 'json'
require_relative 'Libs/ColorUtil.rb'

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
		@speechQueue[id] << {t: t, c: c};

		return if @speaking;
		@speaking = true;
		Thread.new() {
			speakOutQueue;
		}
	end

	def speakOutQueue()
		@speaking = true;

		@speechQueue.each_pair do |k, v|
			until v.empty?
				h = v.drop(1)[0];
				next if h[:t] =~ /[^\w\s\.,-:+']/;

				@led.sendRGB(h[:c], 0.5) unless h[:c] == nil;
				system('espeak -s 150 -g 3 "' + h[:t] + '" --stdout | aplay');
				@led.sendRGB(@defaultC, 0.5) unless h[:c] == nil;
				sleep 0.5;
			end

			@speechQueue.delete k;
		end

		@speaking = false;
	end
end

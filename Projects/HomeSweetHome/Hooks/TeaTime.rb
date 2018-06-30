
require 'json'

module Hooks
	module TeaTimer

		@teaTime = nil;

		def self._stop_teaTimer()
			$xasin.notify("Your tea is ready!", Color.RGB(255, 200, 100), {
				timer: @teaTime.to_i
			})

			@teaTime = nil;
		end

		def self._update_teaTimerInfo()
			unless @teaTime
				$mqtt.publish_to "Telegram/Xasin/Delete", "TeaTimerInfo"
				return;
			end

			remainingTime = (@teaTime - Time.now()).to_i;
			remainingTimeString = "#{(remainingTime/1.minutes).floor}:#{(remainingTime).floor % 60}"

			$mqtt.publish_to "Telegram/Xasin/Send", {
				gid: 			"TeaTimerInfo",
				overwrite: 	true,
				text:			"Tea will be ready in #{remainingTimeString}"
			}
		end

		def self.start_timer(duration = 5.minutes)
			@teaTime = Time.now() + duration;
			$xasin.notify("Tea timer has been set to #{(duration/1.minutes).round(1)} minutes!");

			@teaThread.run();
		end
		def self.abort_timer()
			$xasin.notify("Tea timer stopped.");
			@teaTime = nil;
			_update_teaTimerInfo();
		end

		@teaThread = Thread.new() do
			loop do
				sleep 5;
				Thread.stop() until @teaTime

				if((@teaTime - Time.now()).to_i <= 0)
					_stop_teaTimer();
				end

				_update_teaTimerInfo();
			end
		end

		$mqtt.subscribe_to "Telegram/Xasin/Command" do |data|
			begin
				data = JSON.parse(data);
				cmd = data["text"];
			rescue
				next;
			end

			case cmd
			when /^\/tea stop/
				abort_timer();
			when /^\/tea (\d+(?:\.\d+))/
				start_timer($1.to_i.minutes);
			end
		end

		$room.on_command do |cmd|
			if(cmd =~ /^tt/)
				start_timer();
			end
		end
	end
end

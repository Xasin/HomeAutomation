
require_relative '../SetupEnv.rb'

module Hooks
	module Wakeup

		@wakeupTTS = ColorSpeak::Client.new($mqtt, "Wakeup");

		@alarmTime = nil;
		@AlarmThread = Thread.new do
			while true do
				until @alarmTime do Thread.stop(); end

				if(Time.now() >= @alarmTime) then
					$mqtt.publishTo "Room/Commands", "good morning"
					$mqtt.publishTo "Room/Light/Set/Switch", "on";
					$mqtt.publishTo "Room/Light/Set/Color", Color.RGB(0, 0, 0);

					@wakeupTTS.speak "Good morning, David"

					@alarmTime = nil;
				else
					sleep [0.5, [2.minutes, (@alarmTime - Time.now())*0.9].min].max
				end
			end
		end

		$mqtt.subscribeTo "Room/Commands" do |t, data|
			if(data == "clk" and not @alarmTime) then
				@alarmTime =  Time.today(21.hours + 56.minutes);
				@alarmTime += 24.hours if @alarmTime <= Time.now();
				@wakeupTTS.speak "Alarm set for 7am"

				@AlarmThread.run
			end
		end
	end
end

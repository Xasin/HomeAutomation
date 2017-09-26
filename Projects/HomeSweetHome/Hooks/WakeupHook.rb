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

		def set_alarm(time = 7.hours)
			@alarmTime =  Time.today(time);
                        @alarmTime += 24.hours if @alarmTime <= Time.now();
                     	@wakeupTTS.speak "Alarm set for #{@alarmTime.hour} #{@alarmTime.min}"

                	@AlarmThread.run
		end
		module_function :set_alarm

		$mqtt.subscribeTo "Room/Commands" do |t, data|
			if(data == "clk" and not @alarmTime) then
				set_alarm
			end
		end

		$mqtt.subscribeTo "Room/Alarm/Set" do |t, data|
			set_alarm(data.to_f.hours);
		end
	end
end

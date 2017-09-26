require_relative '../SetupEnv.rb'
require_relative '../weather.rb'

module Hooks
	module Wakeup

		@wakeupTTS  = ColorSpeak::Client.new($mqtt, "Wakeup");
		@weatherTTS = ColorSpeak::Client.new($mqtt, "Weather");

		@alarmTime = nil;
		@AlarmThread = Thread.new do
			while true do
				Thread.stop() until @alarmTime;

				sleep [0.5, [2.minutes, (@alarmTime - Time.now())*0.9].min].max

				if(Time.now() >= @alarmTime) then
					@weatherTime = @alarmTime + 5.minutes;
					@WeatherThread.run();

					@alarmTime = nil;

					$mqtt.publishTo "Room/Commands", "good morning"
					$mqtt.publishTo "Room/Light/Set/Switch", "on";
					$mqtt.publishTo "Room/Light/Set/Color", Color.RGB(0, 0, 0);

					@wakeupTTS.speak "Good morning, David"
				end
			end
		end

		@weatherTime = nil;
		@WeatherThread = Thread.new do
			while true do
				Thread.stop() until @weatherTime;

				sleep [0.5, [2.minutes, (@weatherTime - Time.now())*0.9].min].max

				if(Time.now() >= @weatherTime) then
					@weatherTime = nil;

					@weatherTTS.speak "And now, the weather report: "
					sleep 5;

					first = true;
					$weather.fiveday_data["list"].each do |d|
						break if d["dt"].to_i >= Time.today(21.hours).to_i;
						@weatherTTS.speak $weather.readable_forecast(d, temperature: true, forceDay: first), Color.HSV(120 - 100*(d["main"]["temp"].to_i - 17)/5);
						first = false;
					end
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

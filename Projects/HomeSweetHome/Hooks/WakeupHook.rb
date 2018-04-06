
require_relative '../weather.rb'

module Hooks
	module Wakeup

		@wakeupTTS  = ColorSpeak::Client.new($mqtt, "Wakeup");

		@alarmTime = nil;
		@AlarmThread = Thread.new do
			while true do
				Thread.stop() until @alarmTime;
				sleep [0.5, [2.minutes, (@alarmTime - Time.now())*0.9].min].max
				next unless @alarmTime;

				if(Time.now() >= @alarmTime) then
					@weatherTime = @alarmTime + 5.minutes;
					@WeatherThread.run();

					@switchRecommendTime = @alarmTime + 1.minutes;
					@SwitchRecommendThread.run();

					@alarmTime = nil;

					$room.command "good morning"
					$room.lights = "#000000"

					@wakeupTTS.speak "Good morning, David."
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

					begin
						newWeatherData = $weather.fiveday_data["list"];
					rescue
					else
						@wData = newWeatherData;
					end

					if @wData
						@wakeupTTS.speak "And now, the weather report: "
						sleep 3;

						first = true;
						@wData.each do |d|
							next  if d["dt"].to_i <= Time.now().to_i;
							break if d["dt"].to_i >= Time.today(21.hours).to_i;
							@wakeupTTS.speak $weather.readable_forecast(d, temperature: true, forceDay: first), Color.HSV(120 - 100*(d["main"]["temp"].to_i - 17)/5);
							first = false;
						end
					else
						@wakeupTTS.speak "Weather forecast currently unavailable."
					end
				end
			end
		end

		@switchRecommendTime = nil;
		$mqtt.track "Personal/Xasin/Switching/Data" do |newData|
			@switchPercentTrack = JSON.parse(newData)["percentage"];
		end
		@SwitchRecommendThread = Thread.new do
			loop do
				Thread.stop() until @switchRecommendTime;
				sleep [0.5, (@switchRecommendTime - Time.now()).to_i].max
				next unless Time.now() >= @switchRecommendTime;

				@switchRecommendTime = nil;

				@switchPercentTrack.delete_if {|key| not Hooks::Switching::SystemColors.include? key }
				lowestSwitch = @switchPercentTrack.min_by {|key,value| value};
				@wakeupTTS.speak "I recommend #{lowestSwitch[0]} at #{lowestSwitch[1]} percent to switch in.", Switching::SystemColors[lowestSwitch[0]];
			end
		end

		def set_alarm(time = 7.hours)
			@alarmTime =  Time.today(time);
         @alarmTime += 24.hours if @alarmTime <= Time.now();

			@wakeupTTS.speak "Alarm set for #{@alarmTime.hour} #{@alarmTime.min}"

        	@AlarmThread.run
		end
		module_function :set_alarm

		$room.on_command do |data|
			if(data == "clk") then
				if not @alarmTime then
					set_alarm($wakeupTimes[(Time.now() - 6.hours).wday])
				else
					@alarmTime = nil;
					@wakeupTTS.speak "Alarm unset."
				end
			end
		end

		$mqtt.subscribe_to "Room/default/Alarm/Set" do |data|
			set_alarm(data.to_f.hours);
		end
	end
end


require_relative '../weather.rb'

module Hooks
	$wakeupTimes = [7.hours, 6.75.hours, 6.75.hours, 8.25.hours, 8.25.hours, 9.5.hours, 9.5.hours];

	class TimedEvent
		def initialize(&block)
			@callback = block;

			@execTime = nil;

			@runThread = Thread.new do
				loop do
					Thread.stop until @execTime;
					sleep [0.1, [10.minutes, (@execTime - Time.now())*0.99].min].max

					next unless @execTime;
					next if Time.now < @execTime;

					@execTime = nil;
					@callback.call();
				end
			end

			def set(time)
				raise ArgumentError, "Needs to be a Time or nil!" unless (time.is_a? Time) or time.nil?
				@execTime = time;
				@runThread.run();
			end

			def set?
				return @execTime
			end
		end
	end

	module Wakeup
		@wakeupTTS 		= ColorSpeak::Client.new($mqtt, "Wakeup");
		@wakeupUser 	= Messaging::UserClient.new($mqtt, "Xasin", "Wakeup");

		@wakeupNotify  = @wakeupTTS;

		def self.initial_wakeup
			@alarmEvent.set(nil);
			$mqtt.publish_to "Room/default/Alarm/Unix", Time.now.to_i, retain: true;

			@weatherEvent.set(Time.now + 5.minutes)
			@switchRecommendEvent.set(Time.now + 1.minutes);

			@wakeupNotify.notify "Good morning, David."
		end

		def self.weather_report
			@weatherEvent.set(nil);
			Thread.new do
				begin
					newWeatherData = $weather.fiveday_data["list"];
				rescue
				else
					@wData = newWeatherData;
				end

				if @wData
					@wakeupNotify.notify "And now, the weather report: "
					sleep 8;

					first = true;
					@wData.each do |d|
						next  if d["dt"].to_i <= Time.now().to_i;
						break if d["dt"].to_i >= Time.today(23.hours).to_i;

						@wakeupNotify.notify $weather.readable_forecast(d, temperature: true, forceDay: first),
								color: Color.HSV(120 - 100*(d["main"]["temp"].to_i - 17)/5),
								temperature: d["main"]["temp"].to_i

						first = false;
					end
				else
					@wakeupNotify.notify "Weather forecast currently unavailable."
				end
			end
		end

		@sleepLastRecommended = Time.new(0);
		def self.check_sleep
			if(!$xasin.awake? and @alarmEvent.set? and (@sleepLastRecommended+10.minutes < Time.now))
				Thread.new() do
					sleep 0.5;
					$room.lights = false;
					sleep 0.5;

					sleepLeft = @alarmEvent.set? - Time.now()
					if(sleepLeft >= 2.hours)
						sleepLeft = "#{(sleepLeft / 1.hours).round(0)} hours"
					elsif(sleepLeft <= 10.minutes)
						$room.command "gm"
						sleepLeft = nil;
					else
						sleepLeft = "#{(sleepLeft / 1.minutes).round(-1)} minutes"
					end

					@wakeupTTS.notify "It's ok. You still have #{sleepLeft} left. Go back to bed." if sleepLeft;

					@sleepLastRecommended = Time.now();
				end
			end
		end

		@alarmEvent = TimedEvent.new do
			$room.command "gm"
		end

		@weatherEvent = TimedEvent.new do
			$room.command "whtr"
		end

		@switchRecommendEvent = TimedEvent.new do
			$room.command "sr"
		end

		$room.on_command do |data|
			@wakeupNotify = @wakeupTTS;

			case data
			when "e"
				check_sleep
			when "gm"
				initial_wakeup
			when "whtr"
				weather_report
			when "clk"
				if not @alarmEvent.set? then
					set_alarm($wakeupTimes[(Time.now() - 6.hours).wday])
				else
					$mqtt.publish_to "Room/default/Alarm/Unix", nil, retain: true;
					@alarmEvent.set(nil);
					@wakeupNotify.notify "Alarm unset."
				end
			end
		end

		def set_alarm(time = 7.hours)
			@alarmTime =  Time.today(time);
         @alarmTime += 24.hours if @alarmTime <= Time.now();

			@wakeupTTS.speak "Alarm set for #{@alarmTime.hour} #{@alarmTime.min}",
				time: @alarmTime.to_i

        	@alarmEvent.set(@alarmTime);
			$mqtt.publish_to "Room/default/Alarm/Unix", @alarmTime.to_i, retain: true;
		end
		module_function :set_alarm

		$mqtt.subscribe_to "Room/default/Alarm/Set" do |data|
			set_alarm(data.to_f.hours);
		end
	end
end

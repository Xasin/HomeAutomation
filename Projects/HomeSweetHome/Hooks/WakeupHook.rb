
require_relative '../weather.rb'

module Hooks
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
		end
	end

	module Wakeup
		@wakeupTTS  = ColorSpeak::Client.new($mqtt, "Wakeup");

		$mqtt.track "Personal/Xasin/Switching/Data" do |newData|
			@switchPercentTrack = JSON.parse(newData)["percentage"];
		end

		def self.initial_wakeup
			@weatherEvent.set(Time.now + 5.minutes)
			@switchRecommendEvent.set(Time.now + 1.minutes);

			@wakeupTTS.speak "Good morning, David."
		end

		def self.weather_report
			Thread.new do
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
						break if d["dt"].to_i >= Time.today(23.hours).to_i;

						@wakeupTTS.speak $weather.readable_forecast(d, temperature: true, forceDay: first),
								Color.HSV(120 - 100*(d["main"]["temp"].to_i - 17)/5),
								data: d["main"]["temp"].to_i,
								type: "temperature"

						first = false;
					end
				else
					@wakeupTTS.speak "Weather forecast currently unavailable."
				end
			end
		end

		def self.switch_recommend
			@switchPercentTrack.delete_if {|key| not Hooks::Switching::SystemColors.include? key }
			lowestSwitch = @switchPercentTrack.min_by {|key,value| value};
			$xasin.notify "I recommend #{lowestSwitch[0]} at #{lowestSwitch[1]} percent to switch in.",
					color: Switching::SystemColors[lowestSwitch[0]],
					gid: "SwitchHelp",
					data: lowestSwitch[1],
					type: "percentage"
		end

		$room.on_command do |data|
			case data
			when "gm"
				initial_wakeup
			when "whtr"
				weather_report
			when "sr"
				switch_recommend
			when "clk"
				if not @alarmTime then
					set_alarm($wakeupTimes[(Time.now() - 6.hours).wday])
				else
					@alarmTime = nil;
					@wakeupTTS.speak "Alarm unset."
				end
			end
		end

		$telegram.on_message do |data|
			if data =~ /recommend .*switch/ then
				switch_recommend
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

		def set_alarm(time = 7.hours)
			@alarmTime =  Time.today(time);
         @alarmTime += 24.hours if @alarmTime <= Time.now();

			@wakeupTTS.speak "Alarm set for #{@alarmTime.hour} #{@alarmTime.min}",
				data: @alarmTime,
				type: "time"

        	@AlarmThread.run
		end
		module_function :set_alarm

		$mqtt.subscribe_to "Room/default/Alarm/Set" do |data|
			set_alarm(data.to_f.hours);
		end
	end
end

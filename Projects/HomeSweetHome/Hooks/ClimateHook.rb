module Hooks
	module ClimateControl
		class SI7021
			def initialize(twi)
				@twi = twi;

				@lastMeasured = Time.new(0);
				@temperature = nil;
				@humidity = nil;
			end

			def measure()
				retry_attempts = 0;

				begin
					$twi.write(0x40, [0xF5].pack("C"));
					sleep 0.05;

					rawHumidity = @twi.read(0x40, 2).unpack("S>")[0];
					rawTemp     = @twi.read(0x40, 2, [0xE0].pack("C")).unpack("S>")[0];

					humidity    = (rawHumidity*125.0)/65536 - 6;
					temperature = (rawTemp*175.72)/65536 - 46.85;
				rescue
					sleep 1
					retry unless ++retry_attempts >= 3;
				else
					@lastMeasured 	= Time.now();
					@temperature  	= temperature;
					@humidity 		= humidity;
				end
			end

			def temperature
				measure if @lastMeasured + 10 < Time.now();
				return @temperature;
			end

			def humidity
				measure if @lastMeasured + 10 < Time.now();
				return @humidity
			end
		end

		class GY_30
			def initialize(twi)
				@twi = twi;

				begin
					@twi.write(0x23, [0x10].pack("C"));
				rescue
					puts "GY-30 init failed"
				end
				@lastMeasured = 0;
			end

			def brightness()
				begin
					@lastMeasured = @twi.read(0x23, 2).unpack("S>")[0];

					if(@lastMeasured == 0) then
						@twi.write(0x23, [0x10].pack("C"));
					end
				rescue
					puts "GY-30 didn't answer!"
				end

				return @lastMeasured;
			end
		end

		@HumidityTTS = ColorSpeak::Client.new($mqtt, "HumidityWarning");

		@humidityWarned = false;
		@lastNotified = Time.new(0);

		@lightSensor = GY_30.new($twi);
		@humidSensor = SI7021.new($twi);
		Thread.new do
			loop do
				sleep 30;
				$mqtt.publish_to "Room/default/Sensors/Temperature", @humidSensor.temperature;
				$mqtt.publish_to "Room/default/Sensors/Humidity", @humidSensor.humidity;
				$mqtt.publish_to "Room/default/Sensors/Brightness", @lightSensor.brightness;

				next unless $xasin.awake_and_home?
				if case @humidSensor.humidity
						when 53..58
							next if @lastNotified + 3.hours >= Time.now();
							@HumidityTTS.speak "Room humidity is at #{@humidSensor.humidity.round(1)} percent. Maybe you could open the window?",
								"#a0a0FF",
								percentage: @humidSensor.humidity
							true
						when 58..65
							next if @lastNotified + 1.hours >= Time.now();
							@HumidityTTS.speak "Room humidity is slightly high at #{@humidSensor.humidity.round(1)} percent. Please open the window.",
								"#6060FF",
								percentage: @humidSensor.humidity
							true
						when 65..100
							next if @lastNotified + 20.minutes >= Time.now();
							@HumidityTTS.speak "This room is extremely humid at #{@humidSensor.humidity.round(1)} percent, open the windows!",
								"#6000FF",
								percentage: @humidSensor.humidity
							true
						end then
					@humidityWarned = true;
					@lastNotified = Time.now();
				elsif(@humidSensor.humidity <= 52 and @humidityWarned) then
					@HumidityTTS.speak "Humidity levels are back to normal.", "#B0B0FF";
					@humidityWarned = false;
				end
			end
		end


	end
end

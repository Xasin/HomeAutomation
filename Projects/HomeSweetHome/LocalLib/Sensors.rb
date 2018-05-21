
require 'i2c'

module Hardware
	module Sensors
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
	end
end

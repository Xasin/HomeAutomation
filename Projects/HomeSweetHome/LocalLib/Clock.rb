
require 'i2c'
require 'mqtt/sub-handler'

module Hardware
	class TWIClock
		attr_reader :active

		def initialize(twi)
			@twi = twi;

			@lastWritten = 0;

			@currentDisplay = 0;
			@active = true;
		end

		def _raw_write(value)
			return if @lastWritten == value;

			retries = 0;

			begin
				@twi.write(0x31, [value].pack("s<"));
			rescue Errno::EIO, Errno::ETIMEDOUT
				retries += 1;

				if(retries < 3)
					sleep 0.5
					retry;
				else
					puts "Clock TWI unresponsive!";
				end
			else
				@lastWritten = value;
			end
		end

		def show(value)
			if(value.is_a? Time) then
				if(Time.to_i < 99*60)
					value = value.min.to_i * 100 + value.sec.to_i
				else
					value = (value.hour.to_i * 100 + value.min.to_i)
				end
			end

			raise ArgumentError, "Unsupported data format!" unless value.is_a? Numeric
			@currentDisplay = value;
			_raw_write(value) if @active;
		end

		def active=(value)
			if(value)
				_raw_write(@currentDisplay);
				@active = true;
			else
				_raw_write(-1);
				@active = false;
			end
		end
	end

	class Clock
		def initialize(mqtt, clock, room: "default", user: nil)
			@mqtt = mqtt;
			@clock = clock;

			@roomName = room;
			@user = user;

			if(@user) then
				@user.awake_and_home? do |data|
					self.active = data;
				end
			end

			@currentOverride = nil;
			@countdown = false;
		end

		def _clock_thread
			loop do
				sleep 1;
				if @currentOverride
					if(@countdown and @currentOverride.is_a? Time)
						@clock.show(@currentOverride - Time.now());
					end
				else
					@clock.show(Time.now)
				end
			end
		end

		def _parse_override(data)
			
		end

		def active=(value)
			@clock.active = value;
		end
		def active
			return @clock.active
		end
	end
end

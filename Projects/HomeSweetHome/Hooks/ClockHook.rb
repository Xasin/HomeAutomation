
class TWIClock
	attr_reader :active

	def initialize(twi)
		@twi = twi;

		@lastWritten = 0;

		@currentDisplay = 0;
		@active = true;
	end

	def _raw_write(value)
		value = -1 if value < 0;
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
	attr_accessor :active

	def initialize(mqtt, clock, room: "default")
		@mqtt = mqtt;
		@clock = clock;

		@roomName = room;

		@currentOverride = nil;
		@countdown = false;
		@active = true;

		@clockThread = Thread.new do _clock_thread end;
	end

	def _clock_thread
		loop do
			sleep 0.5;
			if @currentOverride
				if(@countdown and @currentOverride.is_a? Time)
					@clock.show(@currentOverride - Time.now());
				end
			elsif(@active)
				@clock.show(Time.now)
			else
				@clock.show(-1);
			end
		end
	end

	def _parse_override(data)
	end
end

$clock = Clock.new($mqtt, TWIClock.new($twi));
$xasin.awake_and_home? do |data|
	$clock.active = data;
end

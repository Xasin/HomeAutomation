
class TWIClock
	attr_reader :active

	def initialize(twi)
		@twi = twi;

		@lastWritten = 0;

		@currentDisplay = 0;
		@active = true;

		@writeRetries = 0;
	end

	def _raw_write(value)
		value = -1 if value < 0;
		return if @lastWritten == value;

		begin
			@twi.write(0x31, [value].pack("s<"));

			@lastWritten  = value;
			@writeRetries = 0;
		rescue Errno::EIO, Errno::ETIMEDOUT
			@writeRetries += 1;

			if(@writeRetries < 3)
				sleep 0.5
				retry;
			elsif(@writeRetries == 3)
				puts "Clock TWI unresponsive!";
			end
		end
	end

	def show(value)
		if(value.is_a? Time) then
			if(value.to_i < 99*60)
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
	attr_reader :currentValue
	attr_reader :active

	def initialize(mqtt, clock, room: "default")
		@mqtt = mqtt;
		@clock = clock;

		@roomName = room;

		@currentOverride = nil;
		@countdown = false;
		@active = true;

		@clockThread = Thread.new do _clock_thread end;
		@clockThread.abort_on_exception = true;

		@mqtt.subscribe_to "Room/#{@roomName}/Info/Current" do |data|
			_parse_override(data);
		end
	end

	def show(value)
		@currentValue = value;
		if(@clock)
			@clock.show(value);
		end
	end

	def _clock_thread
		loop do
			sleep 2;
			if @currentOverride
				if(@countdown and @currentOverride.is_a? Time)
					show(Time.new(@currentOverride - Time.now()));
				else
					show(@currentOverride);
				end
			elsif(@active)
				show(Time.now)
			else
				show(-1);
			end
		end
	end

	def _parse_override(data)
		@currentOverride = nil;
		begin
			data = JSON.parse(data);
			["temperature", "percentage"].each do |k|
				if (d = data[k])
					@currentOverride = d.to_i
				end
			end

			if(d = data["time"])
				@currentOverride = Time.new(d.to_i);
			end
		rescue
		end

		@clockThread.run;
	end

	def active=(value)
		@active = value;
		@clockThread.run;
	end
end

$clock = Clock.new($mqtt, TWIClock.new($twi));
$xasin.awake_and_home? do |data|
	$clock.active = data;
end

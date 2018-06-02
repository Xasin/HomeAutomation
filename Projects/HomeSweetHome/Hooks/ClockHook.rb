
class TWIClock
	attr_reader :active

	def initialize(twi)
		@twi = twi;

		@lastWritten = 0;

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
			value = (value.hour * 100 + value.min)
		end

		raise ArgumentError, "Unsupported data format!" unless value.is_a? Numeric
		_raw_write(value);
	end

	def self.calculate_timer(value)
		value = value.to_i.abs;

		if(value > 5999)
			value /= 60;
		end
		value = [value, 5999].min;

		return ((value/60).round*100 + value%60);
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
			sleep 1;
			if @currentOverride
				if(@countdown and @currentOverride.is_a? Time)
					show(Clock.calculate_timer(Time.new(@currentOverride - Time.now())));
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
		@countdown = false;

		begin
			data = JSON.parse(data);
			["temperature", "percentage"].each do |k|
				if (d = data[k])
					@currentOverride = d.to_i
				end
			end

			if(d = data["time"])
				@currentOverride = Time.at(d.to_i);
			end

			if(d = (data["alarm"] or data["timer"]))
				@currentOverride = Time.at(d.to_i);
				@countdown = true;
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

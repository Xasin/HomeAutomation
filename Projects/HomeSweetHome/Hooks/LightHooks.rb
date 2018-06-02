
require 'interpolate'
require_relative '../Libs/InterpolateTools.rb'

module Hooks
	module Lights
		LIGHT_OFF_THRESHOLD = 150;
		LIGHT_ON_THRESHOLD  = 80;
		@roomBrightness = 0;
		@oldLightSuggestion = false;

		def self.check_light_status()
			return false unless $xasin.awake_and_home?

			if($room.lightSwitch)
				return (@roomBrightness < LIGHT_OFF_THRESHOLD)
			else
				return (@roomBrightness < LIGHT_ON_THRESHOLD)
			end
		end

		def self.update_light_status()
			if(@oldLightSuggestion != check_light_status) then
				@oldLightSuggestion = check_light_status();
				$room.lights = @oldLightSuggestion;
			end
		end

		$xasin.awake_and_home? do
			self.update_light_status();
		end
		$mqtt.track "Room/default/Sensors/Brightness" do |data|
			@roomBrightness = data.to_f
			self.update_light_status();
		end

		$room.on_command do |data|
			case data
			when "e"
				$room.lights = (not $room.lightSwitch);
			when "ld"
				$room.lights = "#000000"
			when "gm"
				$room.lights = "#000000" if @roomBrightness < LIGHT_OFF_THRESHOLD
			when /^lh([\d]{1,3})$/
				$room.lights = Color.HSV($~[1].to_i)
			when /^l([\da-f]{6})$/
				$room.lights = Color.from_s("#" + $~[1])
			end
		end

		$telegram.on_message do |data|
			mText = data[:text].downcase;

			case mText
			when /lights\s(on|off)/
				$room.lights = ($~[1] == "on");
			when /daylight(?:[^\d]*(\d{1,3})%|)/
				if($~[1]) then
					$room.lights = Color.RGB(255,255,255).set_brightness($~[1].to_i * 25.5).to_s;
				else
					$room.lights = "#000000"
				end
			when /lights .*#([\da-f]{6})/, /lights .*to .*([\da-f]{6})[^k]/
				$room.lights = Color.from_s("#" + $~[1]).to_s;
			when /lights .*(\d{4,})k(?:[^\d]*(\d{1,3})%|)/
				$room.lights = Color.temperature($~[1].to_i, $~[2] ? $~[2].to_f/100 : 1).to_s;
			end
		end

		@prePS2Color = "#FFFFFF";
		@PS2Status = false;
		Thread.new do
			loop do
				sleep 20
				next unless $xasin.home?
				next unless $room.lightSwitch

				currentStatus = $planetside.get_online_status("Xasin");
				if(currentStatus and not @PS2Status) then
					@prePS2Color = $room.lightColor
					@PS2Status = true;

					$room.lights = "#936AFC";
				elsif(not currentStatus and @PS2Status) then
					@PS2Status = false;
					$room.lights = @prePS2Color unless $room.lightColor != "#936AFC"
				end
			end
		end.abort_on_exception = true;

		dayProfile = {
			1.hours	=> Color.K(1000, 0.2),
			6.hours 	=> Color.K(1000, 0.2),
			8.hours 	=> Color.K(4000, 1),
			10.hours	=> Color.K(5500, 1),
			15.hours => Color.K(5000, 1),
			18.hours => Color.K(3000, 1),
			20.hours	=> Color.K(3000, 1),
			22.hours => Color.K(2400, 0.7),
			23.hours => Color.K(1500, 0.3),
		};
		@daylightProfile = dayProfile.clone();

		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, dayProfile, offset: i.days, upperBound: 7.days, spacing: 0.5.hours);
		end

		workoutTimes = [18.hours, 13.hours, 17.3.hours, 18.hours, 18.hours, 18.hours, 18.hours];
		workoutProfile = {
			0 				=> Color.K(6000, 1),
			18.minutes	=> Color.K(6000, 1),
		}
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, workoutProfile, offset: i.days + workoutTimes[i], upperBound: 7.days, spacing: 15.minutes);
		end

		teaTimes = [nil, 17.hours, 17.hours, 17.hours, 17.hours, 17.hours, 17.hours];
		teaProfile = {
			-3.minutes 	=> Color.K(2400, 0.7),
			20.minutes 	=> Color.K(2400, 0.7),
		}
		7.times do |i|
			if teaTimes[i] then
				Interpolate::mix_looped(@daylightProfile, teaProfile, offset: i.days + teaTimes[i], upperBound: 7.days, spacing: 10.minutes);
			end
		end

		@daylightInterpolator = Interpolate::Points.new(@daylightProfile);

		wakeupProfile = {
			-1.minutes => Color.K(1800, 0.1),
			15.minutes => Color.K(4000, 1),
		};

		$mqtt.track "Room/default/Alarm/Unix" do |data|
			begin
				time = Time.at(data.to_i);
				offset = ((time.wday-1)%7).days + t.hour.hours + t.min.minutes + t.sec;

				daylightProfile_clone = @daylightProfile.clone;
				Interpolate::mix_looped(daylightProfile_clone, wakeupProfile, offset: offset, upperBound: 7.days, spacing: 0.5.hours)

				@daylightInterpolator = Interpolate::Points.new(daylightProfile_clone);
			rescue
				@daylightInterpolator = Interpolate::Points.new(@daylightProfile)
			end
		end

		$cSpeak.daylight_getter do
			t = Time.now();
			currentTime = ((t.wday-1)%7).days + t.hour.hours + t.min.minutes + t.sec

			@daylightInterpolator.at(currentTime);
		end
	end
end

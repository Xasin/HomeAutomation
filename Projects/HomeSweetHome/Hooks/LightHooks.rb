
require 'interpolate'
require_relative '../Libs/InterpolateTools.rb'

module Hooks
	module Lights
		$lightsOnTime = 16.hours

		$room.on_command do |data|
			if(data == "e") then
				$room.lights = (not $room.lightSwitch);
			elsif(data == "ld") then
				$room.lights = "#000000"
			elsif(data =~ /lh([\d]{1,3})/) then
				$room.lights = Color.HSV($~[1].to_i)
			elsif(data =~ /l([\da-f]{6})/) then
				$room.lights = Color.from_s("#" + $~[1])
			elsif(data == "gn") then
				$room.lights = false;
			end
		end

		$telegram.on_message do |data|
			mText = data[:text].downcase;

			case mText
			when /lights\s(on|off)/
				$room.lights = ($~[1] == "on");
			when /daylight(?:[^\d]*(\d{1,3})%|)/
				if($~[1]) then
					$room.lights = Color.RGB(255,255,255).set_brightness($~[1].to_i * 25.5);
				else
					$room.lights = "#000000"
				end
			when /lights .*#([\da-f]{6})/, /lights .*to .*([\da-f]{6})[^k]/
				$room.lights = Color.from_s("#" + $~[1])
			when /lights .*(\d{4,})k(?:[^\d]*(\d{1,3})%|)/
				$room.lights = Color.temperature($~[1].to_i, $~[2] ? $~[2].to_f/100 : 1);
			end
		end

		@prePS2Color = "#FFFFFF";
		@PS2Status = false;
		Thread.new do
			loop do
				sleep 20
				next unless $xasin.home?

				if (Time.today($lightsOnTime).between? Time.now() - 20, Time.now())
					$room.lights = true;
				end

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
			24.hours => Color.K(1800, 0.5),
		};
		@daylightProfile = dayProfile.clone();

		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, dayProfile, offset: i.days, upperBound: 7.days, spacing: 0.5.hours);
		end

		$wakeupTimes = [7.hours, 6.75.hours, 6.75.hours, 6.75.hours, 6.75.hours, 9.5.hours, 9.5.hours];
		wakeupProfile = {
			-1.minutes => Color.K(1800, 0.1),
			15.minutes => Color.K(4000, 1),
		};
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, wakeupProfile, offset: i.days + $wakeupTimes[i], upperBound: 7.days, spacing: 0.5.hours);
		end

		workoutTimes = [18.hours, 13.hours, 17.3.hours, 18.hours, 18.hours, 18.hours, 18.hours];
		workoutProfile = {
			0 				=> Color.K(6000, 1),
			18.minutes	=> Color.K(6000, 1),
		}
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, workoutProfile, offset: i.days + workoutTimes[i], upperBound: 7.days, spacing: 15.minutes);
		end

		teaTimes = [15.hours, nil, 16.45.hours, nil, nil, 17.hours, 17.hours];
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
		$cSpeak.daylight_getter do
			t = Time.now();
			currentTime = ((t.wday-1)%7).days + t.hour.hours + t.min.minutes + t.sec

			@daylightInterpolator.at(currentTime);
		end
	end
end

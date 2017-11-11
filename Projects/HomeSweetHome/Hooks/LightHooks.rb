
require 'interpolate'
require_relative '../Libs/InterpolateTools.rb'

module Hooks
	module Lights
		@switchValue = $mqtt.track "Room/default/Lights/Switch"

		@RoomName = "default"
		$mqtt.subscribe_to "Room/#{@RoomName}/Commands" do |tList, data|
			if(data == "e") then
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Switch", @switchValue.value == "on" ? "off" : "on", retain: true;
			elsif(data == "ld") then
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Switch", "on", retain: true;
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Color", Color.RGB(0,0,0).to_s, retain: true;
			elsif(data =~ /lh([\d]{1,3})/) then
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Switch", "on", retain: true;
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Color", Color.HSV($~[1].to_i).to_s, retain: true;
			elsif(data =~ /l([\da-f]{6})/) then
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Switch", "on", retain: true;
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Color", Color.from_s("#" + $~[1]).to_s, retain: true;
			elsif(data == "gn") then
				$mqtt.publish_to "Room/#{@RoomName}/Lights/Set/Switch", "off", retain: true;
			end
		end

		@prePS2Color = "#FFFFFF";
		@PS2Status = false;
		@roomColor = $mqtt.track "Room/default/Lights/Color"

		Thread.new do
			loop do
				sleep 20
				currentStatus = $planetside.get_online_status("Xasin");

				if(currentStatus and not @PS2Status) then
					@prePS2Color = @roomColor.value
					@PS2Status = true;

					$mqtt.publish_to "Room/default/Lights/Set/Color", "#936AFC"
				elsif(not currentStatus and @PS2Status) then
					@PS2Status = false;
					$mqtt.publish_to "Room/default/Lights/Set/Color", @prePS2Color unless @roomColor.value != "#936AFC"
				end
			end
		end

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

		wakeupTimes = [7.hours, 7.hours, 7.hours, 7.5.hours, 7.5.hours, 9.5.hours, 9.5.hours];
		wakeupProfile = {
			-1.minutes => Color.K(1800, 0.1),
			15.minutes => Color.K(4000, 1),
		};
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, wakeupProfile, offset: i.days + wakeupTimes[i], upperBound: 7.days, spacing: 0.5.hours);
		end

		workoutTimes = [18.hours, 17.15.hours, 20.hours, 18.hours, 18.hours, 18.hours, 18.hours];
		workoutProfile = {
			0 				=> Color.K(6000, 1),
			18.minutes	=> Color.K(6000, 1),
		}
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, workoutProfile, offset: i.days + workoutTimes[i], upperBound: 7.days, spacing: 15.minutes);
		end

		teaTimes = [15.hours, 16.45.hours, 16.45.hours, 17.hours, 17.hours, 17.hours, 17.hours];
		teaProfile = {
			-3.minutes 	=> Color.K(2400, 0.7),
			20.minutes 	=> Color.K(2400, 0.7),
		}
		7.times do |i|
			Interpolate::mix_looped(@daylightProfile, teaProfile, offset: i.days + teaTimes[i], upperBound: 7.days, spacing: 10.minutes);
		end

		@daylightInterpolator = Interpolate::Points.new(@daylightProfile);
		$cSpeak.daylight_getter do
			t = Time.now();
			currentTime = ((t.wday-1)%7).days + t.hour.hours + t.min.minutes + t.sec
			@daylightInterpolator.at(currentTime);
		end
	end
end

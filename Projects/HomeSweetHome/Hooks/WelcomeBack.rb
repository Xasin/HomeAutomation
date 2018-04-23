module Hooks
module Welcome

@welcomeTTS = ColorSpeak::Client.new($mqtt, "Welcome");

@computerTrack = $mqtt.track "Room/default/X-Desktop/Status"

$xasin.home? do |data|
	if(data == "true") then
		if($xasin.awake?)
			who = $xasin.switch;

			@welcomeTTS.speak "Welcome back home #{who}", Hooks::Switching::SystemColors[who];
			if(Time.today($lightsOnTime) < Time.now()) then
				$room.lights = true;
			end

			`etherwake 54:a0:50:50:d6:ac` if(@computerTrack.value == "SUSPENDED");
		end
	else
		$telegram.send_message("See you around!", disable_notification: true);
		$room.lights = false;
	end
end

end
end

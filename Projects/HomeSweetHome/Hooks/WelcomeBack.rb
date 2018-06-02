module Hooks
module Welcome

@welcomeTTS = ColorSpeak::Client.new($mqtt, "Welcome");

@computerTrack = $mqtt.track "Room/default/X-Desktop/Status"

$xasin.home? do |data|
	next unless $xasin.awake?

	if(data == "true") then
		who = $xasin.switch;

		@welcomeTTS.speak "Welcome back home #{who}", Hooks::Switching::SystemColors[who];

		`etherwake 54:a0:50:50:d6:ac` if(@computerTrack.value == "SUSPENDED");
	else
		$telegram.send_message("See you around!", disable_notification: true);
	end
end

$room.on_command do |data|
	case data
	when "bye"
		$xasin.home = false;
	when "hi"
		$xasin.home = true;
	end
end

end
end

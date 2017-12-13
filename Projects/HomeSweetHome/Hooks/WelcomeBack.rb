module Hooks
module Welcome

@SystemColors = {
	"Xasin" => Color.RGB(255, 50, 50),
	"Neira" => Color.RGB(50, 50, 255),
	"Mesh"  => Color.RGB(50, 255, 50),
}


@welcomeTTS = ColorSpeak::Client.new($mqtt, "Welcome");

@switchTrack 	= $mqtt.track "Personal/Xasin/Switching/Who";
@computerTrack = $mqtt.track "Room/default/X-Desktop/Status"

$mqtt.track "Personal/Xasin/IsHome" do |data|
	if(data == "true") then
		if(@SystemColors.key? @switchTrack.value)
			who = @switchTrack.value;

			@welcomeTTS.speak "Welcome back home #{who}", @SystemColors[who];
			if(Time.today($lightsOnTime) < Time.now()) then
				$mqtt.publish_to "Room/default/Lights/Set/Switch", "on"
			end

			`etherwake 54:a0:50:50:d6:ac` if(@computerTrack.value == "SUSPENDED");
		end
	end
end

end
end

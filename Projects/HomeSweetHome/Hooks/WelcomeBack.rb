module Hooks
module Welcome

@SystemColors = {
	"Xasin" => Color.RGB(255, 0, 0),
	"Neira" => Color.RGB(0, 0, 255),
	"Mesh"  => Color.RGB(0, 255, 0),
	"David" => Color.RGB(255, 255, 255),
}


@welcomeTTS = ColorSpeak::Client.new($mqtt, "Welcome");

@switchTrack = $mqtt.track "personal/switching/Xasin/who";

$mqtt.track "personal/Xasin/IsHome" do |data|
	if(data == "true") then
		who = @SystemColors.key?(@switchTrack.value) ? @switchTrack.value : "David"

		@welcomeTTS.speak "Welcome back home, #{who}", @SystemColors[who];
		if(Time.today(18.hours) < Time.now()) then
			$mqtt.publish_to "Room/default/Lights/Set/Switch", "on"
		end
	end
end

end
end

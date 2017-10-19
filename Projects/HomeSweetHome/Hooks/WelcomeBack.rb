module Hooks
module Welcome

@SystemColors = {
	"Xasin" => Color.RGB(255, 0, 0),
	"Neira" => Color.RGB(0, 0, 255),
	"Mesh"  => Color.RGB(0, 255, 0),
	"David" => Color.RGB(255, 255, 255),
}


@welcomeTTS = ColorSpeak::Client.new($mqtt, "Welcome");

@formerState = "false";

$mqtt.subscribe_to "personal/Xasin/IsHome" do |tList, data|
	if(data == "true" and @formerState != "true") then
		who = @SystemColors.key?($switchedInMember) ? $switchedInMember : "David"

		@welcomeTTS.speak "Welcome back home, #{who}", @SystemColors[who];
		if(Time.today(18.hours) < Time.now()) then
			$mqtt.publish_to "Room/Light/Set/Switch", "on", retain: true
		end
	end
	@formerState = data;
end

end 
end


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
	end
end

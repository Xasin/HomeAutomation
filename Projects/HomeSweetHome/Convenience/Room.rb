
module Convenience
	class Room
		def initialize(mqtt, name)
			@mqtt = mqtt;
			@name = name;
		end

		def lights=(newVal)
			if(newVal) then
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Switch", "on", retain: true;
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Color", newVal, retain: true if newVal.is_a? String;
			else
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Switch", "off", retain: true;
			end
		end

		def command(cmd)
			@mqtt.publish_to "Room/#{@name}/Commands", cmd
		end
	end
end


module Convenience
	class Room
		def initialize(mqtt, name)
			@mqtt = mqtt;
			@name = name;

			@lights 			= @mqtt.track "Room/#{@name}/Lights/Color";
			@lightSwitch	= @mqtt.track "Room/#{@name}/Lights/Switch";

			@commandBlocks = Array.new();
			@mqtt.subscribe_to "Room/#{@name}/Commands" do |data|
				@commandBlocks.each do |c| c.call(data); end
			end
		end

		def lights=(newVal)
			if(newVal) then
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Switch", "on", retain: true;
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Color", newVal, retain: true if newVal.is_a? String;
			else
				@mqtt.publish_to "Room/#{@name}/Lights/Set/Switch", "off", retain: true;
			end
		end
		def lightColor
			return @lights.value
		end
		def lightSwitch
			return (@lightSwitch.value == "on")
		end

		def command(cmd)
			@mqtt.publish_to "Room/#{@name}/Commands", cmd
		end

		def on_command(&block)
			@commandBlocks << block;
		end
	end
end

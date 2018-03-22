require 'json'

module Convenience
	class User
		def initialize(mqtt, name, gid: rand(0..100000))
			@mqtt = mqtt;
			@name = name;

			@GID 	= gid;

			@homeTrack 		= @mqtt.track "Personal/#{@name}/IsHome";
			@switchTrack	= @mqtt.track "Personal/#{@name}/Switching/Who";
		end

		def notify(text, **args)
			args[:gid] ||= @GID if @GID;
			args[:text] = text;

			@mqtt.publish_to "Personal/#{@name}/Notify", args.to_json, qos: 2;
		end

		def awake?
			return @switchTrack.value != "none";
		end
		def home?
			return @homeTrack.value == "true";
		end

		def switch
			return @switchTrack.value;
		end
		def switch=(member)
			@mqtt.publish_to "Personal/#{@name}/Switching/Who", member, retain: true;
		end
	end
end

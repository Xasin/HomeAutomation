require 'json'

module Convenience
	class User
		def initialize(mqtt, name, gid: rand(0..100000))
			@mqtt = mqtt;
			@name = name;

			@GID 	= gid;

			@homeTrack 		= @mqtt.track "Personal/#{@name}/IsHome" do
				_update_awake_and_home();
			end
			@switchTrack	= @mqtt.track "Personal/#{@name}/Switching/Who" do |newState, oldState|
				# System falls asleep, new awake state is "none"
				if(newState == "none") then
					@on_awake_change.each do |c| c.call(false); end
				# System awoke from sleep, the old awake state was "none"
				elsif(oldState == "none") then
					@on_awake_change.each do |c| c.call(true); end
				end

				_update_awake_and_home();
			end

			@was_home_and_awake   = false;
			@on_home_awake_change = Array.new();
			@on_awake_change 		 = Array.new();
		end

		def notify(text, color = nil, **args)
			args[:gid] ||= @GID if @GID;
			args[:text]  = text;

			args[:color] ||= color;
			args[:color] = args[:color].to_s if args[:color];

			@mqtt.publish_to "Personal/#{@name}/Notify", args.to_json, qos: 2;
		end

		def _update_awake_and_home()
			if awake_and_home? != @was_home_and_awake then
				@on_home_awake_change.each do |c| c.call(awake_and_home?); end
				@was_home_and_awake = awake_and_home?;
			end
		end

		def awake_and_home?(&callback)
			@on_home_awake_change << callback if callback;

			return (self.awake? and self.home?);
		end
		def awake?(&callback)
			@on_awake_change << callback if callback;

			return @switchTrack.value != "none";
		end
		def home?(&callback)
			@homeTrack.attach(callback) if callback;

			return @homeTrack.value == "true";
		end
		def home=(value)
			@mqtt.publish_to "Personal/#{@name}/IsHome", value ? "true" : "false", retain: true;
		end

		def switch
			return @switchTrack.value;
		end
		def switch=(member)
			@mqtt.publish_to "Personal/#{@name}/Switching/Who", member, retain: true;
		end
		def on_switch(&callback)
			@switchTrack.attach(callback);
		end
	end
end

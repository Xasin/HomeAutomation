
module Hooks
	module TapHook
		@tapMSG = Messaging::UserClient.new($mqtt, "Xasin", "Tap");

		@formerBattery = 100;
		@lastMentioned = Time.at(0);

		$eclipse.subscribe_to "Personal/Xasin/Tap/Battery" do |data|
			newBattery = data.unpack("c");

			[25, 10, 5].each do |i|
				if((@formerBattery > i && newBattery <= i))
					if((Time.now()-@lastMentioned) > 10*60)
						@tapMSG.speak "Tap's battery is a bit low at #{newBattery} percent!", Color.RGB(255, 180, 0),
							percentage: newBattery;

						@lastMentioned = Time.now();
					end
				end
			end

			@formerBattery = newBattery;
		end

		@wasConnected = true;
		$eclipse.track "Personal/Xasin/Tap/Connection" do |data|
			if(@wasConnected && data != "OK")
				@tapMSG.speak "It seems Tap has disconnected.", Color.RGB(255, 180, 0);
			end

			@wasConnected = (data == "OK");
		end

		$eclipse.subscribe_to "Personal/Xasin/Tap/Morse/Out" do |data|
			if($xasin.awake_and_home?)
				$room.command(data);
			end
		end

		$mqtt.subscribe_to "Room/default/Info/Current" do |data|
			stdbyColor = [0, 0, 0];

			begin
				data = JSON.parse(data);

				if(c = data["color"])
					c = Color.from_s(c).rgb();

					stdbyColor = [c[2], c[1], c[0]];
				end
			rescue
			end

			$eclipse.publish_to "Personal/Xasin/Tap/StdbyColor", stdbyColor.pack("c3");
		end
	end
end

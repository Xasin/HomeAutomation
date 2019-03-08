
module Hooks
	module TapHook
		@tapMSG = Messaging::UserClient.new($mqtt, "Xasin", "Tap");

		@formerBattery = 100;
		@lastMentioned = Time.at(0);

		$eclipse.subscribe_to "Personal/Xasin/Tap/Battery" do |data|
			newBattery = data.unpack("c")[0];

			[25, 10, 5].each do |i|
				if((@formerBattery > i && newBattery <= i))
					if((Time.now()-@lastMentioned) > 10*60)
						@tapMSG.speak "Tap's battery is a bit low at #{newBattery} percent!", Color.RGB(255, 180, 0),
							percentage: newBattery;

						@lastMentioned = Time.now();
					end
				end
			end

			if(@formerBattery < 90 && newBattery >= 90)
				if((Time.now()-@lastMentioned) > 10*60)
					@tapMSG.speak "Tap is fully charged!", Color.RGB(10, 250, 50);

					@lastMentioned = Time.now();
				end
			end

			@formerBattery = newBattery;
		end

		@wasConnected = true;
		$flespi.track "Personal/Xasin/Tap/Connection" do |data|
			if(@wasConnected && data != "OK")
				@tapMSG.speak "It seems Tap has disconnected.", Color.RGB(255, 180, 0);
			end

			@wasConnected = (data == "OK");
		end

		$flespi.subscribe_to "Personal/Xasin/Tap/Morse/Out" do |data|
			if($xasin.awake_and_home?)
				$room.command(data);
			elsif data =~ /^(sw|tt|gn)/
				$room.command(data);
			end
		end

		$mqtt.subscribe_to "Room/default/Info/Current" do |data|
			stdbyColor = [0, 0, 0];

			begin
				data = JSON.parse(data);

				if(c = data["color"])
					c = Color.from_s(c).set_brightness(100).rgb();

					stdbyColor = [c[2], c[1], c[0]];
				end
			rescue
			end

			$flespi.publish_to "Personal/Xasin/Tap/StdbyColor", stdbyColor.pack("c3");
		end
	end
end

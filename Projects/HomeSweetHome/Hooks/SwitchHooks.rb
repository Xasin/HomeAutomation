
require 'timeout'

module Hooks
	module Switching

		@SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 0, 255),
			"Mesh"  => Color.RGB(0, 255, 0)
		}
		SystemColors = @SystemColors;

		@switchTTS = ColorSpeak::Client.new($mqtt, "Switching");
		@switchMSG = Messaging::UserClient.new($mqtt, "Xasin", "Switching");

		@switchPercentTrack = {"Xasin" => 0, "Neira" => 0, "Mesh" => 0};

		def self.get_switch_msg
			@switchPercentTrack.delete_if {|key| not Hooks::Switching::SystemColors.include? key }
			lowestSwitch = @switchPercentTrack.min_by {|key,value| value};

			alreadyIn = lowestSwitch[0] == $xasin.switch

			outData = {
				text:  "I recommend #{lowestSwitch[0]} at #{lowestSwitch[1]} percent to #{alreadyIn ? "stay switched" : "switch"} in.",
				color: Switching::SystemColors[lowestSwitch[0]],
				gid:   "SwitchRecommend",
				percentage: lowestSwitch[1]
			}
			outData[:inline_keyboard] = nil;
			outData[:inline_keyboard] = {"Do it!" => "/switch #{lowestSwitch[0]}"} unless alreadyIn;

			return outData;
		end

		def self.update_switch_msg
			data = get_switch_msg();
			$mqtt.publish_to "Telegram/Xasin/Edit", data.to_json
		end

		def self.switch_recommend
			$mqtt.publish_to "Telegram/Xasin/Edit", {gid: "SwitchRecommend", inline_keyboard: nil}
			data = get_switch_msg();
			@switchMSG.notify data[:text], **data;
		end

		$xasin.on_switch do |newMember, formerMember|
			formerMember ||= "none";

			begin
				Timeout.timeout(3) {
					`mosquitto_pub -h iot.eclipse.org -t 'Personal/CyanRainNin/XaHead/Who' -m #{newMember} &`
					`mosquitto_pub -h iot.eclipse.org -t 'Personal/Yyunko/XaHead/Who' -m #{newMember} &`
					$flespi.publish_to "Personal/Xasin/Switching/Who", newMember;

					push_member = newMember;
					push_member = "_nil" if newMember == "none"
					begin
						`curl -X POST -H "Content-Type: application/json" -d '{"webhook": {"command": "switch", "member_name": "#{push_member}"}}' https://www.switchcounter.science/webhook/be92e614a5831f6cbaa67f125c59853fc43dfee2 > /dev/null 2>&1 &`
					rescue
					end
				}
			rescue
			end

			if(newMember != "none" and formerMember == "none") then
				@switchMSG.speak "Good morning, #{newMember}.", @SystemColors[newMember];
			elsif(newMember != "none") then
				@switchMSG.speak "Hello #{newMember}!", @SystemColors[newMember];
			elsif(formerMember != "none") then
				@switchMSG.speak "Good night, #{formerMember}.", @SystemColors[formerMember];
			end

			update_switch_msg();
		end

		$mqtt.track "Personal/Xasin/Switching/Data" do |newData|
			@switchPercentTrack = JSON.parse(newData)["percentage"];
			update_switch_msg();
		end

		$room.on_command do |data|
			case data
			when "gm"
				Thread.new do
					sleepTime = Time.now() + 15.minutes;

					while true do
						sleep 5;

						if($xasin.switch != "none") then
							break;
						end

						if(Time.now >= sleepTime) then
							@switchTTS.speak "Please remember", @SystemColors["Xasin"]
							@switchTTS.speak "to log", @SystemColors["Neira"]
							@switchTTS.speak "your switch", @SystemColors["Mesh"]
							break;
						end
					end
				end

			when /sw([nmxs])/
				$xasin.switch = {"m" => "Mesh", "x" => "Xasin", "n" => "Neira", "s" => "none"}[$1]
			when "sr"
				switch_recommend
			when "gn"
				$xasin.switch = "none"
			end
		end

		$telegram.on_message do |message|
			mText = message[:text].downcase;
			if(mText =~ /(?:switch|switched)/ and mText =~ /(xasin|neira|mesh)/) then
				$xasin.switch = $1.capitalize

			elsif /(recommend|suggest) .*switch/ =~ mText then
				switch_recommend
			end
		end

		$mqtt.subscribe_to "Telegram/Xasin/Command" do |data|
			begin
				text = JSON.parse(data)["text"]

				if(text =~ /\/switch (Xasin|Neira|Mesh)/) then
					$xasin.switch = $1;
				end
			rescue
			end
		end
	end
end

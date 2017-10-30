
require_relative '../SetupEnv.rb'

module Hooks
	module Switching

		@SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 0, 255),
			"Mesh"  => Color.RGB(0, 255, 0)
		}

		@switchTTS = ColorSpeak::Client.new($mqtt, "Switching");
		@switchMSG = Messaging::UserClient.new($mqtt, "Xasin", "Switching");

		@who = $mqtt.track "Personal/Xasin/Switching/Who" do |newMember, formerMember|
			formerMember ||= "none";

			if(newMember != "none" and formerMember == "none") then
				@switchMSG.speak "Good morning, #{newMember}.", @SystemColors[newMember], single: true;
			elsif(newMember != "none") then
				@switchMSG.speak "Hello #{newMember}!", @SystemColors[newMember], single: true;
			elsif(formerMember != "none") then
				@switchMSG.speak "Good night, #{formerMember}.", @SystemColors[formerMember], single: true;
			end
		end

		$mqtt.subscribe_to "Room/default/Commands" do |tList, data|
		if(data == "good morning") then
			Thread.new do
				sleepTime = Time.now() + 15.minutes;

				while true do
					sleep 5;

					if(@who.value != "none") then
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
		end

		if(data =~ /sw([nmxs])/) then
			$mqtt.publish_to "Personal/Xasin/Switching/Who", {"m" => "Mesh", "x" => "Xasin", "n" => "Neira", "s" => "none"}[$1], retain: true;
		end
		if(data == "gn") then
			$mqtt.publish_to "Personal/Xasin/Switching/Who", "none", retain: true;
		end
		end
	end
end

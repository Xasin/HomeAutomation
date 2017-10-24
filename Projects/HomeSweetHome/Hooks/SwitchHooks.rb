
require_relative '../SetupEnv.rb'

module Hooks
	module Switching

		@SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 0, 255),
			"Mesh"  => Color.RGB(0, 255, 0)
		}

		@switchTTS    = ColorSpeak::Client.new($mqtt, "Switching");

		$mqtt.track "Personal/Xasin/Switching/Who" do |newMember, formerMember|
			formerMember ||= "none";

			if(newMember != "none" and formerMember == "none") then
				@switchTTS.speak "Good morning, #{newMember}", @SystemColors[newMember], single: true;
			elsif(newMember != "none") then
				@switchTTS.speak "Hello, #{newMember}", @SystemColors[newMember], single: true;
			elsif(formerMember != "none") then
				@switchTTS.speak "Good night, #{formerMember}", @SystemColors[formerMember], single: true;
			end
		end
	end
end

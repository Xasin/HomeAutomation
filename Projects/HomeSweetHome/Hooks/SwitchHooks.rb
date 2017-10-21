
require_relative '../SetupEnv.rb'

module Hooks
	module Switching

		@SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 0, 255),
			"Mesh"  => Color.RGB(0, 255, 0)
		}

		@switchTTS    = ColorSpeak::Client.new($mqtt, "Switching");

		$mqtt.track "personal/switching/Xasin/who" do |newMember, formerMember|
			formerMember ||= "none";

			if(newMember != "none" and formerMember == "none") then
				@switchTTS.speak "Good morning, #{data}", @SystemColors[data], single: true;
			elsif(newMember != "none") then
				@switchTTS.speak "Hello, #{data}", @SystemColors[data], single: true;
			elsif(formerMember != "none") then
				@switchTTS.speak "Good night, #{formerMember}", @SystemColors[formerMember], single: true;
			end
		end
	end
end

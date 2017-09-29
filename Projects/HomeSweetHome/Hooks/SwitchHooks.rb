
require_relative '../SetupEnv.rb'

module Hooks
	module Switching

		@SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 0, 255),
			"Mesh"  => Color.RGB(0, 255, 0)
		}

		@switchTTS    = ColorSpeak::Client.new($mqtt, "Switching");
		@formerMember = "none";

		$mqtt.subscribeTo "personal/switching/Xasin/who" do |topic, data|
			if(data != "none" and @formerMember == "none") then
				@switchTTS.speak "Good morning, #{data}", @SystemColors[data];
			elsif(data != "none") then
				@switchTTS.speak "Hello, #{data}", @SystemColors[data];
			elsif(@formerMember != "none") then
				@switchTTS.speak "Goodbye, #{@formerMember}", @SystemColors[@formerMember];
			end
			@formerMember = data;
		end
	end
end

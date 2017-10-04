
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

		$mqtt.subscribe_to "personal/switching/Xasin/who" do |topic, data|
			if(data != "none" and @formerMember == "none") then
				@switchTTS.speak "Good morning, #{data}", @SystemColors[data], single: true;
			elsif(data != "none") then
				@switchTTS.speak "Hello, #{data}", @SystemColors[data], single: true;
			elsif(@formerMember != "none") then
				@switchTTS.speak "Good night, #{@formerMember}", @SystemColors[@formerMember], single: true;
			end
			@formerMember = data;
		end
	end
end

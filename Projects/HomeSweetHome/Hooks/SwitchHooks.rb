
require_relative '../SetupEnv.rb'

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

		$mqtt.track "Personal/Xasin/Switching/Who" do |newMember, formerMember|
			formerMember ||= "none";

			begin
			`curl -X POST -H "Content-Type: application/json" -d '{"webhook": {"command": "switch", "member_name": "#{newMember}"}}' https://hidden-cliffs-30452.herokuapp.com/webhook/be92e614a5831f6cbaa67f125c59853fc43dfee2 > /dev/null 2>&1 &`
			rescue
			end

			if(newMember != "none" and formerMember == "none") then
				@switchMSG.speak "Good morning, #{newMember}.", @SystemColors[newMember];
			elsif(newMember != "none") then
				@switchMSG.speak "Hello #{newMember}!", @SystemColors[newMember];
			elsif(formerMember != "none") then
				@switchMSG.speak "Good night, #{formerMember}.", @SystemColors[formerMember];
			end
		end

		$room.on_command do |data|
		if(data == "good morning") then
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
		end

		if(data =~ /sw([nmxs])/) then
			$xasin.switch = {"m" => "Mesh", "x" => "Xasin", "n" => "Neira", "s" => "none"}[$1]
		end
		if(data == "gn") then
			$xasin.switch = "none"
		end
		end

		$telegram.on_message do |message|
			mText = message[:text].downcase;
			if(mText =~ /(?:switch|switched)/ and mText =~ /(xasin|neira|mesh)/) then
				$xasin.switch = $1.capitalize
			end
		end
	end
end

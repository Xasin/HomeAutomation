
require_relative "Constants.rb"
require 'haversine'

module Hooks
	module PokeLukas

		@lastLunchPoked = Time.at(0);
		$mqtt.subscribe_to "Personal/Xasin/Position" do |data|
			begin
				data = JSON.parse(data);
			rescue
				next;
			end

			currentTime = Time.now().min.minutes + Time.now().hour.hours
			next unless currentTime.between?(11.5.hours, 14.hours)

			position = [data["lat"], data["lon"]];
			accuracy = data["acc"];
			lunchDistance = Haversine.distance(Xasin::Locations::Lunch, position).to_m - accuracy;

			next;

			if((lunchDistance < 30) and (Time.now() - @lastLunchPoked) > 5.hours)
				@lastLunchPoked = Time.now();

				$mqtt.publish_to("Telegram/Lukas/Send", {
					text: "David ist jetzt in der Mensa! Kommst du auch?",
					inline_keyboard: {"Ja!" => "/mensa confirm", "Nein" => "/mensa deny"},
					gid: "MensaCheck"
				}.to_json)
			end
		end

		$mqtt.subscribe_to "Telegram/Lukas/Command" do |data|
			begin
				data = JSON.parse(data);
			rescue
				next;
			end

			case data["text"]
			when /\/mensa (confirm|deny)/
				$mqtt.publish_to("Telegram/Lukas/Edit", {gid: "MensaCheck", inline_keyboard: nil}.to_json)

				if($1 == "confirm")
					$mqtt.publish_to "Telegram/Lukas/Send", "Super!"
					$mqtt.publish_to "Telegram/Xasin/Send", "Lukas kommt auch gleich!"
				else
					$mqtt.publish_to "Telegram/Lukas/Send", "Schade ... Aber ok."
				end
			end
		end

		$mqtt.subscribe_to "Telegram/Lukas/Received" do |data|
			begin
				data = JSON.parse(data);
			rescue
				next;
			end

			$mqtt.publish_to "Telegram/Lukas/Send", "Tut mir leid, noch kann ich nichts!"
		end
	end
end

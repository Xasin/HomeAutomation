
require_relative "Constants.rb"
require 'haversine'

module Hooks
	module PokeLukas

		@isAtLunch = false;
		$mqtt.subscribe_to "Personal/Xasin/Position" do |data|
			begin
				data = JSON.parse(data);
			rescue
				next;
			end

			position = [data["lat"], data["lon"]];
			accuracy = data["acc"];

			lunchDistance = Haversine.distance(Xasin::Locations::Lunch, position).to_m - accuracy;

			nextLunchState = lunchDistance < (@isAtLunch ? 80 : 50);
			if(nextLunchState != @isAtLunch)
				@isAtLunch = nextLunchState;

				if(@isAtLunch)
					$mqtt.publish_to "Telegram/Lukas/Send", "David ist jetzt in der Mensa!";
				end
			end
		end
	end
end

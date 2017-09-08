
require_relative '../SetupEnv.rb'

module Hooks
	module Switching

		$SystemColors = {
			"Xasin" => Color.RGB(255, 0, 0),
			"Neira" => Color.RGB(0, 255, 0),
			"Mesh"  => Color.RGB(0, 0, 255)
		}

		$switchTTS = ColorSpeak::Client.new($mqtt, "Switching");

		$mqtt.subscribeTo "personal/switching/Xasin/who" do |topic, data|
			$switchTTS.speak "Welcome back, #{data}", $SystemColors[data] if $SystemColors.key? data;
		end
	end
end

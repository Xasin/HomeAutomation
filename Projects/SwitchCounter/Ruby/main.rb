
require 'rubygems'

require_relative "credentials"
require_relative "SwitchHandler.rb"

$xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd],
										clean_session: false, client_id: "RB Switching Counter");

$switchTime = SwitchHandler.new("SwitchTimes.db");

Thread.new do
	while true
		sleep 60;

		packData = Hash.new();
		packData[:percentage] 	= $switchTime.getPercentagesSince("Xasin", Time.now.to_i - 60*60*24 *3);
		packData[:total] 			= $switchTime.getTimesSince("Xasin", Time.now.to_i - 60*60*24 *3);

		$xaQTT.publish('personal/switching/Xasin/', packData.to_json);
	end
end

$xaQTT.get('personal/switching/Xasin/who') do |topic, payload|
	$switchTime.switchTo("Xasin", payload);
end


require 'rubygems'

require_relative "credentials"
require_relative "SwitchHandler.rb"

$xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd]);

$switchTime = SwitchHandler.new("SwitchTimes.db");

normalCFG = {
	updateInterval: 	3*60,
	measureTimespan:	7*24*60*60
}


timingCFG = normalCFG;
Thread.new do
	while true
		sleep timingCFG[:updateInterval]; # Debug time!

		$switchTime.autosave();

		packData = Hash.new();
		packData[:percentage] 	= $switchTime.getPercentagesSince("Xasin", Time.now.to_i - timingCFG[:measureTimespan]);
		packData[:total] 			= $switchTime.getTimesSince("Xasin", Time.now.to_i - timingCFG[:measureTimespan]);

		$xaQTT.publish('personal/switching/Xasin/data', packData.to_json, retain=true);
	end
end

$xaQTT.get('personal/switching/Xasin/who') do |topic, payload|
	$switchTime.switchTo("Xasin", payload);
end

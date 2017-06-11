
require 'rubygems'

require_relative "credentials"
require_relative "SwitchHandler.rb"

$xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd]);

$switchTime = SwitchHandler.new("SwitchTimes.db");

normalCFG = {
	updateInterval: 	3*60,
	measureTimespan:	7*24*60*60
}

debugCFG = {
	updateInterval:	5,
	measureTimespan: 	120
}

timingCFG = normalCFG;

Thread.new do
	$xaQTT.get('personal/switching/+/who') do |topic, payload|
		sysName = topic.match(/^personal\/switching\/(\w+)\/who$/)[1];
		$switchTime.switchTo(sysName, payload) unless sysName == nil;
	end
end

while true
	sleep timingCFG[:updateInterval];

	$switchTime.autosave();

	$switchTime.getSystems().each do |key, value|
		packData = Hash.new();
		packData[:percentage] 	= $switchTime.getPercentagesSince(key, Time.now.to_i - timingCFG[:measureTimespan]);
		packData[:total] 			= $switchTime.getTimesSince(key, Time.now.to_i - timingCFG[:measureTimespan]);
		$xaQTT.publish("personal/switching/#{key}/data", packData.to_json, retain=true);
	end
end


require 'rubygems'

require_relative 'MQTTSubscriber.rb'

require_relative "credentials"
require_relative "SwitchHandler.rb"

$xaQTT = MQTTSubs.new(MQTT::Client.new($mqtt_host));

$switchTime = SwitchHandler.new("SwitchTimes.db");

normalCFG = {
	updateInterval: 	3*60,
	measureTimespan:	3*24*60*60
}

debugCFG = {
	updateInterval:	5,
	measureTimespan: 	120
}

timingCFG = normalCFG;


$xaQTT.subscribeTo 'personal/switching/+/who' do |topic, payload|
	sysName = topic[0];
	$switchTime.switchTo(sysName, payload) unless sysName == nil;
end

while true
	sleep timingCFG[:updateInterval];

	$switchTime.autosave();

	$switchTime.getSystems().each do |key, value|
		packData = Hash.new();
		packData[:percentage] 	= $switchTime.getPercentagesSince(key, Time.now.to_i - timingCFG[:measureTimespan]);
		packData[:total] 			= $switchTime.getTimesSince(key, Time.now.to_i - timingCFG[:measureTimespan]);
		$xaQTT.publishTo "personal/switching/#{key}/data", packData.to_json, retain: true;
	end
end


require 'mqtt'
require 'sinatra'

require_relative "credentials.rb"

$xaQTT = MQTT::Client.connect(host: $mqtt_credentials[:host], port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd]);

def MQTT_reconnect()
	return if $connecting;

	$connecting = true;

	while true
		begin
			$xaQTT = MQTT::Client.connect(host: $mqtt_credentials[:host], port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd], client_id: "SwitchNote-#{`hostname`}", clean_session: false);
		rescue
			$connectAttempts += 1;
			print "Connecting (#{$connectAttempts})\n"
			sleep 10;
		else
			$connecting = false;
			$connectAttempts = 0;
			return;
		end
	end
end

$currentMember = Hash.new() do |h, k| $h[k] = "none"; end

def setPic(sysName, memName)

end

Thread.new do
	while true
		begin
			$xaQTT.get "personal/switching/+/who" do |topic, payload|
				return if payload == "none";
				sysName = topic.match(/^personal\/switching\/(\w+)\/who$/)[1];
				$currentMember[sysName] = payload;
			end
		rescue
			MQTT_reconnect();
		end
	end
end

get "/switchPics/Xasin" do
	send_file "Pics/#{$currentMember["Xasin"]}.jpg";
end

require 'mqtt'

Process.setproctitle("switchNote");
Process.daemon();
require_relative 'Ruby/credentials'

$connectAttempts = 0;
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

while true
	begin
		$xaQTT.get('personal/switching/+/who') do |topic, payload|
			sysName = topic.match(/^personal\/switching\/(\w+)\/who$/)[1];
			`notify-send 'SwitchTime' 'System #{sysName} has just switched over to #{payload}'`
			sleep 5;
		end

	rescue
		MQTT_reconnect();
	end
end

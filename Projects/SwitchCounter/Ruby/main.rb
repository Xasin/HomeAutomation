
require 'rubygems'
require 'mqtt'

require_relative "credentials"


xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd],
										clean_session: false, client_id: "RB Switching Counter");

class SwitchTimer
	def initialize
		@switchTimes = Hash.new(0);

		@hostInfo = {
			inSince: 0,
			name:		"none"
		}
	end

	def switchTo(name)
		return unless(name != @hostInfo[:name])

		swTime = Time.now.to_i - @hostInfo[:inSince];

		if @hostInfo[:name] != "none" then
			print("Switching from #{@hostInfo[:name]} (who's been in for #{swTime} seconds, #{@switchTimes[@hostInfo[:name]] + swTime} total) to #{name}!\n");

			@switchTimes[@hostInfo[:name]] += Time.now.to_i - @hostInfo[:inSince];
		else
			print("Switching to: #{name}\n");
		end

		@hostInfo[:name]		= name;
		@hostInfo[:inSince] 	= Time.now.to_i;
	end
end

$switchTime = SwitchTimer.new
$switchTime.switchTo('none')

xaQTT.get('personal/switching/who') do |topic, payload|
	$switchTime.switchTo payload
end


require 'rubygems'
require 'mqtt'
require 'json'

require_relative "DBManager.rb"
require_relative "credentials"


$xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd],
										clean_session: false, client_id: "RB Switching Counter");

class SwitchTimer
	def initialize(systemName)
		@switchTimes = Hash.new(0);

		@system = systemName;

		@hostInfo = {
			inSince: 0,
			name:		"none"
		}

		@database = DBManager.new("SwitchTimes.db");
	end

	def switchTo(name)
		return unless(name != @hostInfo[:name])

		swTime = Time.now.to_i - @hostInfo[:inSince];

		if @hostInfo[:name] != "none" then
			@database.registerSwitch(@system, @hostInfo[:name], @hostInfo[:inSince], swTime);

			print("Switching from #{@hostInfo[:name]} (who's been in for #{swTime} seconds, #{@database.systemSwitchTimesSince("Xasin", 0)[@hostInfo[:name]]}) to #{name}!\n");
		else
			print("Switching to: #{name}\n");
		end

		@hostInfo[:name]		= name;
		@hostInfo[:inSince] 	= Time.now.to_i;
	end
end

$switchTime = SwitchTimer.new("Xasin");
$switchTime.switchTo('none')

$xaQTT.get('personal/switching/Xasin/who') do |topic, payload|
	$switchTime.switchTo payload
end

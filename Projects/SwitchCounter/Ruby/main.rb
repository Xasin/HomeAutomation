
require 'rubygems'
require 'sqlite3'
require 'mqtt'
require 'json'

require_relative "credentials"


$xaQTT = MQTT::Client.connect(host: '192.168.178.111', port: 1883, username: $mqtt_credentials[:username], password: $mqtt_credentials[:passwd],
										clean_session: false, client_id: "RB Switching Counter");

class DBManager
	def initialize(dbName)
		dbInitialized = File.file?(dbName);

		@switchDB = SQLite3::Database.new dbName
		@switchDB.type_translation = true;

		unless dbInitialized
			@switchDB.execute <<-SQL
CREATE TABLE SwitchTimes (
	system 		VARCHAR(50),
	member		VARCHAR(50),
	startTime 	UNSIGNED BIGINT,
	switchTime	UNSIGNED INT
);
			SQL
		end
	end

	def registerSwitch(systemName, member, startTime, totalTime)
		sqlCMD = <<-SQL
INSERT INTO SwitchTimes
VALUES ('#{systemName}', '#{member}', #{startTime}, #{totalTime});
		SQL

		@switchDB.execute(sqlCMD);
	end

	def getSystemMembers(systemName)
		sysMembers = Array.new;

		@switchDB.execute("SELECT DISTINCT member FROM SwitchTimes WHERE system = '#{systemName}'") do |row|
			sysMembers << row[0];
		end

		return sysMembers;
	end

	def getSwitchTimes(systemName)
		switchTimes = Hash.new;
		@switchDB.execute("SELECT member, sum(switchTime) FROM SwitchTimes WHERE system = '#{systemName}' GROUP BY member") do |row|
			switchTimes[row[0]] = row[1];
		end

		return switchTimes;
	end
end

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

			$xaQTT.publish('personal/switching/Xasin/times', @database.getSwitchTimes("Xasin").to_json, true);

			print("Switching from #{@hostInfo[:name]} (who's been in for #{swTime} seconds, #{@database.getSwitchTimes(@system)[@hostInfo[:name]]} total) to #{name}!\n");
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

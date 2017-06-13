
require 'json'

require_relative "DBManager.rb"

class SwitchHandler

	def initialize(dbName)
		@systemInfos = Hash.new() do |h, k|
			h[k] = {startTime: 0, member: "none", lastSave: 0};
		end

		@database 	= DBManager.new(dbName);
	end

	def switchTo(systemName, memberName)
		print("Switching to #{memberName}\n");
		sysInfo = @systemInfos[systemName];

		return if memberName == sysInfo[:member];

		switchLength = Time.now.to_i - sysInfo[:startTime];

		unless sysInfo[:member] == "none"
			@database.updateSwitch(systemName, sysInfo[:member], sysInfo[:startTime], switchLength);

			print("Time percentages: #{getPercentagesSince(systemName, 0).inspect}\n");
		end

		@database.registerSwitch(systemName, memberName, Time.now.to_i) unless memberName == "none";

		sysInfo = {
			startTime: 	Time.now.to_i,
			member:		memberName,
			lastSave: 	Time.now.to_i
		};
		@systemInfos[systemName] = sysInfo;
	end

	def getSystems()
		return @database.Systems();
	end

	def autosave()
		@systemInfos.each do |key, value|
			unless value[:member] == "none"
				@database.updateSwitch(key, value[:member], value[:startTime], Time.now.to_i - value[:startTime]);
				value[:lastSave] = Time.now.to_i;
			end
		end
	end

	def getTimesSince(systemName, timestamp)
		sysInfo = @database.systemSwitchTimesSince(systemName, timestamp);

		currentMember = @systemInfos[systemName][:member];
		unless currentMember == "none" then
			sysInfo[currentMember] += Time.now.to_i - [@systemInfos[systemName][:lastSave], timestamp].max; end

		return sysInfo;
	end

	def getTotalTimeSince(systemName, timestamp)
		sysInfo = getTimesSince(systemName, timestamp);
		totalTime = 0;
		sysInfo.each do |key, value|
			totalTime += value;
		end

		return totalTime;
	end

	def getPercentagesSince(systemName, timestamp)
		percentages = Hash.new();

		sysInfo = getTimesSince(systemName, timestamp);
		totalTime = getTotalTimeSince(systemName, timestamp);

		sysInfo.each do |key, value|
			if(totalTime == 0) then
				percentages[key] = 0;
			else
				percentages[key] = value*100/totalTime;
			end
		end

		return percentages;
	end
end

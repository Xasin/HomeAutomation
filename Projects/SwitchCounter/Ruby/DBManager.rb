
require 'sqlite3'

class DBManager
	def initialize(dbName)
		dbInitialized = File.file?(dbName);

		@switchDB = SQLite3::Database.new dbName
		@switchDB.type_translation = true;

		unless dbInitialized
			@switchDB.execute_batch <<-SQL

CREATE TABLE SwitchTimes (
	member 		UNSIGNED INT,
	startTime 	UNSIGNED BIGINT,
	switchTime	UNSIGNED BIGINT
);

CREATE TABLE Systems (
	ID 		UNSIGNED INT AUTO_INCREMENT,
	name		varchar,
	PRIMARY KEY(ID)
);

CREATE TABLE Members (
	ID			UNSIGNED INT AUTO_INCREMENT,
	system	UNSIGNED INT,
	name		varchar,
	PRIMARY KEY(ID)
)
SQL
		end

		genSyshash();
	end

	def Systems()
		systems = Hash.new();

		@switchDB.execute("SELECT name, ID FROM Systems") do |row|
			systems[rows[0]] = rows[1];
		end

		return systems;
	end

	def MembersForSystem(sysName)
		members = Hash.new();

		@switchDB.execute("SELECT M.name, M.ID FROM Members AS M, Systems AS S WHERE S.ID = M.system AND S.name = '#{sysName}'") do |row|
			members[row[0]] = row[1];
 		end

		return members;
	end

	def genSyshash()
		@syshash = Hash.new();
		Systems().each do |sys
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

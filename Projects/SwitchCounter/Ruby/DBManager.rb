
require 'sqlite3'

class DBManager
	def initialize(dbName)
		dbInitialized = File.file?(dbName);

		@switchDB = SQLite3::Database.new dbName
		@switchDB.type_translation = true;

		unless dbInitialized
			@switchDB.execute_batch <<-SQL

		CREATE TABLE SwitchTimes (
			member 		INTEGER,
			startTime 	UNSIGNED BIGINT,
			switchTime	UNSIGNED BIGINT
		);

		CREATE TABLE Systems (
			ID 		INTEGER PRIMARY KEY ASC,
			name		varchar
		);

		CREATE TABLE Members (
			ID			INTEGER PRIMARY KEY ASC,
			system 	INTEGER,
			name		varchar
		);
		SQL
		end
	end

	def Systems()
		systems = Hash.new();

		@switchDB.execute("SELECT name, ID FROM Systems;") do |row|
			systems[rows[0]] = rows[1];
		end

		return systems;
	end

	def MembersForSystem(sysName)
		members = Hash.new();

		@switchDB.execute("SELECT M.name, M.ID FROM Members AS M, Systems AS S WHERE S.ID = M.system AND S.name = '#{sysName}';") do |row|
			members[row[0]] = row[1];
 		end

		return members;
	end

	def memberID(sysName, memberName)
		mID = @switchDB.get_first_value("SELECT M.ID FROM Members AS M, Systems AS S WHERE S.ID = M.system AND S.name = '#{sysName}' AND M.name = '#{memberName}';");
		return mID unless mID == nil;

		sysID = @switchDB.get_first_value("SELECT ID FROM Systems WHERE name = '#{sysName}';");
		if sysID == nil then
			@switchDB.execute <<-SQL
			INSERT INTO Systems
			VALUES (null, '#{sysName}');
			SQL
		end

		sysID = @switchDB.get_first_value("SELECT ID FROM Systems WHERE name = '#{sysName}';");

		@switchDB.execute <<-SQL
		INSERT INTO Members
		VALUES (null, #{sysID}, '#{memberName}');
			SQL

		return @switchDB.get_first_value("SELECT M.ID FROM Members AS M, Systems AS S WHERE S.ID = M.system AND S.name = '#{sysName}' AND M.name = '#{memberName}';");
	end

	def registerSwitch(systemName, member, startTime, totalTime)
		@switchDB.execute <<-SQL
		INSERT INTO SwitchTimes
		VALUES (#{memberID(systemName, member)}, #{startTime}, #{totalTime});
		SQL
	end

	def systemSwitchTimesSince(systemName, timestamp)
		times = Hash.new(0);

		sqlCMD = <<-SQL
		SELECT M.name, sum(switchTime)
		FROM SwitchTimes AS T
		INNER JOIN Members AS M ON M.ID = T.member
		INNER JOIN Systems AS S ON S.ID = M.system
		WHERE T.startTime > #{timestamp}
		GROUP BY M.name
		SQL

		@switchDB.execute(sqlCMD) do |row|
			times[row[0]] = row[1];
		end

		return times;
	end
end

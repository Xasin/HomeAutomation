
require 'sqlite3'

class FoodDB
	def initialize(dbName = "Food.db")
		dbExisted = File.file?(dbName);

		@foodDB = SQLite3::Database.new(dbName);
		@foodDB.type_translation = true;
		@foodDB.results_as_hash = true;

		_initialize_db unless dbExisted;

		at_exit {
			@foodDB.close();
		}
	end

	def _initialize_db()
		@foodDB.execute_batch <<-SQL
			CREATE TABLE Consumables (
				ID			INTEGER PRIMARY KEY ASC,
				Name		varchar,
				Category varchar
			);

			CREATE TABLE Consumed (
				ConsumedID	INTEGER,
				EatenAt		BIGINT,
				Amount		FLOAT
			)
		SQL
	end

	def get_food_id(name)
		return @foodDB.get_first_value("SELECT ID FROM Consumables WHERE Name = '#{name}';")
	end
	def get_food_info(id)
		return @foodDB.get_first_row("SELECT * FROM Consumables WHERE ID = '#{id}';")
	end
	def get_foods()
		output = Hash.new();

		@foodDB.execute("SELECT * FROM Consumables") do |row|
			id = row.delete 'ID';
			output[id] = row;
		end

		return output;
	end

	def add_new_food(name, category = "Food")
		raise "Food already present!" if get_food_id(name);

		@foodDB.execute("INSERT INTO Consumables(Name, Category) VALUES (?,?)", name, category)

		return get_food_id(name);
	end

	def log_consumption(id, amount = 1)
		if(id.is_a? String)
			id = get_food_id(id);
			raise "Food not known!" unless id;
		end

		@foodDB.execute("INSERT INTO Consumed(ConsumedID,EatenAt,Amount) VALUES (?,?,?);", id, Time.now().to_i, amount)
	end

	def get_consumed_between(startTime = 0, endTime = Time.now())
		return @foodDB.execute("SELECT * FROM Consumed WHERE EatenAt BETWEEN ? AND ?;", startTime.to_i, endTime.to_i)
	end

	def get_amount_consumed_between(startTime = 0, endTime = Time.now())
		return @foodDB.execute("SELECT ConsumedID, SUM(Amount) FROM Consumed WHERE EatenAt BETWEEN ? AND ? GROUP BY ConsumedID;",
			startTime.to_i, endTime.to_i)
	end
end

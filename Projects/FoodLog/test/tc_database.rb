
require 'test/unit'
require_relative '../DBManager.rb'

class Test_Database < Test::Unit::TestCase
	def setup()
		begin
			File.delete("/tmp/Test.db");
		rescue
		end
		@db = FoodDB.new("/tmp/Test.db");
	end

	def test_add_food()
		assert_nothing_raised do
			@db.add_new_food("TestFood","TestStuff");
		end

		assert_not_nil @db.get_food_id("TestFood");

		assert_raise do
			@db.add_new_food("TestFood");
		end

		expectedEntry = {
			"ID" => 1,
			"Name" => "TestFood",
			"Category" => "TestStuff"
		}
		assert_equal expectedEntry,
			@db.get_food_info(@db.get_food_id("TestFood"));
	end

	def test_consumption()
		@db.add_new_food("TestFoodA", "TestFood");
		@db.add_new_food("TestFoodB", "TestFood");

		assert_raise do
			@db.log_consumption("NonexistantFood");
		end

		@db.log_consumption(@db.get_food_id("TestFoodA"));
		expectedReturn = [
			{
				"ConsumedID" => 1,
				"EatenAt"	 => Time.now().to_i,
				"Amount"		 => 1,
			}
		]
		assert_equal expectedReturn, @db.get_consumed_between();

		@db.log_consumption("TestFoodB", 2);
		expectedReturn << {
			"ConsumedID" => 2,
			"EatenAt"	 => Time.now().to_i,
			"Amount"		 => 2,
		}
		assert_equal expectedReturn, @db.get_consumed_between();

		@db.log_consumption(@db.get_food_id("TestFoodA"), 3);
		expectedReturn = [
			{
				"ConsumedID"  => 1,
				"SUM(Amount)" => 4
			},
			{
				"ConsumedID"  => 2,
				"SUM(Amount)" => 2
			}
		]
		assert_equal expectedReturn, @db.get_amount_consumed_between();
	end
end

require_relative 'DBManager.rb'

$db = FoodDB.new();

$foodRename 		= {
	"Gebaeck" => "Gebäck",
	"Lymphnodes" => "Lymphfknoten (Hals)",
	"Nausea" => "Übelkeit",
	"BadSleep" => "Schlechter Schlaf",
	"Shivers" => "Zittern/Kältegefühl",
	"Cheese" => "Käse",
	"Onion" => "Zwiebeln",
	"Garlic" => "Knoblauch",
	"Lactose" => "Laktose",
	"Pudding" => "Laktose",
	"MentalStress" => "Stress/Unruhegefühl"
}
$categoryRename 	= {
	"add" => "Food"
}

$foodList 		= Hash.new();
$categoryList 	= Array.new();

$db.get_foods().each do |fID, food|
	if(n = $categoryRename[food["Category"]])
		food["Category"] = n;
	end

	if(n = $foodRename[food["Name"]])
		food["Name"] = n;
	end

	$foodList[fID] = {
		name: food["Name"],
		category: food["Category"]
	}

	unless($categoryList.include? food["Category"])
		$categoryList << food["Category"];
	end
end

$categoryLogList = Hash.new();
$categoryList.each do |c|
	$categoryLogList[c] = ""

	header = "Tag,";
	$foodList.each do |id, data|
		if(data[:category] == c)
			header += "#{data[:name]},"
		end
	end

	$categoryLogList[c] += header.chomp(',') + "\n";
end

def get_for_day(day)
	timeArray = day.to_a

	(0..2).each do |i| timeArray[i] = 0; end
	startTime = Time.local(*timeArray);

	timeArray[0] = 59;
	timeArray[1] = 59;
	timeArray[2] = 23;

	endTime = Time.local(*timeArray);

	consumedList = Hash.new(0);

	$db.get_consumed_between(startTime, endTime).each do |data|
		amount = data["SUM(Amount)"];
		amount = 1 if data["SUM(Amount)"].nil?

		consumedList[data["ConsumedID"]] += amount.to_i
	end

	return consumedList
end

def log_for_day(day)
	omNommed = get_for_day(day);

	$categoryList.each do |c|
		$categoryLogList[c] += "#{day.day}.#{day.month},"
	end

	$foodList.each do |id, data|
		amountEaten = omNommed[id] | 0;
		$categoryLogList[data[:category]] += "#{amountEaten},"
	end

	$categoryList.each do |c|
		$categoryLogList[c].chomp!(',')
		$categoryLogList[c] += "\n";
	end
end

currentDay = Time.now() - 3*7*24*60*60;
while(currentDay <= Time.now())
	log_for_day(currentDay);
	currentDay += 24*60*60;
end

`rm *_data.csv`

$categoryLogList.each do |category, d|
	`echo "#{d}" >> #{category}_data.csv`
end

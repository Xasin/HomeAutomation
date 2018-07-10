
require 'mqtt/sub_handler.rb'
require 'json'

require_relative 'mqttLogin.rb'
require_relative 'DBManager.rb'

$database  = FoodDB.new();
$eventFName = "eventLog.csv";

def log_event(data)
	timeString = Time.now().strftime("%m.%d %H:%M")

	File.open($eventFName, "a") do |f|
		f.puts "#{timeString};#{data}"
	end
end

def send_raw(data)
	$mqtt.publish_to "Telegram/Xasin/Send", data.to_json
end
def send_msg(msg)
	send_raw({text: msg});
end

$mqtt.subscribe_to "Telegram/Xasin/Command" do |data|
	begin
		data = JSON.parse(data);
	rescue
		next;
	end

	cmd = data["text"];

	case cmd
	when /^\/addfood (\w+)(?: (\w+))?/
		begin
			category = "Food"
			category = $2 if $2;
			$database.add_new_food($1, category);
		rescue
			send_msg "That food already exists!"
		else
			send_msg "Food added, thanks!"
		end

	when /^\/logfood (.+)/
		foodList = $1
		command = "/logfood #{foodList}"

		foodIDList = Hash.new();

		unknownFood = catch :unknown_food do
			foodList.split(" ").each do |food|
				next unless food =~ /(\w+)(?:\*(\d+(?:\.\d+)?))?/

				foodID = $database.get_food_id($1);
				throw :unknown_food, $1 unless foodID

				amount = $2.to_f;
				amount = 1 if amount == 0;

				foodIDList[foodID] = amount;
			end
			nil;
		end

		if(unknownFood) then
			send_raw({
				text: "Sorry, food #{unknownFood} isn't known yet!",
				inline_keyboard: {"Try again!" => command}
				});
		else
			foodIDList.each do |id, amount|
				$database.log_consumption(id, amount);
			end
			send_msg "Alright, logged #{foodIDList.length} entries!"
		end

	when /^\/logevent (.+)/
		log_event($1);
		send_msg "Alright, got that. Thanks for telling me!"
	end
end

$mqtt.lockAndListen();

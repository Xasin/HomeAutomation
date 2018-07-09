
require 'mqtt/sub_handler.rb'
require 'json'

require_relative 'mqttLogin.rb'
require_relative 'DBManager.rb'

$database = FoodDB.new();

def send_raw(data)
	$mqtt.publish_to "Telegram/Xasin/Send", data.to_json
end
def send_msg(msg)
	send_raw({text: msg});
end

$mqtt.subscribe_to "Telegram/Xasin/Commands" do |data|
	begin
		data = JSON.parse(data);
	rescue
		next;
	end

	cmd = data[:text];

	case cmd
	when /^\/addfood (\w+)(?: (\w+))?/
		begin
			$database.add_new_food($1, $2 | "Food");
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

				begin
					foodIDList[$database.get_food_id($1)] = $2 or 1;
				rescue
					throw :unknown_food, $1
				end
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
	end
end

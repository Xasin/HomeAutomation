
module Hooks
	module DSKorder
		$mqtt.subscribe_to "Telegram/Xasin/Command" do |cmd|
			begin
				data = JSON.parse(data);
				cmd = data["text"];
			rescue
				next;
			end

			case cmd
			when /^\/dsky esc/
				$flespi.publish_to "DSKorder/Console/BTN", [27].pack("c");
			when /^\/dsky (.*)/
				$flespi.publish_to "DSKorder/Console/In", $1;
			end
		end
	end
end

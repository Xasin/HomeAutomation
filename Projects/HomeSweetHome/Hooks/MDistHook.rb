
require_relative '../MessageDistributor/MessageDistributor.rb'

module Messaging
	@telegramGIDTable = Hash.new();

	@telegramMEndpoint = Messaging::Endpoint.new() do |data|
		$mqtt.publish_to "Telegram/Xasin/Send", data.to_json;
	end
	@telegramMEndpoint.available 	= true;
	@telegramMEndpoint.priority  	= -1;
	@telegramMEndpoint.secret		= true;

	$messageDistributor = Messaging::Distributor.new($mqtt, "Xasin", @telegramMEndpoint);

	@ttsMEndpoint = $messageDistributor.add_endpoint() do |data|
		$cSpeak.process_message(data);
	end

	$xasin.awake_and_home? do |state|
		@ttsMEndpoint.available = state;
	end

	$telegram.on_message do |message|
		if message[:text] =~ /\/cmd (.+)/ then
			$room.command $1
		end
	end
end

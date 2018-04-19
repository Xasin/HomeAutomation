
require_relative '../MessageDistributor/MessageDistributor.rb'

module Messaging
	@telegramGIDTable = Hash.new();

	@telegramMEndpoint = Messaging::Endpoint.new() do |data|
		if(data[:single] and data[:gid] and @telegramGIDTable[data[:gid]]) then
			$telegram.delete_message(@telegramGIDTable[data[:gid]]);
		end
		mID = $telegram.send_message(data[:text], disable_notification: data[:silent]);

		@telegramGIDTable[data[:gid]] = mID if data[:gid];
	end
	@telegramMEndpoint.available 	= true;
	@telegramMEndpoint.priority  	= -1;
	@telegramMEndpoint.secret		= true;

	$messageDistributor = Messaging::Distributor.new($mqtt, "Xasin", @telegramMEndpoint);

	@ttsMEndpoint = $messageDistributor.add_endpoint() do |data|
		$cSpeak.process_message(data);
	end

	@XasinHome = $mqtt.track "Personal/Xasin/IsHome" do |newState|
		@ttsMEndpoint.available = ((@XasinHome.value == "true") and (@XasinAwake.value != "none"));
	end
	@XasinAwake = $mqtt.track "Personal/Xasin/Switching/Who" do |newState|
		@ttsMEndpoint.available = ((@XasinHome.value == "true") and (@XasinAwake.value != "none"));
	end

	$telegram.on_message do |message|
		if message[:text] =~ /\/cmd (.+)/ then
			$mqtt.publish_to "Room/default/Commands", $1, qos: 2;
		end
	end
end

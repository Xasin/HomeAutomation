
require 'thread'
require 'json'

module Messaging
	class Distributor
		def initialize(mqtt, name, defaultEndpoint)
			@mqtt = mqtt;
			@name = name;

			@messageQueue = Queue.new();

			@endpointList = Array.new();
			@endpointList << defaultEndpoint;

			@mqtt.subscribe_to "Personal/#{@name}/Notify" do |tList, data|
				begin
					data = JSON.parse(data, symbolize_names: true);
					forward_message(data);
				rescue
				end
			end

			Thread.new do
				loop do
					toProcessMessage = @messageQueue.pop;

					bestEndpoint = @endpointList[0];
					@endpointList.each do |e|
						if(e.available and (e.priority > bestEndpoint.priority) and (e.secret or not toProcessMessage[:secret])) then
							bestEndpoint = e;
						end
					end

					bestEndpoint.forward_message(toProcessMessage);
				end
			end
		end

		def forward_message(data)
			@messageQueue << data;
		end

		def add_endpoint(&callback)
			newEndpoint = Endpoint.new(&callback);
			@endpointList << newEndpoint

			return newEndpoint;
		end
	end

	class Endpoint
		attr_accessor :available
		attr_accessor :priority
		attr_accessor :secret

		def initialize(&callback)
			@available 	= false;
			@priority 	= 0;
			@secret 	= false;

			@data_callback = callback;
		end

		def forward_message(data)
			@data_callback.call(data);
		end
	end

	class UserClient
		def initialize(mqtt, name, gid = nil)
			@mqtt = mqtt;
			@Name = name;
			@GID  = gid;
		end

		def notify(data)
			data[:gid] ||= @GID if @GID;
			@mqtt.publish_to "Personal/#{@Name}/Notify", data.to_json, qos: 2;
		end

		def speak(text, color = nil, **args)
			args ||= Hash.new();

			args[:text] 	= text;
			args[:color] 	= color.to_s if color;

			notify(args);
		end
	end
end

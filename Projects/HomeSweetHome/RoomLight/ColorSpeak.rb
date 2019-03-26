
require 'json'

require_relative '../Libs/ColorUtils.rb'
require_relative '../Libs/Waitpoint.rb'

module ColorSpeak
class Server
	def initialize(led, mqtt, roomName = "default")
		@led = led;
		@mqtt = mqtt;

		@RoomName = roomName;

		@userColor = Color.RGB(0, 0, 0);
		@speaking = false;

		@speechQueue = Hash.new() do |h, k|
			h[k] = Array.new();
		end

		@newMessageWaitpoint = Xasin::Waitpoint.new();

		@mqtt.subscribe_to "Room/#{@RoomName}/TTS" do |data|
			h = JSON.parse(data, symbolize_names: true);
			process_message(h);
		end

		@mqtt.subscribe_to "Room/#{@RoomName}/Lights/Set/Color" do |data|
			begin
				data = JSON.parse(data, symbolize_names: true);
			rescue
				@userColor = Color.from_s(data);
				update_current_color();
			else
				@userColor = Color.from_s(data[:color]);
				update_current_color(data[:speed]);
			end
		end

		@mqtt.subscribe_to "Room/#{@RoomName}/Lights/Set/Switch" do |data|
			@lightOn = (data == "on")
			update_current_color();
		end

		Thread.new() do
			while true do
				sleep 10
				update_current_color(10) unless (@skipUpdateColor or not(@lightOn))
				@skipUpdateColor = false;
			end
		end

		Thread.new do
			while(true) do
				speak_out_queue();
			end
		end.abort_on_exception = true;
	end

	def daylight_getter(&daylightCB)
		@daylightCB = daylightCB;
	end

	def get_recommended_color()
		if(@daylightCB) then
			begin
				daylightColor = @daylightCB.call
				return daylightColor if @userColor.black?
				return daylightColor.set_brightness(@userColor.get_brightness/255.0) if @userColor.white?
			rescue
			end
		end
		return @userColor;
	end

	def get_current_color()
		return Color.RGB(0, 0, 0) unless @lightOn;
		return get_recommended_color();
	end

	def update_current_color(fadeSpeed = 3)
		@skipUpdateColor = true;
		rColor = get_current_color();

		@mqtt.publish_to "Room/#{@RoomName}/Lights/Color",  @userColor.to_s, retain: true, qos: 1;
		@mqtt.publish_to "Room/#{@RoomName}/Lights/Switch", @lightOn ? "on" : "off", retain: true, qos: 1;
		@led.sendRGB(rColor, fadeSpeed) unless @speaking;
	end

	def process_message(h)
		begin
			h[:color] = h.key?(:color) ? Color.from_s(h[:color]) : nil;
		rescue
			h[:color] = nil;
		end
		queue_message(h[:gid] || "default", h);

		return true;
	end

	def queue_message(id, data)
		@speechQueue[id].clear if(data[:single]);

		@speechQueue[id].push(data);

		@newMessageWaitpoint.fire();
	end

	def speak_out_queue()
		@newMessageWaitpoint.wait();

		until @speechQueue.empty?
			k = @speechQueue.keys[0];
			v = @speechQueue[k];
			while h = v.shift
				next unless h.has_key? :text
				h[:text].gsub!(/[^\w\s\.,-:+']/, " ");

				@speaking = true;
					@mqtt.publish_to "Room/#{@RoomName}/Info/Current", h.to_json, retain: true;

					speechBrightness = [get_recommended_color().get_brightness, 10].max();
					@led.sendRGB(h[:color] ? h[:color].set_brightness(speechBrightness) : get_current_color, 0.5);
					system('pico2wave -w=speech.wav "' + h[:text] + ' 2>/dev/null && aplay >/dev/null 2>&1 speech.wav')
					#system('espeak -s 140 -g 3 -a 200 "' + h[:text] + '" --stdout 2>/dev/null | aplay >/dev/null 2>&1');
				@speaking = false;
			end

			@speechQueue.delete k;
		end

		@mqtt.publish_to "Room/#{@RoomName}/Info/Current", nil, retain: true;
		update_current_color(0.5);
	end
end

class Client
	def initialize(mqtt, topic, roomName = "default")
		@mqtt = mqtt;

		@RoomName = roomName;

		@topic = topic;
	end

	def speak(t, c = nil, **outData)
		outData[:text] = t;
		outData[:gid]	= @topic;

		outData[:color] 	= c.to_s 	if c;

		@mqtt.publish_to "Room/#{@RoomName}/TTS", outData.to_json;
	end
	alias notify speak
end
end

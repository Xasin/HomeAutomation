
require_relative '../Libs/ColorUtils.rb'
require_relative 'TWILight.rb'

require 'json'

module Hardware
	class Lights
		def initialize(mqtt, light, room: "default", infoFadeTime: 0.5)
			@mqtt  = mqtt;
			@roomName = room;

			@light = light;

			@currentColor = Color.RGB(0, 0, 0);
			@fadeTime = 10;
			@infoFadeTime = infoFadeTime;

			@fadeUntil = Time.new(0);

			@currentOverride = nil;
			@notificationBrightness = 100;

			@mqtt.track "Room/#{@roomName}/Peripherals/Light" do |data|
				begin
					data = JSON.parse(data);

					@fadeSpeed = data["fadeSpeed"].to_i or @fadeSpeed;

					if(@data["skip"]) then
						@fadeUntil = [@fadeUntil, Time.now() + @fadeTime].min;
					else
						@fadeUntil = Time.now() + @fadeTime;
					end

					@currentColor = Color.from_s(data["color"]);

					update_color() unless @currentOverride;
 				end
			end

			@roomBrightness = @mqtt.track "Room/#{@roomName}/Sensors/Brightness"

			@mqtt.track "Room/#{@roomName}/Notify/Current" do |data|
				begin
					data = JSON.parse(data);
					cO = Color.from_s(data["color"]);

					cO.set_brightness
						[5,
						 @roomBrightness.value.to_i * 2.5,
						 @currentColor.get_brightness].max

					@currentOverride = cO;
				rescue
					@currentOverride = nil;
				end

				@fadeUntil = Time.now() + @infoFadeTime;
				update_color();
			end
		end

		def update_color()
			@light.sendRGB([@currentOverride, @currentColor].compact[0],
				@fadeUntil - Time.now());
		end
	end
end

require 'i2c'
require_relative '../Libs/ColorUtils.rb'

module Hardware
	class RGB
		def initialize(twiClass)
			@twi ||= I2C.create("/dev/i2c-1");
			@conAttempts = 0;

			@lastColor = "";
		end

		def sendRGB(c, fadeDuration = 0)
			return if @lastColor = c.to_s;
			@lastColor = c.to_s;

			fadeDuration *= 104.167;
			begin
				@twi.write(0x30, c.rgb.pack("C3"), [fadeDuration].pack("v"));
			rescue Errno::EIO, Errno::ETIMEDOUT
				@conAttempts += 1;
				if @conAttempts == 5 then
					puts "A TWI packet has been lost!"
					@conAttempts = 0
				else
					sleep 0.5
					retry
				end
			else
			@conAttempts = 0
			end
		end
	end
end

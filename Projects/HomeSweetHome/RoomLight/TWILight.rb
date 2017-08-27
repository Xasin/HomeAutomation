require 'i2c'
require_relative '../Libs/ColorUtils.rb'

class RGB 
	def initialize()
		@twi = I2C.create("/dev/i2c-1");
		@conAttempts = 0;
	end

	def sendRGB(c, fadeDuration = 0)
		fadeDuration /= 0.05;
		begin
		@twi.write(0x30, c.rgb.pack("C3"), [fadeDuration].pack("v"));
		rescue Errno::EIO
		@conAttempts += 1;
		if @conAttempts == 5 then
			puts "A TWI packet has been lost!"
			@conAttempts = 0
		else
			sleep 0.1
			retry
		end
		else
		@conAttempts = 0
		end
	end
end

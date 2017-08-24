require 'i2c'
require_relative '../Libs/ColorUtils.rb'

class RGB 
	def initialize()
		@twi = I2C.create("/dev/i2c-1");
	end

	def sendRGB(c, fadeDuration = 0)
		fadeDuration /= 0.05;
		@twi.write(0x30, c.rgb.pack("C3"), [fadeDuration].pack("v"));
	end
end

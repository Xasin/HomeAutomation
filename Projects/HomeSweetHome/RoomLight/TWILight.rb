require 'i2c'
require_relative '../Libs/ColorUtil.rb'

class RGB 
	def initialize()
		@twi = I2C.create("/dev/i2c-1");
	end

	def sendRGB(c, fadeDuration = 0)
		@twi.write(0x30, c.rgb.pack("C3"), [fadeDuration].pack("v"));
	end
end

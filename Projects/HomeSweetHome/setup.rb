#!/usr/bin/ruby2.4.1

at_exit {
	sleep 3*69 unless $updateSignalSent
 	exec("git pull; ruby setup.rb")
}

`echo #{ $$ } > /tmp/ColorSpeak.pid`

Thread.abort_on_exception = true;

require_relative 'Libs/CoreExtensions.rb'

require 'mqtt/sub_handler'
require 'mqtt/sub_testing'

require 'xasin/telegram/SingleUser.rb'
require 'xasin/telegram/MQTT_Adapter.rb'

require_relative 'mqttSignIn.rb'

$eclipse = MQTT.Eclipse();

require_relative 'RoomLight/TWILight.rb'
require_relative 'RoomLight/ColorSpeak.rb'
$twi = I2C.create("/dev/i2c-1");
$led = RGB.new($twi);

$cSpeak = ColorSpeak::Server.new($led, $mqtt);
puts "ColorSpeak loaded!"

require_relative 'Convenience/Room.rb'
require_relative 'Convenience/User.rb'
$room  = Convenience::Room.new($mqtt, "default");
$xasin = Convenience::User.new($mqtt, "Xasin");
puts "Convenience interfaces loaded."

require_relative 'Hooks/MDistHook.rb'
puts "Message distribution online!"

require_relative 'Libs/PS2Client.rb'
$planetside = Planetside2::Client.new("XasinsIoTPlanetside");
puts "Planetside loaded!"

print "Hooks loaded: "
require_relative 'Hooks/PrinterHooks.rb'
print "Printer, "
require_relative 'Hooks/WakeupHook.rb'
print "Alarm Clock, "
require_relative "Hooks/SwitchHooks.rb"
print "Switch status, "
require_relative "Hooks/LightHooks.rb"
print "Light controls, "
require_relative "Hooks/WelcomeBack.rb"
print "Welcome Back, "
require_relative "Hooks/ClimateHook.rb"
print "Environmental controls, "
require_relative "Hooks/GoodMessages.rb"
print "Positivity boosters, "
require_relative "Hooks/ClockHook.rb"
print "Clock connection, "
require_relative "Hooks/WorkHook.rb"
print "Work counter, "
require_relative "Hooks/PokeLukas.rb"
print "Lukas-Poker, "
require_relative "Hooks/TeaTime.rb"
print "Tea timer, "
require_relative "Hooks/TapHook.rb"
print "Tap integration."

puts "\nPID of this process: #{Process.pid}"

Signal.trap("SIGHUP") {
  $updateSignalSent = true;
  exit
}
$telegram.on_message do |message|
	if message[:text] =~ /\/restart/ then
		puts "RESTART ISSUED FROM TELEGRAM!"
		$updateSignalSent = true;
		exit
	end
end

puts ""
$mqtt.lockAndListen();

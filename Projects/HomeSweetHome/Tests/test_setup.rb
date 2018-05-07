
require 'mqtt/sub_handler'
$mqtt ||= MQTT::SubHandler.new("mqtts://Xasin:ChocolateThings@xasin.hopto.org")

require_relative "../Convenience/Room.rb"
require_relative "../Convenience/User.rb"

$xasin ||= Convenience::User.new($mqtt, "Xasin");
$room  ||= Convenience::Room.new($mqtt, "default");

sleep 1

preTestSwitch = $xasin.switch;
preTestHome   = $xasin.home?;
preTestColor  = $room.lightColor
preTestLightSwitch = $room.lightSwitch

at_exit {
	$xasin.switch = preTestSwitch;
	$xasin.home   = preTestHome;
	$room.lights  = preTestColor;
	$room.lights  = preTestLightSwitch;
}

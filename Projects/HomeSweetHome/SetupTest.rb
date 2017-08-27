
require_relative 'RoomLight/ColorSpeak.rb'
require_relative 'Libs/MQTTSubscriber.rb'

$mqtt = MQTTSubs.new(MQTT::Client.new("mqtts://Internal:Internal@192.168.178.111"));

$ts = ColorSpeak::Client.new($mqtt, "Test");

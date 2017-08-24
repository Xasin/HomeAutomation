require_relative 'ColorSpeak.rb'
require_relative 'Libs/MQTTSubscriber.rb'
require_relative 'RoomLight/TWILight.rb'

$led = RGB.new();
$mqtt = MQTTSubs.new(MQTT::Client.new("mqtts://Internal:Internal@192.168.178.111"));

$cSpeak = ColorSpeak.new($led, $mqtt);

$cSpeak.queueWords("Test", "What is love", Color.RGB(255, 0, 255));

sleep 10;

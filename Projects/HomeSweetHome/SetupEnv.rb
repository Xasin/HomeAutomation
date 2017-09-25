
require_relative 'RoomLight/ColorSpeak.rb'
require_relative 'Libs/MQTTSubscriber.rb'
require_relative 'Libs/CoreExtensions.rb'

login = File.read(File.expand_path("~/.HoT/logins/snippet.login")).strip!

$mqtt = MQTTSubs.new(MQTT::Client.new(login));
sleep 1;
$ts = ColorSpeak::Client.new($mqtt, "Test");

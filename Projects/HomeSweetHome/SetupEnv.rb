
require_relative 'RoomLight/ColorSpeak.rb'
require_relative 'Libs/MQTTSubscriber.rb'
require_relative 'Libs/CoreExtensions.rb'

login ||= File.read(File.expand_path("~/.HoT/logins/snippet.login")).strip!

$mqtt ||= MQTT::SubHandler.new(login);
sleep 1;
$testSpeak = ColorSpeak::Client.new($mqtt, "Test");


require 'mqtt/sub_handler'
require 'pocketsphinx-ruby'

require_relative 'NumberDecoder.rb'
require_relative 'VoiceControl.rb'

require_relative 'Libs/ColorUtils.rb'

require_relative 'Convenience/User.rb'
require_relative 'Convenience/Room.rb'

$mqtt = MQTT::SubHandler.new("== REDACTED ==");

cfg = Pocketsphinx::Configuration::Grammar.new("Control.JSGF");
cfg['logfn'] = "/dev/null";
rec = Pocketsphinx::LiveSpeechRecognizer.new(cfg);

$xasin = Convenience::User.new($mqtt, "Xasin");
$room  = Convenience::Room.new($mqtt, "default");

$processor = VoiceControl::Processor.new($mqtt, $xasin);

require_relative 'VoyagerSounds.rb'
$player = StarTrek::VojagerSounds.new();

$processor.add_sentences 'Controls/LightControls.rb';
$processor.add_sentences 'Controls/Miscellanous.rb';

puts "Systems loaded, beginning to listen ..."
rec.recognize do |words|
	$processor.process words;
end

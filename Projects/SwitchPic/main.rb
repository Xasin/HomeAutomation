
require_relative 'MQTTSubscriber'
require 'sinatra'

require_relative "credentials.rb"

set :port, 80
set :bind, "0.0.0.0"

$xaQTT = MQTTSubs.new(MQTT::Client.new($mqtt_host));

$currentMember = Hash.new() do |h, k| $h[k] = "none"; end
$memberColors = {
	"Xasin"	=> "red",
	"Neira"	=> "blue",
	"Mesh"	=>	"brightgreen",
}

$xaQTT.subscribeTo "personal/switching/+/who" do |topic, payload|
	return if payload == "none";
	sysName = topic[0];
	$currentMember[sysName] = payload;
end

before do
  cache_control :no_cache, :must_revalidate
end

get "/switchPics/Xasin.jpg" do
	mName = $currentMember["Xasin"];
	etag mName
	send_file "Pics/#{mName}.jpg", :last_modified=>Time.now().to_i, :filename => "#{mName}.jpg", :type => :jpg, :disposition => :inline;
end

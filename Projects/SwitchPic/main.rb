require_relative "credentials.rb"

require_relative 'MQTTSubscriber'
$xaQTT = MQTT::SubHandler.new $mqtt_host

require 'sinatra'

set :port, 80
set :bind, "0.0.0.0"

$currentMember = Hash.new() do |h, k| h[k] = "none"; end
$memberColors = {
	"Xasin"	=> "red",
	"Neira"	=> "blue",
	"Mesh"	=> "brightgreen",
}

$xaQTT.subscribeTo "Personal/+/Switching/Who" do |topic, payload|
	unless payload == "none" then
	sysName = topic[0];
	$currentMember[sysName] = payload;
	end
end

before do
  cache_control :no_cache, :must_revalidate
end

get "/switchPics/Xasin.jpg" do
	mName = $currentMember["Xasin"];
	etag mName
	send_file "Pics/#{mName}.jpg", :last_modified=>Time.now().to_i, :filename => "#{mName}.jpg", :type => :jpg, :disposition => :inline;
end

post "/gitAPI/ColorSpeakUpdate" do
	puts "Params: #{params}"

	begin
		if(params[:repository][:full_name] == "Xasin/HomeAutomation") then

			Process.kill("HUP", `cat /tmp/ColorSpeak.pid`);

		end
	rescue
	end

	true
end

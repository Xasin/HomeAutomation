
sentence /(red|green|blue) switched in/ do |match|
	$xasin.switch = {"red" => "Xasin", "green" => "Mesh", "blue" => "Neira"}[match[1]];
end

sentence "computer good night and sweet dreams" do
	$room.command "gn"
end

sentence "computer i am back home" do
	$xasin.home = true;
end
sentence "computer i am leaving now" do
	$xasin.home = false;
end

sentence "computer how are you doing" do
	$xasin.notify "I am doing quite well, thank you for asking."
end

sentence /(red|blue|stand down) alert/ do |match|
	$player.alert = match[1];
end


sentence /(red|green|blue) switched in/ do |match|
	$xasin.switch = {"red" => "Xasin", "green" => "Mesh", "blue" => "Neira"}[match[1]];
end

sentence "computer good night and sweet dreams" do
	$xasin.switch = "none";
	$room.lights  = false;
end

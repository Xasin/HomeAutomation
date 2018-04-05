
sentence /turn (on|off) the light/ do |match|
	$xasin.notify "Turning #{match[1]} the light!";
	$room.lights = (match[1] == "on");
end

sentence /light temperature to (\d+)(?: brightness (0\.\d+))?/ do |match|
	$xasin.notify "Light temperature set to #{match[1]}K"
	b = 1;
	if match[2] then
		b = match[2].to_f;
	end
	$room.lights = Color.temperature(match[1].to_i, b).to_s;
end

sentence /light to daylight/ do
	$xasin.notify "Lights have been set to daylight."
	$room.lights = "#000000";
end

sentence /light color to((?: (?:\d\.\d+|1) (?:red|green|blue)){1,3})/ do |match|
	colors = [];
	["red","green","blue"].each do |c|
		if colorMatch = (/(\d\.\d+|1) #{c}/.match match[1]) then
			colors << colorMatch[1].to_f * 255;
		else
			colors << 0;
		end
	end

	colors = Color.new(colors).to_s;
	$xasin.notify "Setting up lights to #{colors}!"
	$room.lights = colors;
end

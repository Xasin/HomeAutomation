
ledColors = {};
bufferColors = {};
for i = 1,8 do
	ledColors[i] = {0, 0, 0};
end
for i= 1,3*8 do
	bufferColors[i] = 0;
end

function updateLEDs()
	j = 0;
	im = 0;
	for i=1,8 do
		j = 0;
		im = i*3;
		while(j<3) do
			j = j+1;
			bufferColors[im + j - 3] = math.floor(((ledColors[i][j])^2) /260);
		end
	end

	gpio.write(4, gpio.HIGH);
	tmr.delay(50);
	gpio.write(4, gpio.LOW);
	tmr.delay(50);
	spi.send(1, bufferColors, 0);

end

function tocolor(hexCode)
	print("Converting color: " .. hexCode);

	outputArray = {};
	for i=2,6,2 do
		table.insert(outputArray, tonumber(string.sub(hexCode, i, i+1), 16) or 0);
	end

	return outputArray;
end


function HSVtoRGB(angle, outputColor, brightness)
	if(brightness == nil) then brightness = 1; end

	while(true) do
		if(angle < 0) then angle = angle + 360;
		elseif(angle > 360) then angle = angle - 360;
		else break; end
	end

	i = 1 + math.floor(angle/120);
	if(angle%120 < 60) then
		outputColor[i] 		= brightness*255;
		outputColor[i%3 + 1]	= brightness*255 * (angle%60)/60;
		outputColor[(i + 1)%3 + 1] = 0;
	else
		outputColor[i%3 + 1] = brightness*255;
		outputColor[i] 		= brightness*255 * (1 - (angle%60)/60);
		outputColor[(i + 1)%3 + 1] = 0;
	end
end

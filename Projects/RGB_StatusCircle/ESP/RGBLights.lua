
ledColors = {};
for i = 1,16*3 do
	ledColors[i] = 0;
end

function updateLEDs()
	i2c.start(0);
	i2c.address(0, 0x01, i2c.TRANSMITTER);
	i2c.write(0, 2, ledColors);
	i2c.stop(0);
end

function tocolor(hexCode)
	print("Converting color: " .. hexCode);

	outputArray = {};
	for i=2,6,2 do
		table.insert(outputArray, tonumber(string.sub(hexCode, i, i+1), 16) or 0);
	end

	return outputArray;
end


function setLED_HSV(ledID, angle, brightness)
	if(brightness == nil) then brightness = 1; end

	while(true) do
		if(angle < 0) then angle = angle + 360;
		elseif(angle > 360) then angle = angle - 360;
		else break; end
	end

	ledID = (ledID -1)*3;
	i = 1 + math.floor(angle/120);
	if(angle%120 < 60) then
		ledColors[ledID + i] 					= brightness*255;
		ledColors[ledID + i%3 + 1]				= brightness*255 * (angle%60)/60;
		ledColors[ledID + (i + 1)%3 + 1] 	= 0;
	else
		ledColors[ledID + i%3 + 1] 			= brightness*255;
		ledColors[ledID + i] 					= brightness*255 * (1 - (angle%60)/60);
		ledColors[ledID + (i + 1)%3 + 1] 	= 0;
	end
end

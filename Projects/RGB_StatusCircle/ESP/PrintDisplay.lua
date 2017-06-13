printProgress = 0;
printHue = 120;

ledBrightnesses = {0, 0, 0, 0, 0, 0, 0, 0};

function bWave(phase)
	phase = (phase*3)%3;
	if(phase > 1) then return 0; end
	return 1 - phase;
end

function updateLights()
	if(printProgress >= 99) then
		tBrightness = 0.5 + 0.5*math.abs(((playTime/1000000)%2 - 1));
		for i=1,8 do
			ledBrightnesses[i] = tBrightness;
		end
	elseif(printProgress == 0) then
		for i=1,8*3 do
			ledColors[i] = 0;
			printTrack.duration = 0;
			return;
		end
	else
		for i=1,8 do
			ledBrightnesses[i] = bWave(playTime/10000000 - i/(8*2));
		end
	end

	pwrPerLed = 1;
	leftPwr 	 = 0.08*printProgress;
	for i=1,8 do
		if(pwrPerLed < leftPwr) then
			setLED_HSV(i, printHue, (ledBrightnesses[i]*0.7 + 0.3));
			leftPwr = leftPwr - pwrPerLed;
		elseif(leftPwr ~= 0) then
			setLED_HSV(i, printHue, leftPwr * (ledBrightnesses[i]*0.7 + 0.3));
			leftPwr = 0;
		else
			setLED_HSV(i, 0, ledBrightnesses[i]*0.5 + 0.1);
		end
	end

	if(printProgress == 0) then
	end
end
printTrack = addLightEffect(true, 10000000, updateLights);
printTrack.interruptable = true;

subscribeTo("octoprint/progress/printing", 0, function(tList, data)
	data = sjson.decode(data);

	print("Received progress: " .. data["progress"] .. "%");
	printProgress = data["progress"];

	printTrack.duration = 10000000;
end);



printProgress = 0;
printHue = 120;

fancyTimer = tmr.create();

ledBrightnesses = {0, 0, 0, 0, 0, 0, 0, 0};

function bWave(phase)
	phase = (phase*3)%3;
	if(phase > 1) then return 0; end
	return 1 - phase;
end

function updateLights()
	if(printProgress >= 99) then
		tBrightness = 0.5 + 0.5*math.abs(((tmr.now()/1000000)%2 - 1));
		for i=1,8 do
			ledBrightnesses[i] = tBrightness;
		end
	else
		for i=1,8 do
			ledBrightnesses[i] = bWave(tmr.now()/10000000 - i/(8*2));
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

	updateLEDs();
end
fancyTimer:register(100, tmr.ALARM_AUTO, updateLights);

subscribeTo("octoprint/progress/printing", 0, function(tList, data)
	data = sjson.decode(data);

	print("Received progress: " .. data["progress"] .. "%");
	printProgress = data["progress"];

	if(printProgress ~= 0) then
		fancyTimer:start();
	else
		fancyTimer:stop();
		updateLights();
	end
end);

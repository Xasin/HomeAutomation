

printProgress = 0;
printHue = 120;

fancyTimer = tmr.create();

function updateLights()

	ledBrightnesses = {0, 0, 0, 0, 0, 0, 0, 0};

	if(printProgress >= 99) then
		tBrightness = 0.5 + 0.5*math.abs(((tmr.now()/1000000)%2 - 1));
		for i=1,8 do
			ledBrightnesses[i] = tBrightness;
		end
	else
		for i=1,8 do
			ledBrightnesses[i] = math.max(2 * math.abs(((i/5 - tmr.now()/10000000))%1 *2 - 1) - 1, 0.3);
		end
	end

	pwrPerLed = 1;
	leftPwr 	 = 0.08*printProgress;
	for i=1,8 do
		if(pwrPerLed < leftPwr) then
			HSVtoRGB(printHue, ledColors[i], ledBrightnesses[i]);
			leftPwr = leftPwr - pwrPerLed;
		elseif(leftPwr ~= 0) then
			HSVtoRGB(printHue, ledColors[i], leftPwr * ledBrightnesses[i]);
			leftPwr = 0;
		else
			for j=1,3 do
				ledColors[i][j] = ledBrightnesses[i] * 100;
			end
		end
	end

	updateLEDs();
end
fancyTimer:register(250, tmr.ALARM_AUTO, updateLights);

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

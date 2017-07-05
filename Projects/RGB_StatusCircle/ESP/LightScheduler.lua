
trackList 		= {};
currentTrack 	= nil;
trackStart		= 0;

lightTimer = tmr.create();

playTime 		= 0;
function selectNewTrack()
	if(#trackList == 0) then
		currentTrack = nil;
		return;
	end

	currentTrack = table.remove(trackList);

	if(currentTrack.shouldRepeat) then
		table.insert(trackList, 1, currentTrack);
	end

	trackStart = -1;
end

function LSUpdate()
	if(trackStart < 0) then
		trackStart = tmr.now();
		playTime = 0;
	else
		playTime = tmr.now() - trackStart;
	end

	if(playTime < currentTrack.duration) then
		currentTrack.play();
		updateLEDs();
	else
		selectNewTrack();
		if(currentTrack == nil) then
			lightTimer:stop();
		end
		for i=1,8*3 do
			ledColors[i] = 0;
		end
		updateLEDs();
	end
end
lightTimer:register(75, tmr.ALARM_AUTO, LSUpdate);

function addLightEffect(shouldRepeat, duration, cbFunction)
	newTrack = {};
	newTrack.shouldRepeat = shouldRepeat;
	newTrack.duration = duration;
	newTrack.play = cbFunction;

	if(not shouldRepeat) then
		table.insert(trackList, newTrack);
	else
		table.insert(trackList, 1, newTrack);
	end

	if((not currentTrack) or (currentTrack.interruptable)) then
		selectNewTrack();
		lightTimer:start();
	end

	return newTrack;
end

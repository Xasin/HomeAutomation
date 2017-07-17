
sublist = {};

homeQTT = mqtt.Client("NodeCute", "Internal", "internal", 30);

connectedServices = {};

function mqttReconnected(mClient)
	print("MQTT connection established!");
	connectedServices.mqtt = true;

	for k, v in pairs(sublist) do
		homeQTT:subscribe(k, v.qos);
	end
end
function wifiReconnected(wifiTable)
	print("WiFi connection established!");
	connectedServices.wifi = true;

	homeQTT:connect("192.168.178.111", 1883, 0, mqttReconnected, function(client, reason) print(reason); end);
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifiReconnected);
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(wifiTable) if(connectedServices.wifi) then print("Wifi connection lost! Reconnect (probably) automatic..."); end connectedServices.wifi = nil; end);

homeQTT:on("offline", function(client) print("MQTT connection lost! :c"); connectedServices.mqtt = nil; end);

dofile "MQTTInit.lua"
dofile "RGBLights.lua"

i2c.setup(0, 1, 2, 400000);


tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()
	dofile "LightScheduler.lua"

	dofile "PrintDisplay.lua"
	dofile "Temp.lua"

	switchHues = {
		["Xasin"] 	= 0,
		["Mesh"]	= 130,
		["Neira"]	= 234
	};
	currentMember 	= "Xasin";
	oldMember		= "Xasin";
	switchDispPercent = 0;
	function displaySwitch()
		switchDispPercent = 6*playTime/3000000 - 1;
		for i=1,4 do
			if(i<switchDispPercent) then
				setLED_HSV(i, switchHues[currentMember], 1);
				setLED_HSV(9 - i, switchHues[currentMember], 1);
			else
				setLED_HSV(i, switchHues[oldMember], 1);
				setLED_HSV(9 - i, switchHues[oldMember], 1);
			end
		end
	end

	subscribeTo("personal/switching/Xasin/who", 1, function(tList, payload)
		if(payload ~= currentMember) then
			oldMember = currentMember;
			currentMember = payload;
			addLightEffect(false, 3000000, displaySwitch);
		end
	end)
end);

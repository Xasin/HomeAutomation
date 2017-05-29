
sublist = {};

homeQTT = mqtt.Client("NodeCute", 30);

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

	homeQTT:connect("192.168.178.111", 1883, 0, mqttReconnected);
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifiReconnected);
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(wifiTable) if(connectedServices.wifi) then print("Wifi connection lost! Reconnect (probably) automatic..."); end connectedServices.wifi = nil; end);

homeQTT:on("offline", function(client) print("MQTT connection lost! :c"); connectedServices.mqtt = nil; end);

dofile "MQTTInit.lua"
dofile "RGBLights.lua"

gpio.mode(4, gpio.OUTPUT);
gpio.write(4, gpio.HIGH);
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_HIGH, 8, 800);
gpio.mode(8, gpio.INPUT, gpio.PULLUP)

tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()
	dofile "PrintDisplay.lua"
end);

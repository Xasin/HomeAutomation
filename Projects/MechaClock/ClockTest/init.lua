
dofile("MQTTConnect.lua");

tmr.create():alarm(3000, tmr.ALARM_SINGLE,
	function(t)
		sntp.sync(nil, nil, nil, true);

		i2c.setup(0, 1, 2, i2c.SLOW);

		function setClock(num)
			i2c.start(0);
			i2c.address(0, 0x31, i2c.TRANSMITTER);

			if(num == -1) then
				i2c.write(0, 255, 255);
			else
				i2c.write(0, num%256, math.floor(num/256));
			end
			i2c.stop(0);
		end

		tmr.create():alarm(1000, tmr.ALARM_AUTO,
			function(t)
				local sec, usec, rate = rtctime.get();

				sec = sec - 1526594400;
				sec = sec / 60;

				if(xasinAwake) then
					setClock(math.floor(sec/60)%24 * 100 + (sec%60));
				else
					setClock(-1);
				end
			end);

		onMQTTConnect(function()
			print("MQTT Connected!");

			subscribeTo("Personal/Xasin/Switching/Who", 0, function(data)
				print("Got switch data: " .. data);
				xasinAwake = not (data == "none");
			end);
		end);
	end)

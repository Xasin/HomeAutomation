

mesTimer 	= tmr.create();
readTimer 	= tmr.create();

relHumidity = 0;
temperature = 0;

function startRHTMeasurement()
	i2c.start(0);
	i2c.address(0, 0x40, i2c.TRANSMITTER);
	i2c.write(0, 0xF5);
	i2c.stop(0);

	readTimer:start();
end

function readOutRHT()
	i2c.start(0);
	i2c.address(0, 0x40, i2c.RECEIVER);
	relHumidity = i2c.read(0, 2);
	i2c.start(0);
	i2c.address(0, 0x40, i2c.TRANSMITTER);
	i2c.write(0, 0xE0);
	i2c.start(0);
	i2c.address(0, 0x40, i2c.RECEIVER);
	temperature = i2c.read(0, 2);
	i2c.stop(0);


	relHumidity = string.byte(relHumidity, 1) * 256 + string.byte(relHumidity, 2);
	temperature = string.byte(temperature, 1) * 256 + string.byte(temperature, 2);

	relHumidity = (125*relHumidity) / 65536 - 6;
	temperature = (175.72*temperature) / 65536 - 46.85;

	homeQTT:publish("sensoring/temperature", temperature, 1, 0);
	homeQTT:publish("sensoring/humidity", relHumidity, 1, 0);
end

readTimer:register(100, tmr.ALARM_SEMI, readOutRHT);
mesTimer:alarm(2000, tmr.ALARM_AUTO, startRHTMeasurement);

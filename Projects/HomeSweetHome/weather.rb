
require_relative 'Libs/CoreExtensions.rb'
require_relative 'Libs/ColorUtils.rb'
require 'json'
require 'mqtt'

require_relative 'SetupEnv.rb'

$ttsTopic = "Room/TTS/Weather";

class WeatherInfo
	attr_reader :city

	def initialize(apikey, city)
		@apikey = apikey;
		@city = city;

		@lastUpdatedCF = Time.now - 10*60;
		@lastUpdatedFDF = Time.now - 10*60;
	end

	def current_data
		return @currentForecast unless (@lastUpdatedCF < Time.now() - 10*60);

		@lastUpdatedCF = Time.now();
		return @currentForecast = JSON.parse(`wget -q -O - "api.openweathermap.org/data/2.5/weather?q=#{@city}&units=metric&appid=#{@apikey}"`);
	end

	def fiveday_data
		return @fivedayForecast unless (@lastUpdatedFDF < Time.now() - 10*60);

		@lastUpdatedFDF = Time.now();
		return @fivedayForecast = JSON.parse(`wget -q -O - "api.openweathermap.org/data/2.5/forecast?q=#{@city}&units=metric&appid=#{@apikey}"`);
	end

	def format_weather(wData, future: false, noprefix: false)
		prefix = "";

		unless noprefix then
			prefix = "there";
			unless future
				prefix += " is";
			else
				prefix += " will be";
			end
		end

		prefix += " a" if(wData["main"] == "Thunderstorm");
		prefix += " a" if(wData["main"] == "Drizze");
		prefix += " a" if(wData["main"] == "Clear");
		prefix += " a" if(wData["main"] == "Additional");

		prefix  = "there are" if(wData["main"] == "Clouds" and not future);

		return "#{prefix} #{wData["description"]}";
	end

	def readable_current
		return format_weather(current_data["weather"][0]);
	end

	def format_time(t, forceDay: true, preciseTime: true)
		dayBegin  = Time.today();
		cTimeA 	 = Time.now.to_a
		cTimeA[0] = 59; cTimeA[1] = 59; cTimeA[2] = 23;
		dayEnd    = Time.local(*cTimeA);

		dayPrefix = t.strftime("on %A") if t.between?(dayBegin, dayBegin + 7*24*60*60);

		dayPrefix = "yesterday" if t.between?(dayBegin - 60*60*24, dayBegin);
		dayPrefix = "today" if t.between?(dayBegin, dayEnd);
		dayPrefix = "tomorrow" if t.between?(dayEnd, dayEnd + 60*60*24);

		bufDayPrefix = dayPrefix;
		unless forceDay
			dayPrefix = "" if @lastDayPrefix == dayPrefix;
		end
		@lastDayPrefix = bufDayPrefix;

		time = t.strftime "at %k o clock";

		unless preciseTime then
			h = t.hour;
			time = "in the morning" 		if h.between?(7,  10);
			time = "around noon" 			if h.between?(11, 13);
			time = "in the afternoon" 		if h.between?(15, 16);
			time = "at tea time"				if h == 17;
			time = "in the evening" 		if h.between?(18, 20);
		end

		return "#{dayPrefix} #{time}"
	end

	def forecast_for(t)
		t = t.to_i;
		fiveday_data()["list"].each do |f|
			return f if (f["dt"] - t).abs < 1.5*60*60
		end

		return nil;
	end

	def readable_forecast(fCast, forceDay: true, noprefix: false, temperature: false)
		answer = "#{format_time(Time.at(fCast["dt"].to_i), forceDay: forceDay, preciseTime: false)}, #{format_weather(fCast["weather"][0], future: true, noprefix: noprefix)}"
		if(temperature) then
			answer += " at #{fCast["main"]["temp"].round(1)} degrees";
		end

		return answer;
	end

	def readable_forecast_for(t, forceDay: true, temperature: true)
		if t.is_a? Array then
			answer = "";

			t.each do |i|
				answer += readable_forecast_for(i, forceDay: forceDay, temperature: temperature) + ", ";
				forceDay = false;
			end

			return answer;
		else
			fCast = forecast_for(t);
			return "No forecast for #{t}!" if fCast == nil;
			return readable_forecast(fCast, temperature: temperature, forceDay: forceDay);
		end
	end
end

def speak(t, color = nil)
	$mqtt.connect do |c|
		c.publish $ttsTopic, {text: t, color: color.to_s}.to_json;
	end
end

def isInteresting(t)
	h = Time.at(t).hour;
	return true if h.between?(7, 22);
	return false;
end

$w = WeatherInfo.new($privateData["apikey"], "Steinfeld");
i = 0;
$w.fiveday_data()["list"].each do |d|
	if isInteresting(d["dt"].to_i) then
		speak($w.readable_forecast(d, temperature: true, forceDay: i==0), Color.HSV(120 - 100*(d["main"]["temp"].to_i - 17)/5));
		i += 1;
	end
	break if i >= 5;
end

require 'json'

module Hooks
module Printer

@printerData = {
	status: :idle,
	lastProgress: 2,
}
@printTTS = Messaging::UserClient.new($mqtt, "Xasin", "Printer");

$mqtt.subscribe_to "octoprint/event/PrintStarted" do
	@printTTS.speak("Print started.", Color.RGB(0, 255, 200));
	@printerData[:status] = :bed_check;
	@printerData[:lastProgress] = 0;
end

$mqtt.subscribe_to "octoprint/progress/printing" do |data|
	printProgress = JSON.parse(data)

	if (printProgress["progress"] >= 98) and (@printerData[:status] == :printing)
		@printTTS.speak("The print is almost complete.", Color.RGB(0, 255, 0));
		@printerData[:status] = :idle;
	end

	@printerData[:lastProgress] = printProgress["progress"];
end

$mqtt.subscribe_to "octoprint/temperature/+" do |data, tool|
	tool = tool[0];
	data = JSON.parse(data);

	current 	= data["actual"].to_f;
	target 	= data["target"].to_f;

	@printerData[tool] = {
		actual: current,
		target: target,
	}

	tDiff = (current - target).abs;

	if tool == "bed" then
		if(@printerData[:status] == :bed_check) then
			if tDiff < 5
				@printerData[:status] = :tool0_check
			else
				@printerData[:status] = :bed_heatup;
			end
		elsif @printerData[:status] == :bed_heatup and tDiff < 2
			@printTTS.speak "The heatbed has reached temperature!", Color.RGB(255, 0, 50);
			@printerData[:status] = :tool0_check;
		end
	elsif tool == "tool0" and target > 170 then
		if @printerData[:status] == :tool0_check
			if tDiff < 5
				@printerData[:status] = :printing;
			else
				@printerData[:status] = :tool0_heatup;
			end
		elsif @printerData[:status] == :tool0_heatup and tDiff < 5
			@printTTS.speak "The extruder has reached temperature!", Color.RGB(255, 100, 0);
			@printerData[:status] = :printing;
		end
	end
end

$mqtt.subscribe_to "octoprint/event/MetadataAnalysisFinished" do |data|
	data 	= JSON.parse(data);
	pTime = data["result"]["estimatedPrintTime"].to_f

	h = (pTime / (60*60)).floor;
	m = (pTime / 60).floor % 60;

	hString = "#{h} hours and"
	hString = "" if h == 0
	hString = "1 hour and" if h == 1

	mString = "#{m} minutes";
	mString = "1 minute" if m == 1;

	@printTTS.speak "Analysis finished. The print will take #{hString} #{mString}.", Color.RGB(0, 150, 255);
end


end
end

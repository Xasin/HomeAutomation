
require 'haversine'

module Hooks
	module Work
		WORK_POSITION 	= [52.388586, 9.712669]
		LUNCH_POSITION = [52.386311, 9.713906]

		@workStatus  = :not_working
		@startedWork 		= Time.at(0);
		@startedBreak 		= Time.at(0);

		@totalBreakTime 	= 0;
		@totalWorkTime 	= 0;

		def self.set_work_status(newStatus, context: nil)
			case @workStatus
			when :not_working
				if(newStatus == :working)
					@totalWorkTime 	= 0;
					@totalBreakTime 	= 0;
					@startedWork 		= Time.now();
					@workStatus 		= :working;

					$xasin.notify "Alright, have fun at work!"
				end
			when :working
				if(newStatus == :not_working)
					@totalWorkTime = (Time.now() - @startedWork) - @totalBreakTime
					@totalWorkTime = (@totalWorkTime/10.minutes).ceil * 10.minutes

					@workStatus = :not_working

					@totalBreakTime = (@totalBreakTime/5.minutes).round * 5.minutes;
					breakString = "";
					if(@totalBreakTime > 0) then
						breakString = ", had #{@totalBreakTime} minutes of break"
					end

					$xasin.notify "Alright! You started at #{@startedWork.hour}:#{@startedWork.min}#{breakString}, sooo ...
That's *#{(@totalWorkTime/1.hours).round}:#{(@totalWorkTime/1.minutes).round % 60}* of work done!"
				elsif([:break, :lunch].include? newStatus)
					@startedBreak = Time.now();

					@workStatus = newStatus

					$xasin.notify "#{context == :autom ? "Have" : "Ok, have"} a nice #{newStatus}!";
				end
			when :break, :lunch
				if(newStatus == :working)
					@totalBreakTime += Time.now() - @startedBreak;
					@workStatus = :working;

					$xasin.notify "Back to work#{context == :autom ? "" : " indeed"}!"
				elsif(newStatus == :not_working)
					@totalBreakTime += Time.now() - @startedBreak;
					@workStatus = :working;

					set_work_status(:not_working);
				end
			end
		end

		$telegram.on_message do |data|
			data = data[:text].downcase

			case data
			when /(off|back) to work/
				set_work_status(:working);
			when /(finished|done with) work/
				set_work_status(:not_working)
			when /(lunch|break) time/, /time for (?:a )?(lunch|break)/
				set_work_status($1.to_sym)
			end
		end

		$mqtt.track "Personal/Xasin/Position" do |data|
			begin
				data = JSON.parse(data);

				@xasinPosition = [data["lat"], data["lon"]];
				@xasinAccuracy = data["acc"];

				lunchDistance = Haversine.distance(LUNCH_POSITION, @xasinPosition).to_m - @xasinAccuracy;

				nextLunchState = lunchDistance < (@xasinAtLunch ? 80 : 50);

				if(nextLunchState != @xasinAtLunch)
					@xasinAtLunch = nextLunchState;

					if(@workStatus == :working and @xasinAtLunch)
						set_work_status(:lunch, context: :autom);
					elsif(@workStatus == :lunch and not @xasinAtLunch)
						set_work_status(:working, context: :autom);
					end
				end
			rescue
			end
		end
	end
end

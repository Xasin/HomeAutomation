
module StarTrek
	class VojagerSounds
		AlertMap = {
			"blue" => {file: "Sounds/voy_bluealert.mp3", duration: 1.9},
			"red"  => {file: "Sounds/voy_redalert.mp3", duration: 2.5},
		}

		def initialize
			@playerThread = Thread.new {
				loop do
					Thread.stop unless (@killDuration and @repeat) until @killDuration;
					puts "Going into kill-wait ..."
					sleep @killDuration;

					next unless @killDuration;
					if(@repeat) then
						puts "Restarting player!"
						_start_player(@playedFilename);
					else
						puts "Stopping player!"
						_stop_player();
						@playedFilename = nil;
						@killDuration = nil;
					end
				end
			}
			@playerThread.abort_on_exception = true;
		end

		def _start_player(filename)
			_stop_player();
			@playerPID = fork {exec "mpg123 -q #{filename}"}
		end
		def _stop_player()
			Process.kill("INT", @playerPID) if @playerPID;
			@playerPID = nil;
		end

		def _reset_playerthread()
			@killDuration = nil;
			@playerThread.run
		end

		def play(file, repeat: true, killDuration: nil)
			_reset_playerthread();

			@playedFilename = file;
			_start_player(@playedFilename);
			@repeat = repeat;
			@killDuration = killDuration;

			@playerThread.run();
		end

		def stop
			return unless @playedFilename;

			@playedFilename = nil;
			@repeat = false;

			_reset_playerthread();
			_stop_player();
		end

		def alert=(val)
			if sound = AlertMap[val] then
				play(sound[:file], killDuration: sound[:duration]);
			else
				@repeat = false;
			end
		end
	end
end

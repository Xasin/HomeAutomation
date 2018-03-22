
module VoiceControl
	class Processor
		def initialize(mqtt, user, room)
			@mqtt = mqtt;
			@user = user;
			@room = room;

			@listeningEnabled = true;

			@sentences = Hash.new();
		end

		def process(words)
			#next unless user.home? and user.awake?
			puts "Got words: #{words}"

			if (words == "computer enable voice control") and (not @listeningEnabled) then
				@listeningEnabled = true;
				@user.notify "Voice control on"
				return;
			elsif (words == "computer disable voice control") and (@listeningEnabled) then
				@listeningEnabled = false;
				@user.notify "Voice control off"
				return;
			end

			return unless @listeningEnabled;

			words = VoiceControl::NumberDecoding.decode(words);
			puts "Working on: #{words}";

			@sentences.each do |key, val|
				if(key.is_a? Regexp) then
					if(result = key.match(words)) then
						val.call(result);
					end
				elsif(key.is_a? String) then
					val.call if key == words;
				end
			end
		end

		def sentence(regEx, &block)
			@sentences[regEx] = block;
		end

		def add_sentences(filename = nil, &block)
			self.instance_eval(File.read(filename)) if filename;
			self.instance_eval(&block) if block_given?
		end
	end
end

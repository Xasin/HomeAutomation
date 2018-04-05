
module VoiceControl
	module NumberDecoding
		@modifiers = {
			"micro"		=> 0.000001,
			"milli"		=> 0.001,
			"percent"	=> 0.01,
			"hundred" 	=> 100,
			"thousand"	=> 1000,
			"million"	=> 1000000,
			"billion"	=> 1000000000,
		}

		@numbers = {
			"one"		=> 1,
			"two"		=> 2,
			"three"	=> 3,
			"four"	=> 4,
			"five"	=> 5,
			"six"		=> 6,
			"seven"	=> 7,
			"eight"	=> 8,
			"nine"	=> 9,
			"ten"			=> 10,
			"twenty"		=> 20,
			"thirty"		=> 30,
			"fourty"		=> 40,
			"fifty"		=> 50,
			"sixty"		=> 60,
			"seventy"	=> 70,
			"eighty"		=> 80,
			"ninety"		=> 90,
		}

		def self.decode(stringArray)
			stringArray = stringArray.clone;
			stringArray = stringArray.split(" ") unless stringArray.is_a? Array

			total = 0;
			currentBlock = 0;

			outputString = [];
			stage = :idle;

			stringArray.each do |e|
				next if (e == "and") and stage != :idle;

				case stage
				when :idle
					if @numbers.include? e then
						stage = :number;
						redo;
					end
					outputString << e;

				when :number
					if @numbers.include? e then
						currentBlock += @numbers[e];
					elsif e == "hundred" then
						currentBlock *= 100;
					elsif @modifiers.include? e then
						stage = :modifier;
						redo;
					else
						total += currentBlock;
						currentBlock = 0;
						outputString << total;
						total = 0;
						stage = :idle;
						redo;
					end

				when :modifier
					if @modifiers.include? e then
						currentBlock *= @modifiers[e];
					elsif @numbers.include? e then
						total += currentBlock;
						currentBlock = 0;
						stage = :number;
						redo;
					else
						total += currentBlock;
						currentBlock = 0;
						outputString << total;
						total = 0;
						stage = :idle;
						redo;
					end
				end
			end

			total += currentBlock;
			outputString << total if stage != :idle;

			return outputString.join(" ");
		end
	end
end

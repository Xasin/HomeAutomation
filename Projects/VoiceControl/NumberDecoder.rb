
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
	end
end

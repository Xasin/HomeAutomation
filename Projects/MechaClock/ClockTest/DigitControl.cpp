
#include "DigitControl.h"

namespace Digits {
	uint8_t currentDigits[NUM_DIGITS] 	= {0};
	uint8_t targetDigits[NUM_DIGITS]		= {0};

	void home() {
		for(uint8_t i=0; i<NUM_DIGITS; i++)
			currentDigits[i] = {0};
		Motor::home();
	}

	void raw_dial(uint8_t totalLetter) {
		Motor::rotateTo(((uint32_t)totalLetter) * STEPS_PER_LETTER);

		currentDigits[0] = totalLetter;
		for(uint8_t i=1; i<NUM_DIGITS; i++) {
			currentDigits[i] = fmin(currentDigits[i], currentDigits[i-1]);
			currentDigits[i] = fmax(currentDigits[i], currentDigits[i-1] - NUM_LETTERS + 1);
		}
	}

	void position_digit(uint8_t totalLetter, uint8_t digitNum) {
		if(totalLetter < currentDigits[digitNum])
			raw_dial(totalLetter);
		else if(totalLetter > currentDigits[digitNum])
			raw_dial(totalLetter + (NUM_LETTERS-1)*digitNum);
	}

	void show_letter(uint8_t letter, uint8_t digitNum) {
		if((currentDigits[digitNum]%NUM_LETTERS) == letter)
			return;

		if(digitNum == (NUM_DIGITS-1))
			position_digit(letter, digitNum);
		else {
			letter = (currentDigits[digitNum+1]/NUM_LETTERS)*NUM_LETTERS + letter;
			if(letter < currentDigits[digitNum+1])
				letter += NUM_LETTERS;

			position_digit(letter, digitNum);
		}
	}

	void load(uint16_t num) {
		for(uint8_t i=0; i<NUM_DIGITS; i++) {
			targetDigits[i] = (num/(uint16_t)pow(10,i))%10;
		}
	}

	void update_digits() {
		for(uint8_t i=(NUM_DIGITS-1); i!=255; i--) {
			show_letter(targetDigits[i], i);
		}
	}

	void update_digits(uint16_t num) {
		load(num);
		update_digits();
	}
}

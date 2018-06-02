
#include "MotorControl.h"

#define NUM_LETTERS 10
#define NUM_DIGITS  4

#define STEPS_PER_LETTER STEPS_PER_REV/NUM_LETTERS

namespace Digits {
	extern uint8_t currentDigits[];
	extern uint8_t targetDigits[];

	void home();

	void raw_dial(uint8_t totalLetter);
	void position_digit(uint8_t totalLetter, uint8_t digitNum);
	void show_letter(uint8_t letter, uint8_t digitNum);

	void load(uint16_t number);

	void update_digits();
	void update_digits(uint16_t number);
}

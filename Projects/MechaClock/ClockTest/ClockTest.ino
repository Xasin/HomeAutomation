
#include <avr/io.h>

#include "MotorControl.h"
#include "DigitControl.h"

#define MOTORS_ON
#define MOTORS_OFF

int16_t currentDial = 0;
volatile int16_t targetDial = -1;

uint8_t timerAPresc = 1;
ISR(TIMER1_OVF_vect) {
	sei();
	if(timerAPresc-- == 0) {
		timerAPresc = 1000/UPDATE_FREQ;
		Motor::updateMotor();
	}
}

ISR(INT0_vect) {
	Motor::updateEncoder();
}

uint8_t TWI_writePos 	= 0;
uint8_t TWI_writeBuffer = 0;
ISR(TWI_vect) {
	uint8_t TWSR_copy = TWSR & ~0b11;
	switch(TWSR) {
		case 0x60: // Address received
			TWI_writePos = 0;
		break;

		case 0x80: // Data byte received
			if(TWI_writePos == 0) {
				TWI_writePos++;
				TWI_writeBuffer = TWDR;
			}
			else {
				targetDial = (TWI_writeBuffer | TWDR <<8);
			}
		break;
	}

	TWCR |= (1<< TWINT);
}

void setup() {
	Motor::init();

	TWAR = 0x31 <<1;
	TWCR = (1<< TWEA | 1<< TWIE | 1<< TWEN);

	sei();
}

void loop() {
	if(currentDial != targetDial) {
		if(targetDial == -1) {
			Digits::update_digits(0);
			//MOTORS_OFF;
			currentDial = -1;
		}
		else if(currentDial == -1) {
			//MOTORS_ON;
			Digits::home();
			currentDial = 0;
		}
		else
			Digits::update_digits(currentDial = targetDial);
	}
}

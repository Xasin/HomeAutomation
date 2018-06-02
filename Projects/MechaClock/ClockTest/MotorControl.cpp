
#include "MotorControl.h"


namespace Motor {
	volatile int32_t motorPosition = 0;
	volatile int32_t lastMotor		 = 0;
	volatile int32_t motorTarget	 = 0;
	volatile int16_t motorSpeed	 = 0;

	void setMotorPower(float pwr) {
		if(pwr < 0) {
			PORTB |= 1<< MOTOR_DIR;
			pwr = -1 * pwr;
		}
		else
			PORTB &= ~(1<< MOTOR_DIR);

		if(pwr < P_FACT * 4)
			pwr = 0;
		else if(pwr < 0.15)
			pwr = 0.15;
		else if(pwr > 1)
			pwr = 1;

		OCR1A = pwr*4000;
	}

	void updateEncoder() {
		if((PINC>>MOTOR_C1 ^ PINC>>MOTOR_C2) & 1)
			motorPosition++;
		else
			motorPosition--;
	}

	void updateMotor() {
		motorSpeed = motorPosition - lastMotor;
		lastMotor = motorPosition;

		setMotorPower(	P_FACT * (motorTarget - motorPosition)
							- D_FACT * motorSpeed);
	}

	void rotateTo(int32_t steps) {
		motorTarget = steps;

		int32_t mDiff = 0;
		while(true) {
			mDiff = (motorTarget - motorPosition);
			if(fabs(mDiff) < 10)
				break;
		}

    _delay_ms(30);
	 motorTarget = motorPosition;
	}

	void home() {
		uint8_t conseq_stops = 0;

		while(conseq_stops < 10) {
			motorTarget = motorPosition - 0.3/P_FACT;
			if(fabs(motorSpeed) < 1)
				conseq_stops++;
			else
				conseq_stops = 0;

			_delay_ms(10);
		}

		motorPosition 	= - HOME_STEP_CORRECT;
		motorTarget   	= 0;
		lastMotor		= 0;
	}

	void init() {
		PORTC  |= (1<< MOTOR_C1  | 1<< MOTOR_C2);
		DDRB   |= (1<< MOTOR_PWM | 1<< MOTOR_DIR);

		PCMSK1 |= (1<< MOTOR_C1);
		PCICR  |= (1<< PCIE1);

		TCCR1A = (1<< COM1A1 | 1<< WGM11);
		TCCR1B = (1<< WGM13  | 1<< CS10);
		ICR1   = 4000;

		TIMSK1|= (1<< TOIE1);
	}
}

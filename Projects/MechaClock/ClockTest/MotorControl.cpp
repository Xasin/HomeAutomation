
#include "MotorControl.h"


namespace Motor {
	volatile int32_t motorPosition = 0;
	volatile int32_t lastMotor     = 0;
	volatile int32_t motorTarget   = 0;

	void setMotorPower(float pwr) {
	  if(pwr < 0) {
	    PORTB |= 1<< MOTOR_DIR;
	    pwr = -1 * pwr;
	  }
	  else
	    PORTB &= ~(1<< MOTOR_DIR);

	  if(pwr < 0.02)
	    pwr = 0;
	  else if(pwr < 0.13)
	    pwr = 0.13;
	  else if(pwr > 1)
	    pwr = 1;

	  OCR1A = pwr*8000;
	}

  void updateEncoder() {
    if((PIND>>MOTOR_C1 ^ PIND>>MOTOR_C2) & 1)
       motorPosition++;
     else
       motorPosition--;
  }

  void updateMotor() {
    setMotorPower(P_FACT * (motorTarget - motorPosition)
            - D_FACT * (motorPosition - lastMotor));
      lastMotor = motorPosition;
  }

	void rotateTo(int32_t steps) {
	  motorTarget = steps;

	  int32_t mDiff = 0;
	  while(true) {
	   mDiff = (motorTarget - motorPosition);
		if(fabs(mDiff) < 10)
	      break;
	  }

	  _delay_ms(50);
	}

	void init() {
		PORTD |= (1<< MOTOR_C1  | 1<< MOTOR_C2);
		DDRB  |= (1<< MOTOR_PWM | 1<< MOTOR_DIR);

		EICRA |= (1<< ISC00);
		EIMSK |= (1<< INT0);

		TCCR1A = (1<< COM1A1 | 1<< WGM11);
		TCCR1B = (1<< WGM13 | 1<< CS10);
		ICR1   = 8000;

		TIMSK1|= (1<< TOIE1);

		while(true) {
		  motorTarget -= 100;
		  _delay_ms(100);
		  if(fabs(motorTarget - motorPosition) > 100)
			 break;
		}

		motorPosition 	= 0;
		motorTarget   	= 0;
		lastMotor		= 0;
	}
}
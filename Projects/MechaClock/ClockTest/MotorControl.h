
#include <avr/io.h>
#include <math.h>
#include <util/delay.h>

#define P_FACT 0.02
#define D_FACT 0.05

#define MOTOR_C1 PC2
#define MOTOR_C2 PC3

#define MOTOR_DIR PB0
#define MOTOR_PWM PB1

#define UPDATE_FREQ 100

#define STEPS_PER_REV 2124

#define HOME_STEP_CORRECT 50

namespace Motor {
	void init();

	void home();

	void updateEncoder();
	void updateMotor();

	void rotateTo(int32_t targetPosition);
}

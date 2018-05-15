
#include <avr/io.h>
#include <math.h>
#include <util/delay.h>

#define P_FACT 0.03
#define D_FACT 0.005

#define MOTOR_C1 PD2
#define MOTOR_C2 PD3

#define MOTOR_DIR PB0
#define MOTOR_PWM PB1

#define UPDATE_FREQ 100

#define STEPS_PER_REV 2124

namespace Motor {
	void init();

	void home();

	void updateEncoder();
	void updateMotor();

	void rotateTo(int32_t targetPosition);
}

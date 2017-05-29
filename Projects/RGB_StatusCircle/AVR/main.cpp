

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <math.h>

#include "Job.h"

#define DATA_PIN PD3
#define TICK_PIN PD4

#define ARRAY_LEN (3*8)

uint8_t bitpos = ARRAY_LEN-1;
uint8_t brightnesses[ARRAY_LEN];

struct {
	uint8_t length = 0;
	uint8_t red 	= 0;
	uint8_t green	= 0;
	uint8_t blue 	= 0;
} barData;

enum acceptedCommands : uint8_t {
	SET_BAR 			= 0,
	SET_BAR_COLOR 	= 1,
	SET_CUSTOM_DATA = 2,
};

class RecData : public TWI::Job {
public:
	RecData();

	bool slavePrepare();
	void slaveEnd();
};

uint8_t nextPORTC = 0;
ISR(TIMER0_OVF_vect) {
	PORTD |= (1<< TICK_PIN);
	PORTD &= ~(1<< TICK_PIN | 1<< DATA_PIN);
	PORTC = nextPORTC;

	// Apply brightness setting for next tick
	uint8_t led 	= bitpos/3;
	if(bitpos%6 >= 3)
		led = led/2 + 4;
	else
		led = led/2;
	OCR0A = 255 - brightnesses[led*3 + bitpos%3];

	nextPORTC = (~(1<<bitpos/6) & 0b1111);

	// Increment bitposition & loop around
	bitpos++;
	if(bitpos == ARRAY_LEN)
		bitpos = 0;

	// Check if the shift register needs to be restarted.
	if(bitpos%6 == 0)
		PORTD |= (1<< DATA_PIN);

}

uint8_t adjColor(int16_t n) {
	if(n < 0)
		return 0;
	if(n > 250)
		return 250;
	return (pow(n, 2)/255);
}

void setRGB(uint8_t n, int16_t r, int16_t g, int16_t b) {
	brightnesses[0+n*3] = adjColor(r);
	brightnesses[1+n*3] = adjColor(g);
	brightnesses[2+n*3] = adjColor(b);
}

void setBar(int8_t startN, int8_t endN, float percent, int16_t r, int16_t g, int16_t b) {
	uint8_t lenOfBar = (endN - startN)%12 + 1;

	float percentPerLED = 1.0/lenOfBar;
	float pwrThisLED = 0;

	for(uint8_t j = 0; j<lenOfBar; j++) {
		if(percent <= percentPerLED) {
			pwrThisLED = percent/percentPerLED;
			percent = 0;
		}
		else {
			pwrThisLED = 1;
			percent -= percentPerLED;
		}

		pwrThisLED *= 0.3;

		setRGB(j%8, r*pwrThisLED, g*pwrThisLED, b*pwrThisLED);
	}
}

RecData::RecData() {}
bool RecData::slavePrepare() {
	if(TWI::targetReg == acceptedCommands::SET_BAR) {
		TWI::dataLength = 1;
		TWI::dataPacket = (uint8_t *)&barData;
		return true;
	}
	if(TWI::targetReg == acceptedCommands::SET_BAR_COLOR) {
		TWI::dataLength = 3;
		TWI::dataPacket = ((uint8_t *)&barData) +1;
		return true;
	}

	if(TWI::targetReg == acceptedCommands::SET_CUSTOM_DATA) {
		TWI::dataLength = ARRAY_LEN;
		TWI::dataPacket = brightnesses;
		return true;
	}

}
void RecData::slaveEnd() {
	if(TWI::targetReg == acceptedCommands::SET_BAR ||
		TWI::targetReg == acceptedCommands::SET_BAR_COLOR)
		setBar(0, 7, ((float)barData.length)/255.0, barData.red, barData.green, barData.blue);
}

RecData testThing = RecData();

int main() {

	DDRC 		|= (0b1111);
	PORTC 	|= (0b1110);
	DDRB |= (1<< PB5);

	DDRD |= (1<< DATA_PIN | 1<< TICK_PIN | 1<< PD6);

	TCCR0A |= (1<< WGM00 | 1<< WGM01 | 1<< COM0A1);
	TCCR0B |= (1<< CS01);

	TIMSK0 |= (1<< TOIE0);

	TWI::init();
	TWI::setAddr(0x01);

	for(uint8_t i = 0; i<ARRAY_LEN; i++)
		brightnesses[i] = 0;

	sei();


	_delay_ms(3000);

	float i = 0;
	uint8_t formerJ = 5;
	while(1) {
		if((TWCR & (1<< TWINT)) != 0)
			TWI::updateTWI();
	}
	return 0;
}

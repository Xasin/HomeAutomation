

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

enum acceptedCommands : uint8_t {
	SET_CUSTOM_DATA = 2,
};

class RecData : public TWI::Job {
public:
	RecData();

	bool slavePrepare();
};

uint16_t adjBrightness(uint16_t input) {
	if(input > 252) return 1010;
	return (input*input) >> 6;
}

uint8_t nextPORTC = 0;
ISR(TIMER1_OVF_vect) {
	PORTD |= (1<< TICK_PIN);
	PORTD &= ~(1<< TICK_PIN | 1<< DATA_PIN);
	PORTC = nextPORTC;

	// Apply brightness setting for next tick
	uint8_t led 	= bitpos/3;
	if(bitpos%6 >= 3)
		led = led/2 + 4;
	else
		led = led/2;
	OCR1A = 0x03FF - adjBrightness(brightnesses[led*3 + bitpos%3]);

	nextPORTC = (~(1<<bitpos/6) & 0b1111);

	// Increment bitposition & loop around
	bitpos++;
	if(bitpos == ARRAY_LEN)
		bitpos = 0;

	// Check if the shift register needs to be restarted.
	if(bitpos%6 == 0)
		PORTD |= (1<< DATA_PIN);

}

RecData::RecData() {}
bool RecData::slavePrepare() {
	if(TWI::targetReg == acceptedCommands::SET_CUSTOM_DATA) {
		TWI::dataLength = ARRAY_LEN;
		TWI::dataPacket = brightnesses;
		return true;
	}

	return false;
}

RecData testThing = RecData();

int main() {

	DDRC 		|= (0b1111);
	PORTC 	|= (0b1110);

	DDRB |= (1<< PB5 | 1<< PB1);

	DDRD |= (1<< DATA_PIN | 1<< TICK_PIN);

	TCCR1A |= (1<< WGM10 | 1<< WGM11 | 1<< COM1A1);
	TCCR1B |= (1<< CS10 | 1<<WGM12);

	TIMSK1 |= (1<< TOIE1);

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

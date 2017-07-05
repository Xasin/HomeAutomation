

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <math.h>

#include "Job.h"

#define NUM_LEDS  8
#define ARRAY_LEN (3*NUM_LEDS)

#define DEBUG_BLINK PORTB ^= (1<< PB5);

uint8_t brightnesses[ARRAY_LEN];

uint16_t adjBrightness(uint16_t input) {
	if(input > 252) return 1010;
	return (input*input) >> 6;
}

volatile uint32_t cTime = 0;
uint32_t timestamp() {
	return cTime + TCNT1;
}
uint32_t icp_timestamp() {
	return cTime + ICR1;
}

uint32_t pChangeStart = 0;
uint32_t lastPhase = 0;

volatile uint32_t rotStart = 0;
volatile uint32_t rotDur = 0;
ISR(TIMER1_CAPT_vect) {
	uint32_t cMics = icp_timestamp();

	uint32_t thisPhase = cMics - pChangeStart;
	pChangeStart = cMics;

	if(thisPhase > lastPhase) {
		rotDur = cMics - rotStart;
		rotStart = cMics;
	}

	lastPhase = thisPhase;
}

uint8_t getSegment() {
	return ((timestamp() - rotStart) * NUM_LEDS) / rotDur;
}

uint8_t cColor = 0;
ISR(TIMER1_OVF_vect) {
	PORTB |= (0b111 << 2);
	PORTB &= ~(1 << (cColor+2));

	cTime += 1 << 10;

	if(++cColor == 3)
		cColor = 0;

	uint8_t segment = getSegment()%NUM_LEDS;

	OCR1A = 1023 - adjBrightness(brightnesses[segment*3 + cColor]);
}

enum acceptedCommands : uint8_t {
	SET_CUSTOM_DATA = 2,
};

class RecData : public TWI::Job {
public:
	RecData();

	bool slavePrepare();
};

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

	DDRB |= (0b111 << 2 | 1 << PB1 | 1<< PB5);
	PORTB |= (1 | 0b11 << 3);

	PORTD |= (1<< PD7);

	TCCR1A |= (1<< WGM10 | 1<< WGM11 | 1<< COM1A0 | 1<< COM1A1);
	TCCR1B |= (1<< CS10 | 1<<WGM12 | 1<< ICES1 | 1<< ICNC1);

	TIMSK1 |= (1<< TOIE1 | 1<< ICIE1);

	TWI::init();
	TWI::setAddr(0x01);

	for(uint8_t i = 0; i<ARRAY_LEN; i++)
		brightnesses[i] = 0;

	brightnesses[0]	= 250;
	sei();

	_delay_ms(100);

	uint32_t cMics = 0;
	while(1) {
		if((TWCR & (1<< TWINT)) != 0)
			TWI::updateTWI();
	}
	return 0;
}

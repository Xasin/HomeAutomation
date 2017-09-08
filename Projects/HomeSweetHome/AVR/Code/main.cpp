

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

uint16_t RGB_real[3] 	= {0};
volatile uint16_t RGB_realBuf[3] = {0};
uint16_t counter = 0;

uint8_t TWI_writePos  = 0;
volatile uint8_t RGB_target[3] = {0};
volatile uint8_t RGB_start[3]  = {0};

volatile uint8_t RGB_TWIBuffer[3] = {0};

volatile uint16_t fade_duration = 1;
volatile uint16_t fade_position = 0;

volatile uint16_t fade_durationBuffer = 0;

// Run the timer every 200 clock cycles. Should give a good 10bit Soft-PWM
ISR(TIMER0_COMPA_vect) {
	counter++;

	if((counter & 1<<10) != 0) {
		counter = 0;

		PORTB |= (0b111 << 1);

		if(fade_position > 0)
			fade_position--;
		for(uint8_t i=0; i<3; i++) {
			RGB_real[i] = RGB_realBuf[i];
		}
	}

	for(uint8_t i=0; i<3; i++) {
		if(RGB_real[i] == counter) {
			PORTB &= ~(0b10 << i);
		}
	}
}

ISR(TWI_vect) {
	uint8_t TWSR_copy = TWSR & ~0b11;
	switch(TWSR_copy) {
	case 0x60: TWI_writePos = 0; break;
	case 0x80:
		if(TWI_writePos < 3)
			RGB_TWIBuffer[TWI_writePos++] = TWDR;
		else if(TWI_writePos < 5)
			((uint8_t *)&fade_durationBuffer)[TWI_writePos++ - 3] = TWDR;
		break;
	default: break;
	}

	TWCR |= (1<< TWINT);
	sei();

	if(TWSR_copy == 0xA0) {
		if(fade_position == 0) {
			for(uint8_t i=0; i<3; i++) {
				RGB_start[i] 	= RGB_target[i];
				RGB_target[i]	= RGB_TWIBuffer[i];
			}
		}
		else {
			uint16_t phase = (((uint32_t)fade_position) << 8) / fade_duration;
			for(uint8_t i=0; i<3; i++) {
				RGB_start[i] 	= (((256 - phase)*RGB_target[i] + phase*RGB_start[i]) >> 8);
				RGB_target[i]	= RGB_TWIBuffer[i];
			}
		}

		fade_duration = fade_durationBuffer;
		fade_position = fade_duration;
	}
}

int main() {

	TWAR = 0x30<<1;
	TWCR = (1<< TWEA | 1<< TWIE | 1<< TWEN);

	DDRB = (0b111 << 1);

	OCR0A  = 150 -1;
	TCCR0A = (1<< WGM01);
	TCCR0B = (1<< CS00);
	TIMSK0 = (1<< OCIE0A);

	uint16_t fade_phase = 0;
	uint16_t unscaled_power = 0;

	sei();

	while(1) {
		fade_phase = (((uint32_t)fade_position) << 8) / fade_duration;
		for(uint8_t i=0; i<3; i++) {
			unscaled_power = ((256 - fade_phase)*RGB_target[i] + fade_phase*RGB_start[i]) / 256;
			RGB_realBuf[i]	= 1024 - pow(unscaled_power, 2) / 64;
		}
	}
	return 1;
}

#include "MotorControl.h"

#define SEGMENTS  10
#define DIGIT_NUM 3
uint8_t currentSignPositions[DIGIT_NUM] = {0};
uint8_t signDigits[DIGIT_NUM] = {0};

uint8_t timerAPresc = 1;
ISR(TIMER1_OVF_vect) {
	sei();
  if(timerAPresc-- == 0) {
    timerAPresc = 1000/UPDATE_FREQ;

	 Motor::updateMotor();
  }
}

ISR(INT0_vect) {
  sei();
  Motor::updateEncoder();
}

void dialDigit_raw(uint8_t digitNum) {
  Motor::rotateTo(digitNum * STEPS_PER_REV / SEGMENTS);

  currentSignPositions[0] = digitNum;
  for(uint8_t i=1; i<DIGIT_NUM; i++) {
    if(currentSignPositions[i] > digitNum)
      currentSignPositions[i] = digitNum;
    else if((currentSignPositions[i] + i*(SEGMENTS-1)) < digitNum)
      currentSignPositions[i] = digitNum - i*(SEGMENTS-1);
  }
}

void dialDigit(uint8_t digitNum, uint8_t segmentNum) {
  uint8_t futurePosition = 0;

  if(segmentNum == DIGIT_NUM) {
    futurePosition = digitNum;
  }
  else {
    futurePosition = (currentSignPositions[segmentNum+1]/SEGMENTS)*SEGMENTS + digitNum;
    if(futurePosition < currentSignPositions[segmentNum+1])
      futurePosition += SEGMENTS;
  }

  if(futurePosition <= currentSignPositions[segmentNum])
    dialDigit_raw(futurePosition);
  else
    dialDigit_raw(futurePosition + (SEGMENTS-1)*segmentNum);
}

void printDigits() {
  for(uint8_t i=0; i<DIGIT_NUM; i++) {
    Serial.print(currentSignPositions[i]%SEGMENTS);
    Serial.print(" ");
  }
  Serial.print("\n");
}


void updateNumbers() {
  Serial.println("Updating digits:");
  for(uint8_t i=(DIGIT_NUM-1); i!=255; i--) {
    if((currentSignPositions[i]%SEGMENTS) != signDigits[i])
      dialDigit(signDigits[i], i);
  }
}

void setupNumber(uint32_t newNumber) {
  for(uint8_t i=0; i<DIGIT_NUM; i++) {
    signDigits[i] = (newNumber/(uint8_t)pow(10,i))%10;
  }
}

void setup() {
  sei();

  Serial.begin(9600);

	Motor::init();
  pinMode(13, OUTPUT);
}

uint16_t dialNumber = 0;
void loop() {
  Motor::rotateTo(0);
  delay(2000);
  Motor::rotateTo(STEPS_PER_REV * 5);
  delay(2000);
}

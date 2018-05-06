#define P_FACT 0.03
#define D_FACT 0.005

#define MOTOR_C1 PD2
#define MOTOR_C2 PD3

#define MOTOR_DIR PB0
#define MOTOR_PWM PB1

#define UPDATE_FREQ 100

#define STEPS_PER_REV 412.5*5

volatile int32_t motorPosition = 0;
volatile int32_t lastMotor     = 0;
volatile int32_t motorTarget   = 0;

#define SEGMENTS  10
#define DIGIT_NUM 3
uint8_t currentSignPositions[DIGIT_NUM] = {0};
uint8_t signDigits[DIGIT_NUM] = {0};

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

uint8_t timerAPresc = 1;
ISR(TIMER1_OVF_vect) {
  if(timerAPresc-- == 0) {
    setMotorPower(P_FACT * (motorTarget - motorPosition) - D_FACT * (motorPosition - lastMotor));
    lastMotor = motorPosition;
    
    timerAPresc = 1000/UPDATE_FREQ;
  }
}

ISR(INT0_vect) {
  sei();

  if((PIND>>MOTOR_C1 ^ PIND>>MOTOR_C2) & 1)
    motorPosition++;
  else
    motorPosition--;
}

void rotateTo(int32_t steps) {
  motorTarget = steps;

  int32_t mDiff = 0;
  while(true) {
    mDiff = (motorTarget - motorPosition);
    if(mDiff < 0) 
      mDiff = -mDiff;

    if(mDiff < 10)
      break;
  }

  delay(100);
}

void dialDigit_raw(uint8_t digitNum) {
  rotateTo(digitNum * STEPS_PER_REV / SEGMENTS);
  
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

void setup() {
  PORTD |= (1<< MOTOR_C1  | 1<< MOTOR_C2);
  DDRB  |= (1<< MOTOR_PWM | 1<< MOTOR_DIR);

  EICRA |= (1<< ISC00);
  EIMSK |= (1<< INT0);

  TCCR1A = (1<< COM1A1 | 1<< WGM11);
  TCCR1B = (1<< WGM13 | 1<< CS10);
  ICR1   = 8000;

  TIMSK1|= (1<< TOIE1);

  sei();

  Serial.begin(9600);

  while(true) {
    motorTarget -= STEPS_PER_REV / SEGMENTS / 4;
    delay(100);
    if(fabs(motorTarget - motorPosition) > 100)
      break;
  }
  
  motorPosition = 0;
  motorTarget   = 0;
}

uint16_t dialNumber = 0;
void loop() {
  dialNumber = random(0, 1000);
  
  for(uint8_t i=0; i<DIGIT_NUM; i++) {
    signDigits[i] = (dialNumber/(uint8_t)pow(10,i))%10;
  }
  
  updateNumbers();
  printDigits();

  delay(2000);
}

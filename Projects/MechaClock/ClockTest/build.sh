#!/bin/bash

SOURCE_FILES=(main.cpp MotorControl.cpp DigitControl.cpp)

avr-gcc -mmcu=atmega168p -DF_CPU=8000000 -std=c++11 -O2 ${SOURCE_FILES[*]} -o main.elf && avr-objcopy -j .text -j .data -O ihex main.elf main.hex && avrdude -p m168p -P /dev/ttyACM0 -c stk500v2 -U flash:w:main.hex

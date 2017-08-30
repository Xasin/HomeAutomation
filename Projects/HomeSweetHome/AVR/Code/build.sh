#!/bin/bash

SOURCE_FILES=(main.cpp)

avr-gcc -mmcu=atmega328p -DF_CPU=8000000 -std=c++11 -O3 ${SOURCE_FILES[*]} -o main.elf && avr-objcopy -j .text -j .data -O ihex main.elf main.hex && avrdude -p m328p -P /dev/ttyACM1 -c stk500v2 -U flash:w:main.hex

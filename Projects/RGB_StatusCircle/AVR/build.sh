#!/bin/bash

SOURCE_FILES=(main.cpp TWI.cpp Job.cpp)

avr-gcc -mmcu=atmega328p -DF_CPU=16000000 -std=c++11 -O3 ${SOURCE_FILES[*]} -o main.elf && avr-objcopy -j .text -j .data -O ihex main.elf main.hex && avrdude -p m328p -P /dev/ttyACM0 -c arduino -U flash:w:main.hex

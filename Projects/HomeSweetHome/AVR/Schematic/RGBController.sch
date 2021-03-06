EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
EELAYER 25 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L ATMEGA328P-PU U1
U 1 1 59A3D9D3
P 4500 3950
F 0 "U1" H 3750 5200 50  0000 L BNN
F 1 "ATMEGA328P-PU" H 4900 2550 50  0000 L BNN
F 2 "DIL28" H 4500 3950 50  0001 C CIN
F 3 "" H 4500 3950 50  0001 C CNN
	1    4500 3950
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR2
U 1 1 59A3DB5E
P 3600 5400
F 0 "#PWR2" H 3600 5150 50  0001 C CNN
F 1 "GND" H 3600 5250 50  0000 C CNN
F 2 "" H 3600 5400 50  0001 C CNN
F 3 "" H 3600 5400 50  0001 C CNN
	1    3600 5400
	1    0    0    -1  
$EndComp
Wire Wire Line
	3600 5050 3600 5400
Connection ~ 3600 5150
$Comp
L VCC #PWR1
U 1 1 59A3DB95
P 3600 2500
F 0 "#PWR1" H 3600 2350 50  0001 C CNN
F 1 "VCC" H 3600 2650 50  0000 C CNN
F 2 "" H 3600 2500 50  0001 C CNN
F 3 "" H 3600 2500 50  0001 C CNN
	1    3600 2500
	1    0    0    -1  
$EndComp
Wire Wire Line
	3600 2500 3600 3450
Connection ~ 3600 2850
Connection ~ 3600 3150
$Comp
L CONN_01X04 J1
U 1 1 59A3DCA1
P 7550 3950
F 0 "J1" H 7550 4200 50  0000 C CNN
F 1 "CONN_01X04" V 7650 3950 50  0000 C CNN
F 2 "" H 7550 3950 50  0001 C CNN
F 3 "" H 7550 3950 50  0001 C CNN
	1    7550 3950
	-1   0    0    1   
$EndComp
$Comp
L GND #PWR4
U 1 1 59A3DEE0
P 7900 4200
F 0 "#PWR4" H 7900 3950 50  0001 C CNN
F 1 "GND" H 7900 4050 50  0000 C CNN
F 2 "" H 7900 4200 50  0001 C CNN
F 3 "" H 7900 4200 50  0001 C CNN
	1    7900 4200
	1    0    0    -1  
$EndComp
Wire Wire Line
	7750 4100 7900 4100
Wire Wire Line
	7900 4100 7900 4200
$Comp
L VCC #PWR6
U 1 1 59A3DF0F
P 8250 4000
F 0 "#PWR6" H 8250 3850 50  0001 C CNN
F 1 "VCC" H 8250 4150 50  0000 C CNN
F 2 "" H 8250 4000 50  0001 C CNN
F 3 "" H 8250 4000 50  0001 C CNN
	1    8250 4000
	1    0    0    -1  
$EndComp
Wire Wire Line
	7750 4000 8250 4000
Wire Wire Line
	7750 3900 8100 3900
Wire Wire Line
	7750 3800 8100 3800
Text Label 8100 3800 2    60   ~ 0
SCL
Text Label 8100 3900 2    60   ~ 0
SDA
Wire Wire Line
	5500 4100 5850 4100
Wire Wire Line
	5500 4200 5850 4200
Text Label 5850 4100 2    60   ~ 0
SDA
Text Label 5850 4200 2    60   ~ 0
SCL
$Comp
L Q_NMOS_GDS Q2
U 1 1 59A3E300
P 7200 2100
F 0 "Q2" H 7400 2150 50  0000 L CNN
F 1 "Q_NMOS_GDS" H 7400 2050 50  0000 L CNN
F 2 "" H 7400 2200 50  0001 C CNN
F 3 "" H 7200 2100 50  0001 C CNN
	1    7200 2100
	1    0    0    -1  
$EndComp
$Comp
L Q_NMOS_GDS Q4
U 1 1 59A3E4BD
P 8200 2100
F 0 "Q4" H 8400 2150 50  0000 L CNN
F 1 "Q_NMOS_GDS" H 8400 2050 50  0000 L CNN
F 2 "" H 8400 2200 50  0001 C CNN
F 3 "" H 8200 2100 50  0001 C CNN
	1    8200 2100
	1    0    0    -1  
$EndComp
$Comp
L Q_NMOS_GDS Q6
U 1 1 59A3E520
P 9200 2100
F 0 "Q6" H 9400 2150 50  0000 L CNN
F 1 "Q_NMOS_GDS" H 9400 2050 50  0000 L CNN
F 2 "" H 9400 2200 50  0001 C CNN
F 3 "" H 9200 2100 50  0001 C CNN
	1    9200 2100
	1    0    0    -1  
$EndComp
$Comp
L Q_NPN_EBC Q1
U 1 1 59A3E74B
P 6900 2450
F 0 "Q1" H 7100 2500 50  0000 L CNN
F 1 "Q_NPN_EBC" H 7100 2400 50  0000 L CNN
F 2 "" H 7100 2550 50  0001 C CNN
F 3 "" H 6900 2450 50  0001 C CNN
	1    6900 2450
	1    0    0    -1  
$EndComp
$Comp
L Q_NPN_EBC Q3
U 1 1 59A3E7FA
P 7900 2450
F 0 "Q3" H 8100 2500 50  0000 L CNN
F 1 "Q_NPN_EBC" H 8100 2400 50  0000 L CNN
F 2 "" H 8100 2550 50  0001 C CNN
F 3 "" H 7900 2450 50  0001 C CNN
	1    7900 2450
	1    0    0    -1  
$EndComp
$Comp
L Q_NPN_EBC Q5
U 1 1 59A3E821
P 8900 2450
F 0 "Q5" H 9100 2500 50  0000 L CNN
F 1 "Q_NPN_EBC" H 9100 2400 50  0000 L CNN
F 2 "" H 9100 2550 50  0001 C CNN
F 3 "" H 8900 2450 50  0001 C CNN
	1    8900 2450
	1    0    0    -1  
$EndComp
Wire Wire Line
	7000 2050 7000 2250
Wire Wire Line
	8000 2050 8000 2250
Wire Wire Line
	9000 2050 9000 2250
$Comp
L R_Small R1
U 1 1 59A3E9FB
P 6700 2550
F 0 "R1" H 6730 2570 50  0000 L CNN
F 1 "51kΩ" H 6730 2510 50  0000 L CNN
F 2 "" H 6700 2550 50  0001 C CNN
F 3 "" H 6700 2550 50  0001 C CNN
	1    6700 2550
	-1   0    0    1   
$EndComp
$Comp
L R_Small R3
U 1 1 59A3EA62
P 7700 2550
F 0 "R3" H 7730 2570 50  0000 L CNN
F 1 "51kΩ" H 7730 2510 50  0000 L CNN
F 2 "" H 7700 2550 50  0001 C CNN
F 3 "" H 7700 2550 50  0001 C CNN
	1    7700 2550
	1    0    0    -1  
$EndComp
$Comp
L R_Small R5
U 1 1 59A3EAAD
P 8700 2550
F 0 "R5" H 8730 2570 50  0000 L CNN
F 1 "51kΩ" H 8730 2510 50  0000 L CNN
F 2 "" H 8700 2550 50  0001 C CNN
F 3 "" H 8700 2550 50  0001 C CNN
	1    8700 2550
	1    0    0    -1  
$EndComp
Wire Wire Line
	7300 2300 7300 2800
Wire Wire Line
	7000 2650 7000 2800
Wire Wire Line
	7000 2800 9300 2800
Wire Wire Line
	8000 2800 8000 2650
Connection ~ 7300 2800
Wire Wire Line
	8300 2800 8300 2300
Connection ~ 8000 2800
Wire Wire Line
	9000 2800 9000 2650
Connection ~ 8300 2800
Wire Wire Line
	9300 2300 9300 2900
Connection ~ 9000 2800
$Comp
L R_Small R2
U 1 1 59A3F349
P 7000 1950
F 0 "R2" H 7030 1970 50  0000 L CNN
F 1 "51kΩ" H 7030 1910 50  0000 L CNN
F 2 "" H 7000 1950 50  0001 C CNN
F 3 "" H 7000 1950 50  0001 C CNN
	1    7000 1950
	1    0    0    -1  
$EndComp
$Comp
L R_Small R4
U 1 1 59A3F39A
P 8000 1950
F 0 "R4" H 8030 1970 50  0000 L CNN
F 1 "51kΩ" H 8030 1910 50  0000 L CNN
F 2 "" H 8000 1950 50  0001 C CNN
F 3 "" H 8000 1950 50  0001 C CNN
	1    8000 1950
	1    0    0    -1  
$EndComp
$Comp
L R_Small R6
U 1 1 59A3F3C9
P 9000 1950
F 0 "R6" H 9030 1970 50  0000 L CNN
F 1 "51kΩ" H 9030 1910 50  0000 L CNN
F 2 "" H 9000 1950 50  0001 C CNN
F 3 "" H 9000 1950 50  0001 C CNN
	1    9000 1950
	1    0    0    -1  
$EndComp
Connection ~ 7000 2100
Connection ~ 8000 2100
Connection ~ 9000 2100
Wire Wire Line
	6700 2650 6700 3150
Wire Wire Line
	7700 2650 7700 3150
Wire Wire Line
	8700 2650 8700 3150
Text Label 6700 3150 1    60   ~ 0
R_PWM
Text Label 7700 3150 1    60   ~ 0
G_PWM
Text Label 8700 3150 1    60   ~ 0
B_PWM
$Comp
L GND #PWR10
U 1 1 59A40C74
P 9300 2900
F 0 "#PWR10" H 9300 2650 50  0001 C CNN
F 1 "GND" H 9300 2750 50  0000 C CNN
F 2 "" H 9300 2900 50  0001 C CNN
F 3 "" H 9300 2900 50  0001 C CNN
	1    9300 2900
	1    0    0    -1  
$EndComp
Connection ~ 9300 2800
$Comp
L +12V #PWR3
U 1 1 59A413C8
P 7000 1750
F 0 "#PWR3" H 7000 1600 50  0001 C CNN
F 1 "+12V" H 7000 1890 50  0000 C CNN
F 2 "" H 7000 1750 50  0001 C CNN
F 3 "" H 7000 1750 50  0001 C CNN
	1    7000 1750
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR5
U 1 1 59A413F8
P 8000 1750
F 0 "#PWR5" H 8000 1600 50  0001 C CNN
F 1 "+12V" H 8000 1890 50  0000 C CNN
F 2 "" H 8000 1750 50  0001 C CNN
F 3 "" H 8000 1750 50  0001 C CNN
	1    8000 1750
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR8
U 1 1 59A41428
P 9000 1750
F 0 "#PWR8" H 9000 1600 50  0001 C CNN
F 1 "+12V" H 9000 1890 50  0000 C CNN
F 2 "" H 9000 1750 50  0001 C CNN
F 3 "" H 9000 1750 50  0001 C CNN
	1    9000 1750
	1    0    0    -1  
$EndComp
Wire Wire Line
	7000 1750 7000 1850
Wire Wire Line
	8000 1750 8000 1850
Wire Wire Line
	9000 1750 9000 1850
$Comp
L Screw_Terminal_1x02 J3
U 1 1 59A41E85
P 9550 800
F 0 "J3" H 9550 1050 50  0000 C TNN
F 1 "Screw_Terminal_1x02" V 9400 800 50  0000 C TNN
F 2 "" H 9550 575 50  0001 C CNN
F 3 "" H 9525 800 50  0001 C CNN
	1    9550 800 
	0    1    1    0   
$EndComp
$Comp
L GND #PWR11
U 1 1 59A42469
P 9650 1150
F 0 "#PWR11" H 9650 900 50  0001 C CNN
F 1 "GND" H 9650 1000 50  0000 C CNN
F 2 "" H 9650 1150 50  0001 C CNN
F 3 "" H 9650 1150 50  0001 C CNN
	1    9650 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	9650 1000 9650 1150
$Comp
L +12V #PWR9
U 1 1 59A42548
P 9150 1000
F 0 "#PWR9" H 9150 850 50  0001 C CNN
F 1 "+12V" H 9150 1140 50  0000 C CNN
F 2 "" H 9150 1000 50  0001 C CNN
F 3 "" H 9150 1000 50  0001 C CNN
	1    9150 1000
	1    0    0    -1  
$EndComp
Wire Wire Line
	9150 1000 9450 1000
Wire Wire Line
	5500 2950 5950 2950
Wire Wire Line
	5500 3050 5950 3050
Wire Wire Line
	5500 3150 5950 3150
Text Label 5950 3150 2    60   ~ 0
B_PWM
Text Label 5950 3050 2    60   ~ 0
G_PWM
Text Label 5950 2950 2    60   ~ 0
R_PWM
$Comp
L CONN_01X08 J2
U 1 1 59A44475
P 8450 800
F 0 "J2" H 8450 1250 50  0000 C CNN
F 1 "CONN_01X08" V 8550 800 50  0000 C CNN
F 2 "" H 8450 800 50  0001 C CNN
F 3 "" H 8450 800 50  0001 C CNN
	1    8450 800 
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8800 1000 8800 1150
Wire Wire Line
	8400 1150 8950 1150
Wire Wire Line
	8400 1150 8400 1000
Wire Wire Line
	8950 1150 8950 1100
Connection ~ 8800 1150
$Comp
L +12V #PWR7
U 1 1 59A4475E
P 8950 1100
F 0 "#PWR7" H 8950 950 50  0001 C CNN
F 1 "+12V" H 8950 1240 50  0000 C CNN
F 2 "" H 8950 1100 50  0001 C CNN
F 3 "" H 8950 1100 50  0001 C CNN
	1    8950 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	8700 1200 8700 1000
Wire Wire Line
	7300 1200 8700 1200
Wire Wire Line
	8300 1200 8300 1000
Wire Wire Line
	8600 1000 8600 1250
Wire Wire Line
	8600 1250 8200 1250
Wire Wire Line
	8200 1250 8200 1000
Wire Wire Line
	8500 1000 8500 1300
Wire Wire Line
	8100 1300 9300 1300
Wire Wire Line
	8100 1300 8100 1000
Wire Wire Line
	7300 1200 7300 1900
Connection ~ 8300 1200
Wire Wire Line
	8300 1250 8300 1900
Connection ~ 8300 1250
Wire Wire Line
	9300 1300 9300 1900
Connection ~ 8500 1300
$EndSCHEMATC

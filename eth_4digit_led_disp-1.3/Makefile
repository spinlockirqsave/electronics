# makefile, written by guido socher
#
MCU=atmega328p
DUDECPUTYPE=m328p
#
# === Edit this and enter the correct device/com-port:
# linux (plug in the avrusb500 and type dmesg to see which device it is):
LOADCMD=avrdude -P /dev/ttyUSB0

# mac (plug in the programer and use ls /dev/tty.usbserial* to get the name):
#LOADCMD=avrdude -P /dev/tty.usbserial-A9006MOb

# windows (check which com-port you get when you plugin the avrusb500):
#LOADCMD=avrdude -P COM4

# All operating systems: if you have set the default_serial paramter 
# in your avrdude.conf file correctly then you can just use this
# and you don't need the above -P option:
#LOADCMD=avrdude
# === end edit this
#
LOADARG=-p $(DUDECPUTYPE) -c stk500v2 -e -U flash:w:

# If you have a tuxgraphics microcontroller mail account 
# then you can uncommet the following line to compile the
# email client. You will also need to edit test_emailnotify.c
# and add your account ID there.
#EMAIL=haveaccount
# 
#
CC=avr-gcc
OBJCOPY=avr-objcopy
# optimize for size:
CFLAGS=-g -mmcu=$(MCU) -Wall -W -Os -mcall-prologues
#-------------------
.PHONY: all main
#
#  
all: main.hex main-counter.hex
	@echo "done"
#
counter: main-counter.hex
	@echo "done"
main: main.hex
	@echo "done"
#
size: 
	avr-size *.elf
#-------------------
help: 
	@echo "Usage: make all"
	@echo "or"
	@echo "make fuse|rdfuses"
	@echo "or"
	@echo "make load"
	@echo "or"
	@echo "make load-counter"
	@echo "or"
	@echo "Usage: make clean"
	@echo " "
	@echo "The application level logic for the remote display is implemented in main.c and compiles main.hex "
	@echo "The application level logic for the counter display is implemented in main-counter.c and compiles main-counter.hex "
	@echo " "
	@echo "You have to set the low fuse byte to 0x60 on all new tuxgraphics boards".
	@echo "This can be done with the command (linux/mac if you use avrusb500): make fuse"
#-------------------
main-counter.hex: main-counter.elf 
	$(OBJCOPY) -R .eeprom -O ihex main-counter.elf main-counter.hex 
	avr-size main-counter.elf
	@echo " "
	@echo "Expl.: data=initialized data, bss=uninitialized data, text=code"
	@echo " "

main-counter.elf: main-counter.o ip_arp_udp_tcp.o enc28j60.o websrv_help_functions.o
	$(CC) $(CFLAGS) -o main-counter.elf -Wl,-Map,main-counter.map main-counter.o ip_arp_udp_tcp.o enc28j60.o websrv_help_functions.o
main-counter.o: main-counter.c ip_arp_udp_tcp.h enc28j60.h timeout.h net.h websrv_help_functions.h ip_config.h
	$(CC) $(CFLAGS) -Os -c main-counter.c
#-------------------
main.hex: main.elf 
	$(OBJCOPY) -R .eeprom -O ihex main.elf main.hex 
	avr-size main.elf
	@echo " "
	@echo "Expl.: data=initialized data, bss=uninitialized data, text=code"
	@echo " "

main.elf: main.o ip_arp_udp_tcp.o enc28j60.o websrv_help_functions.o
	$(CC) $(CFLAGS) -o main.elf -Wl,-Map,main.map main.o ip_arp_udp_tcp.o enc28j60.o websrv_help_functions.o
websrv_help_functions.o: websrv_help_functions.c websrv_help_functions.h ip_config.h 
	$(CC) $(CFLAGS) -Os -c websrv_help_functions.c
enc28j60.o: enc28j60.c timeout.h enc28j60.h
	$(CC) $(CFLAGS) -Os -c enc28j60.c
ip_arp_udp_tcp.o: ip_arp_udp_tcp.c net.h enc28j60.h ip_config.h
	$(CC) $(CFLAGS) -Os -c ip_arp_udp_tcp.c
main.o: main.c ip_arp_udp_tcp.h enc28j60.h timeout.h net.h websrv_help_functions.h ip_config.h
	$(CC) $(CFLAGS) -Os -c main.c
#------------------
load: main.hex
	$(LOADCMD) $(LOADARG)main.hex
load-counter: main-counter.hex
	$(LOADCMD) $(LOADARG)main-counter.hex
#-------------------
# Check this with make rdfuses
rdfuses:
	$(LOADCMD) -p $(DUDECPUTYPE) -c stk500v2 -v -q
#
fuse:
	@echo "Setting clock source to external clock on pin xtal1"
	$(LOADCMD) -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U lfuse:w:0x60:m
#
fuses:
	@echo "Setting clock source to external clock on pin xtal1"
	$(LOADCMD) -p  $(DUDECPUTYPE) -c stk500v2 -u -v -U lfuse:w:0x60:m
#-------------------
clean:
	rm -f *.o *.map *.elf main.hex main-counter.hex
#-------------------

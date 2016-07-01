# makefile, written by guido socher
#
# Note: to make a 32bit binary on a 64bit Mac you would run:
# gcc -m32 -Wall -o udpcom_32 udpcom.c
all: udpcom
#-------------------
help: 
	@echo "Usage: make all"
	@echo "or"
	@echo "Usage: make clean"
#-------------------
udpcom: udpcom.c
	gcc -Wall -o udpcom udpcom.c
	strip udpcom
#-------------------
clean:
	rm -f *.o udpcom
#-------------------

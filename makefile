
all: dzx1.bin

lbr: dzx1.lbr

dzx1.bin: dzx1.asm include/bios.inc include/kernel.inc
	asm02 -L -b dzx1.asm
	-rm -f dzx1.build

dzx1.lbr: dzx1.bin
	lbradd dzx1.lbr dzx1.bin

clean:
	-rm -f dzx1.lst
	-rm -f dzx1.bin
	-rm -f dzx1.lbr



dzx1.prg: dzx1.asm include/bios.inc include/kernel.inc
	asm02 -L -b dzx1.asm
	-rm -f dzx1.build

clean:
	-rm -f dzx1.lst
	-rm -f dzx1.bin


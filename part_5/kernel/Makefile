GCC		:=	gcc

CCFLAG 	:=	-m32 -I../include -nostdinc -Wall -fomit-frame-pointer -c -fno-pie

LDFLAG	:=	-Ttext 0x0 -s --oformat binary -m elf_i386
INCDIR	:=	../include
OBJS	:=	head.o main.o sched.o chr_drv/chr_drv.a

system.bin: $(OBJS)
	$(LD)	$(LDFLAG) -e startup_32 -o $@ $^

head.o: head.S
	$(GCC)	-m32 -traditional -c -o $@ $^

main.o: main.c
	$(GCC)	$(CCFLAG) -o $@ $^

sched.o : sched.c
	$(GCC) $(CCFLAG) -o $@ $<

chr_drv/chr_drv.a: chr_drv/*.c
	cd chr_drv; make chr_drv.a; cd ..
	
clean:
	rm *.o
	rm system.bin
	cd chr_drv; make clean; cd ..
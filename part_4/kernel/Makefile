GCC		:=	gcc

#还挺麻烦，不加这个-fno-pie
CCFLAG 	:=	-m32 -I../include -nostdinc -Wall -fomit-frame-pointer -c -fno-pie

LDFLAG	:=	-Ttext 0x0 -s --oformat binary -m elf_i386
INCDIR	:=	../include
OBJS	:=	head.o main.o

system.bin: $(OBJS)
	$(LD)	$(LDFLAG) -e startup_32 -o $@ $^

head.o: head.S
	$(GCC)	-m32 -traditional -c -o $@ $^

main.o: main.c
	$(GCC)	$(CCFLAG) -o $@ $^

clean:
	rm *.o
	rm system.bin
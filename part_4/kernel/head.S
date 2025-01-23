.code32
.text
.globl startup_32,idt,gdt,pg_dir,tmp_floppy_area

                                    
pg_dir:                             # 这就是所谓的二级页表，也叫做“页目录表”
    #.long 0x0                      # 我其实很想为pg_dir留一部分空间，避免初始化pg_dir的时候覆盖startup_32这个段。
    #.long 0x0                      # 但目前这种写法是不行的。因为这4个字节码会被放到地址0x0的位置，当内核被搬运到0x0，紧接着就会试图执行这几个0x0，然后bochs就报错。    
    #.long 0x0                      # 目前只能像书里面说的那样，老老实实覆盖startup_32这个段。
    #.long 0x0

startup_32:                        
    movl $0x10,   %eax              # 前面基本没什么变化，都是设置gdt idt 以及打印字符
    movw %ax,   %ds
    movw %ax,   %es
    movw %ax,   %fs
    movl $0x18, %eax 
    movw %ax,   %gs
    lss stack_start,%esp
    call setup_idt
    call setup_gdt
    call set_clock_idt
    int $0x80
    sti

    movl $0x18, %eax
    movl $0x0,   %edi
    movw %ax,   %gs
    movl $0x0,   %edi

    movb $0xf,  %ah
    movb $0x42,  %al
    movw %ax,   %gs:(%edi)

1:                                  
    incl    %eax                    # 经过不明所以的设置之后（目前还是不明所以的设置，后续可能会更清楚一点。）
    movl    %eax,0x000000
    cmpl    %eax,0x100000
    je      1b                      # 如果两数相等，跳转到1的位置，这个b指的是back，意思是要向后（向上）寻找。如果是向前（向下）寻找，需要je 1f
                                    # 总之，这是一个使用循环的手法。之后还会遇到。

                                    # 我们的目标最终在这里
    jmp after_page_tables           # 最终准备进入到页表设置的环节。
                                    # 设置完页表之后，最终可以进入main()函数。好吧，main()函数总算要来了。

setup_idt:
    leal ignore_int,%edx
    movl $0x00080000,%eax
    movw %dx,%ax
    movw $0x8e00,%dx
    leal idt,%edi
    movl $256,%ecx

rp_sidt:
    movl %eax,  (%edi)
    movl %edx,  4(%edi)
    addl $8,    %edi 
    decl %ecx
    jne rp_sidt
    lidt idt_descr
    ret

setup_gdt:
    lgdt gdt_descr
    ret
                                    # 我们把页目录（pg_dir）表放在了地址0x0，这个pg_dir会占用4KB，也就是4096 Byte （0x1000 Byte）,它会覆盖 0x0 到 0x999 的地址。
                                    # 因此，页表就只能从0x1000开始了。
                    
.org 0x1000                         # 每个页表也占用4KB
pg0:
.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000

tmp_floppy_area:                    # 这个好像是虚拟软盘，不知道有什么用，等下再处理
.fill   1024,1,0

after_page_tables:
    
    pushl   $0
    pushl   $0
    pushl   $0
    pushl   $L6
    pushl   $main                           # 以push的手法往栈上存了一个符号。后续我们可以通过该符号跳转到main函数 
    jmp     setup_paging    # 配置页表

L6:
    jmp     L6                              # 老样子，完成一切任务之后，使用无限循环伺候


                                            # 在继续下去之前，我觉得有必要论述一下32位Linux系统究竟是如何管理4G内存的。
                                            # 对于我们要处理的32位Linux操作系统来说，为了支持4个GB（4 * 1024 * 1024 * 1024 Byte）的存储空间，只需要使用二级页表就可以了。
                                            # 首先，页目录表将会存储1024个页表的地址，每个页表的地址占据4Byte。显然，只需每个页表管理好 4 * 1024 * 1024 Byte ，也就是4MB的内存就可以了。
                                            # 我们会在接下来的函数中，看见一个页表如何管理4MB内存。
setup_paging:
    movl    $1024*5,    %ecx
    xorl    %eax,   %eax
    xorl    %edi,   %edi
    cld                                     # 清除CF进位。这样一来，其它寄存器才能按需运作。（比如 di si 这两个地址指针）
    rep
    stosl                                   # stosl指令相当于把eax中的值保存到es:edi指向的地址中，若设置了方向位置位(即在stosl指令前使用std指令让DF=1),则edi自减4，若是用过cld指令，那么就会导致edi自增4。
                                            # 上述内容本质上是在设置内存值为0(即所为的初始化)，确保页表是全新的，里面没有任何“残留数据”。

                                            # 分别存储4个页表的地址到pg_dir内
    movl    $pg0+7, pg_dir                  # 我们首先存储了地址，其次让这个地址+7，这样一来，结果尾部的二进制表示就是111，说明这个页表是用户态可读，可写，并且在内存中存在。
    movl    $pg1+7, pg_dir + 4              
    movl    $pg2+7, pg_dir + 8
    movl    $pg3+7, pg_dir + 12
                                            
                                            # $pg3+4092 是页表最后一项的地址，它占据4个Byte。我们现在要覆盖页表中的每一项，就从最后一项开始执行循环。
    movl    $pg3+4092, %edi                 # 设置目标写入位置
    movl    $0xfff007, %eax                 # 设置要写入的数据，这是一个地址。 0xfff000 + 7,和刚才的需求相同，最后的7是为了设置页表权限。
                                            # $0xfff000 是页的开始地址，这一页的结束地址是 $0xfff000 + 0x1000 = 0x1000000 (16MB内存地址的末尾)
    std
1:
    stosl                                   # 把eax寄存器的值写入es:edi。
    subl $0x1000,%eax                       # 因为之前设置了std，导致每次执行后edi会自减4，所以%eax的值也需要减少。
                                            # 每个页表能管理4KB内存。
    jge 1b
                                            # 因为4张页表都是连在一起的，所以这个循环可以一次性设置4张页表。这样一来,前16MB的内存就都被我们管理起来了。

    xorl    %eax,%eax                       # 这一步步是为了开启CPU的分页管理
    movl    %eax,%cr3                       #
    movl    %cr0,%eax                       #
    orl $0x80000000,%eax                    #
    movl    %eax,%cr0                       # 

    ret

ignore_int:
    # 我们现在还没有print函数，通过直接向显存写入字符来模拟它
    pushl   %eax
    pushl   %ecx
    pushl   %edx
    pushw   %ds
    pushw   %es
    pushw   %fs
    movl    $0x10,  %eax
    movw    %ax,    %ds
    movw    %ax,    %es
    movw    %ax,    %fs

    movl    $0x96,  %edi
    movb    $'I',   %al
    movb    $0x0c,  %ah
    movw    %ax,   %gs:(%edi)

    popw    %fs
    popw    %es
    popw    %ds

    popl    %edx
    popl    %ecx
    popl    %eax

    iret

set_clock_idt:
    leal clock_handle,  %edx
    movl $0x00080000,   %eax
    movw %dx,   %ax
    movw $0x8e00,   %dx
    leal idt,   %edi
    addl $0x100,    %edi
    movl %eax,  (%edi)
    movl %edx,  4(%edi)
    ret

clock_handle:
    movl $0x96,%edi
    incb %gs:(%edi)

    movb $0x20,%al
    outb %al,$0x20
    iret

.align 4
.word 0

gdt_descr:
    .word 256*8-1
    .long gdt

idt_descr:
    .word 256*8-1
    .long idt


idt:
    .fill 256,8,0
.align 8
gdt:
    .quad 0x0000000000000000    #4个Byte，第一个gdt不使用
    .quad 0x00c09a0000000fff
    .quad 0x00c0920000000fff
    .quad 0x00c0f20b8000ffff
    .quad 0x0000000000000000
    .fill 251,8,0
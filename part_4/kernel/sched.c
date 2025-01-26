#define PAGE_SIZE 4096

long user_stack[PAGE_SIZE >> 2];

//在32位Linux平台上，long是4个Byte。所以user_stack一共占据  4 * 1024 个 Byte,刚好是一个内存页的大小。

struct{
    long    *a;     //在32位架构下，任何类型的指针都是4个Byte
    short   b;      //2个Byte
} stack_start = { &user_stack[PAGE_SIZE >> 2],0x10 };

/*
    关于栈，首先要明白，在目前的OS设计中，任何一个进程都要用到栈(stack)结构。
    栈本质是一个数组，在逻辑上，栈的元素是后进先出，除此之外没有任何特别之处。
    所以，栈只是简单的一段内存而已。

    SS, SP, BP 三个寄存器是用于描述栈的寄存器。
    SS是栈的段地址，SP是栈顶指针（永远指向栈的顶端）。SS:SP永远指栈顶的真实物理地址。
    BP是一个备用的寄存器，如果想要读取栈的数据，又不想破坏栈顶指针SP，那么可以把SP的值复制一份给BP，用SS:BP的手法来进行处理。
*/
/*
    user_stack是一段内存，它的大小是4KB。我们现在要把它作为初始进程的栈。
    我们需要让SS:SP指向这个数组的尾部元素。因为86的栈是向下增长的，所以要把数组的末尾作为栈顶（一开始栈顶 和 栈底是同一个地方），随着入栈元素越来越多，新元素会越来越接近于数组的下标0位置。

    接下来的重点就在于这个x10。
    目前我们已经进入了保护模式，所以段寄存器的值一律要经过gdt的处理才能转换成真实地址。
    user_stack这个数组实际上是代码的一部分，它属于代码段。所以，我们要让SS = 代码段的段基地址。对应的选择子就是0x10。

    而栈底元素可以设置为该数组的末尾元素。

    我们会进行堆栈检查，只要超过了数组范围，就进行报错。
    这样一来，无论这个数组被编译到什么地方，我们都能将其当作栈来使用。
    （目前还没有相关的检查代码，但是我看差不多会提上日程了。）
*/
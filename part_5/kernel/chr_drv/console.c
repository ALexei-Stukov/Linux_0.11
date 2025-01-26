// 借用一下include目录的代码。
#include <linux/tty.h>

// 我们读取了很多硬件信息，全都存在诸如0x90000这样的位置，现在是时候启用它们了。
#define ORIG_X          (*(unsigned char *)0x90000)
#define ORIG_Y          (*(unsigned char *)0x90001)
#define ORIG_VIDEO_PAGE     (*(unsigned short *)0x90004)
#define ORIG_VIDEO_MODE     ((*(unsigned short *)0x90006) & 0xff)
#define ORIG_VIDEO_COLS     (((*(unsigned short *)0x90006) & 0xff00) >> 8)
#define ORIG_VIDEO_LINES    ((*(unsigned short *)0x9000e) & 0xff)
#define ORIG_VIDEO_EGA_AX   (*(unsigned short *)0x90008)
#define ORIG_VIDEO_EGA_BX   (*(unsigned short *)0x9000a)
#define ORIG_VIDEO_EGA_CX   (*(unsigned short *)0x9000c)

#define VIDEO_TYPE_MDA      0x10    /* Monochrome Text Display  */
#define VIDEO_TYPE_CGA      0x11    /* CGA Display          */
#define VIDEO_TYPE_EGAM     0x20    /* EGA/VGA in Monochrome Mode   */
#define VIDEO_TYPE_EGAC     0x21    /* EGA/VGA in Color Mode    */

static unsigned char    video_type;     /* Type of display being used   */
static unsigned long    video_num_columns;  /* Number of text columns   */
static unsigned long    video_num_lines;    /* Number of test lines     */
static unsigned long    video_mem_start;     /* Base of video memory     */
static unsigned long    video_mem_term;     /* End of video memory      */
static unsigned long    video_size_row;     /* Bytes per row        */
static unsigned char    video_page;     /* Initial video page       */
static unsigned short   video_port_reg;     /* Video register select port   */
static unsigned short   video_port_val;     /* Video register value port    */

void con_init(){
    char * display_desc = "????";
    char * display_ptr;

    video_num_columns   =   ORIG_VIDEO_COLS;
    video_size_row      =   video_num_columns * 2;
    
    video_num_lines     =   ORIG_VIDEO_LINES;
    video_page          =   ORIG_VIDEO_PAGE;

    /*因为目前单色显示器几乎绝迹，所以相关的代码被删掉了*/
    if (ORIG_VIDEO_MODE == 7){

    }
    else { /*color display*/
        video_mem_start  =   0xb8000;
        video_port_reg  =   0x3d4;
        video_port_val  =   0x3d5;

        if ((ORIG_VIDEO_EGA_BX & 0xff) != 0x10) {
            video_type  =   VIDEO_TYPE_EGAC;
            video_mem_term  =   0xc0000;
            display_desc    =   "EGAc\0";   //"EGAc"其实也行，但我选择补一个\0防止意外。
        }
        else{
            /*qemu和bochs采用了EGA彩色模式*/
            //先不考虑其他情况
        }
    }

    display_ptr =   ((char*)video_mem_start) + video_size_row - 8;
    while(*display_desc) {
        // 这个写法是不是太狂野了
        // *display_ptr++ = *display_desc++;
        // *display_ptr++;

        *display_ptr = *display_desc;
        display_ptr += 2;
        display_desc += 1;
    }
}
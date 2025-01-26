#ifndef _SEGMENT_H
#define _SEGMENT_H

inline unsigned char get_fs_byte(const char * addr);

inline void put_fs_byte(char val,char *addr);

inline void put_fs_word(short val, short * addr) ;

inline unsigned long get_fs_long(const unsigned long *addr) ;

inline void put_fs_long(unsigned long val,unsigned long * addr) ;

inline unsigned long get_fs();

inline unsigned long get_ds();

inline void set_fs(unsigned long val);

#endif


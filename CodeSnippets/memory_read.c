//
//  main.c
//  MemoryRead
//
//  Created by jiaxw on 2021/6/11.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "inttypes.h"


int main(int argc, const char * argv[]) {
    // insert code here...
    void *ptr = main;
    size_t size = 4;
    
    void *buffer = malloc(size);
    memcpy(buffer, ptr, size);
    uintptr_t var = *(unsigned long *)buffer;
    printf("0x%" PRIxPTR "\n", var);
    
    memcpy(buffer, (void *)((uintptr_t)ptr + 4), size);
    var = *(unsigned long *)buffer;
    printf("0x%" PRIxPTR "\n", var);

//        printf("%lu", var);
    
    return 0;
}



/*
 
 (lldb) memory read --format x --size 8 0x000000016d2274a0
 0x16d2274a0: 0x0000000283861ba0 0x673a610196cb0650
 0x16d2274b0: 0x0000000283861ba0 0x0000000283861ba8
 0x16d2274c0: 0x00000001d0903a88 0x0000000283a476d8
 0x16d2274d0: 0x00000001095b7ef9 0x00000001d0eba388
 (lldb) p/x 0x0000000283861ba0+0x68
 (long) $0 = 0x0000000283861c08
 
 (lldb) memory read --format x --size 8 0x0000000283861c08
 0x283861c08: 0x000000011a3204f0 0x0000000000000000
 0x283861c18: 0x0000000000000000 0x0000000000000000
 0x283861c28: 0x0000000000000000 0x0000000000000000
 0x283861c38: 0x0000000000000000 0x0000000000000000
 (lldb) p/x 0x000000011a3204f0+0xe0
 (long) $2 = 0x000000011a3205d0

 (lldb) memory read --format x --size 8 0x000000011a3205d0
 0x11a3205d0: 0x0006000047757717 0x0000000000000001
 0x11a3205e0: 0x000000000a000940 0x0000000100000000
 0x11a3205f0: 0x00070000101b59be 0x0000000000000000
 0x11a320600: 0x0000000000000000 0x0000000000000000
 (lldb) p 0x0006000047757717
 (long) $4 = 1688851059144471
 */

#define _QWORD uint64

void read_memory(void *addr){
    //uid = *(_QWORD *)(*(_QWORD *)(*(_QWORD *)arg + 104LL) + 224LL);
    
    void *ptr = addr;
    size_t size = 8;
    
    void *buffer = malloc(size);
    memcpy(buffer, ptr, size);
    uintptr_t var0 = *(unsigned long *)buffer;
    
    var0 += 0x68;
    memcpy(buffer, (void *)var0, size);
    uintptr_t var1 = *(unsigned long *)buffer;
    
    var1 += 0xe0;
    memcpy(buffer, (void *)var1, size);
    unsigned long uid = *(unsigned long *)buffer;
    
    printf("%lu", uid);
    free(buffer);
}

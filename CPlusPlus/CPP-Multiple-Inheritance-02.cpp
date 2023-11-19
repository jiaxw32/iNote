#include <iostream>

class A
{
public:
    void foo() {}
    int var_a;
};

class B
{
public:
    virtual void bar() {}
    int var_b;
};

class C : public A, public B
{
public:
    virtual void barz() {}
    int var_c;
};

int main()
{
    C *ptrC = new C();
    ptrC->var_a = 0xaa;
    ptrC->var_b = 0xbb;
    ptrC->var_c = 0xcc;

    std::cout << "size of Class C: " << sizeof(*ptrC) << std::endl;

    return 0;
}


/*

clang -cc1 -fdump-record-layouts ./CPP-Multiple-Inheritance-02.cpp

// Class memory layout

*** Dumping AST Record Layout
         0 | class A
         0 |   int var_a
           | [sizeof=4, dsize=4, align=4,
           |  nvsize=4, nvalign=4]

*** Dumping AST Record Layout
         0 | class B
         0 |   (B vtable pointer)
         8 |   int var_b
           | [sizeof=16, dsize=12, align=8,
           |  nvsize=12, nvalign=8]

*** Dumping AST Record Layout
         0 | class C
         0 |   class B (primary base)
         0 |     (B vtable pointer)
         8 |     int var_b
        12 |   class A (base)
        12 |     int var_a
        16 |   int var_c
           | [sizeof=24, dsize=20, align=8,
           |  nvsize=20, nvalign=8]

================================================================================================

// 编码源文件，使用 lldb 调试
clang++ -std=c++20 -stdlib=libc++ -g ./CPP-Multiple-Inheritance-02.cpp && lldb ./a.out

// class C 实例大小
(lldb) p sizeof(*ptrC)
(unsigned long) $1 = 24

(lldb) p/x ptrC
(C *) $2 = 0x0000600000208000

// 读取 Class C 内存数据
(lldb) x -fx -s8 -c3 0x0000600000208000
0x600000208000: 0x00000001000040f8 0x000000aa000000bb
0x600000208010: 0x00000000000000cc

// C Class vtable 镜像信息
(lldb) image lookup -va 0x00000001000040f8
      Address: a.out[0x00000001000040f8] (a.out.__DATA_CONST.__const + 16)
      Summary: a.out`vtable for C + 16
      Symbol: id = {0x00000114}, range = [0x00000001000040e8-0x0000000100004108), name="vtable for C", mangled="_ZTV1C"

// Class C vtable 大小
(lldb) p 0x0000000100004108-0x00000001000040e8
(long) $3 = 32

// Class C vtable 内存数据
(lldb) x -fx -s8 -c4 0x00000001000040e8
0x1000040e8: 0x0000000000000000 0x0000000100004128
0x1000040f8: 0x00000001000031f4 0x0000000100003204

// function pointer to B::bar()
(lldb) image lookup -a 0x00000001000031f4
      Address: a.out[0x00000001000031f4] (a.out.__TEXT.__text + 508)
      Summary: a.out`B::bar() at CPP-Multiple-Inheritance-02.cpp:13

// function pointer to C::barz()
(lldb) image lookup -a 0x0000000100003204
      Address: a.out[0x0000000100003204] (a.out.__TEXT.__text + 524)
      Summary: a.out`C::barz() at CPP-Multiple-Inheritance-02.cpp:20

// C typeinfo 信息
(lldb) image lookup -va 0x0000000100004128
      Address: a.out[0x0000000100004128] (a.out.__DATA_CONST.__const + 64)
      Summary: a.out`typeinfo for C
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x00000117}, range = [0x0000000100004128-0x0000000100004160), name="typeinfo for C", mangled="_ZTI1C"

// C typeinfo 大小
(lldb) p 0x0000000100004160-0x0000000100004128
(long) $4 = 56

// C class typeinfo 内存数据
(lldb) x -fx -s8 0x0000000100004128
0x100004128: 0x0000000202659380 0x8000000100003eae
0x100004138: 0x0000000200000000 0x0000000100004108
0x100004148: 0x0000000000000c02 0x0000000100004118
0x100004158: 0x0000000000000002

// C class typeinfo 类型
(lldb) image lookup -a 0x0000000202659380
      Address: libc++abi.dylib[0x00000001dd389380] (libc++abi.dylib.__AUTH_CONST.__const + 12224)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__vmi_class_type_info + 16

// 类名称
(lldb) p/c (char *)0x000000100003eae
(char *) $5 = \xae>\0\0\x01\0\0\0 "1C"

// typeinfo for A
(lldb) image lookup -va 0x0000000100004108
      Address: a.out[0x0000000100004108] (a.out.__DATA_CONST.__const + 32)
      Summary: a.out`typeinfo for A
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x00000115}, range = [0x0000000100004108-0x0000000100004118), name="typeinfo for A", mangled="_ZTI1A"

// A typeinfo memory
(lldb) x -fx -s8 -c2 0x0000000100004108
0x100004108: 0x00000002026592b0 0x8000000100003eb1

// A class typeinfo 类型
(lldb) image lookup -a 0x00000002026592b0
      Address: libc++abi.dylib[0x00000001dd3892b0] (libc++abi.dylib.__AUTH_CONST.__const + 12016)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__class_type_info + 16

// type name
(lldb) p/c (char *)0x000000100003eb1
(char *) $6 = \xb1>\0\0\x01\0\0\0 "1A"

// typeinfo for B
(lldb) image lookup -a 0x0000000100004118
      Address: a.out[0x0000000100004118] (a.out.__DATA_CONST.__const + 48)
      Summary: a.out`typeinfo for B

// B typeinfo memory
(lldb) x -fx -s8 -c2 0x0000000100004118
0x100004118: 0x00000002026592b0 0x8000000100003eb4

// B class typeinfo 类型
(lldb) image lookup -a 0x00000002026592b0
      Address: libc++abi.dylib[0x00000001dd3892b0] (libc++abi.dylib.__AUTH_CONST.__const + 12016)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__class_type_info + 16

// type name
(lldb) p/c (char *)0x000000100003eb4
(char *) $7 = \xb4>\0\0\x01\0\0\0 "1B"

*/
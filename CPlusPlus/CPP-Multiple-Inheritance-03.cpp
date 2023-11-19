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
    void bar() {}
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

    return 0;
}


/*

clang -cc1 -fdump-record-layouts ./CPP-Multiple-Inheritance-03.cpp

// Class memory layout

*** Dumping AST Record Layout
         0 | class A
         0 |   int var_a
           | [sizeof=4, dsize=4, align=4,
           |  nvsize=4, nvalign=4]

*** Dumping AST Record Layout
         0 | class B
         0 |   int var_b
           | [sizeof=4, dsize=4, align=4,
           |  nvsize=4, nvalign=4]

*** Dumping AST Record Layout
         0 | class C
         0 |   (C vtable pointer)
         8 |   class A (base)
         8 |     int var_a
        12 |   class B (base)
        12 |     int var_b
        16 |   int var_c
           | [sizeof=24, dsize=20, align=8,
           |  nvsize=20, nvalign=8]

================================================================================================

// 编码源文件，使用 lldb 调试
clang++ -std=c++20 -stdlib=libc++ -g ./CPP-Multiple-Inheritance-03.cpp && lldb ./a.out


(lldb) p/x ptrC
(C *) $0 = 0x0000600000204000
(lldb) p sizeof(*ptrC)
(unsigned long) $1 = 24
(lldb) x -fx -s8 -c3 0x0000600000204000
0x600000204000: 0x00000001000040f0 0x000000bb000000aa
0x600000204010: 0x00000000000000cc

(lldb) image lookup -va 0x00000001000040f0
      Address: a.out[0x00000001000040f0] (a.out.__DATA_CONST.__const + 16)
      Summary: a.out`vtable for C + 16
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x00000109}, range = [0x00000001000040e0-0x00000001000040f8), name="vtable for C", mangled="_ZTV1C"

(lldb) p 0x00000001000040f8-0x00000001000040e0
(long) $2 = 24

(lldb) x -fx -s8 -c3 0x00000001000040e0
0x1000040e0: 0x0000000000000000 0x0000000100004118
0x1000040f0: 0x0000000100003204

(lldb) image lookup -a 0x0000000100003204
      Address: a.out[0x0000000100003204] (a.out.__TEXT.__text + 440)
      Summary: a.out`C::barz() at CPP-Multiple-Inheritance-03.cpp:20

(lldb) image lookup -va 0x0000000100004118
      Address: a.out[0x0000000100004118] (a.out.__DATA_CONST.__const + 56)
      Summary: a.out`typeinfo for C
      Symbol: id = {0x0000010c}, range = [0x0000000100004118-0x0000000100004150), name="typeinfo for C", mangled="_ZTI1C"

(lldb) p 0x0000000100004150-0x0000000100004118
(long) $3 = 56

(lldb) x -fx -s8 -c7 0x0000000100004118
0x100004118: 0x0000000202659380 0x8000000100003eae
0x100004128: 0x0000000200000000 0x00000001000040f8
0x100004138: 0x0000000000000802 0x0000000100004108
0x100004148: 0x0000000000000c02

(lldb) image lookup -a 0x0000000202659380
      Address: libc++abi.dylib[0x00000001dd389380] (libc++abi.dylib.__AUTH_CONST.__const + 12224)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__vmi_class_type_info + 16

(lldb) p/c (char *)0x000000100003eae
(char *) $4 = \xae>\0\0\x01\0\0\0 "1C"

(lldb) image lookup -a 0x00000001000040f8
      Address: a.out[0x00000001000040f8] (a.out.__DATA_CONST.__const + 24)
      Summary: a.out`typeinfo for A

(lldb) image lookup -a 0x0000000100004108
      Address: a.out[0x0000000100004108] (a.out.__DATA_CONST.__const + 40)
      Summary: a.out`typeinfo for B

*/
#include <iostream>

class A
{
public:
    virtual void foo() {}
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
    void bar() override {}
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

clang -cc1 -fdump-record-layouts ./CPP-Multiple-Inheritance-04.cpp

// Class memory layout

*** Dumping AST Record Layout
         0 | class A
         0 |   (A vtable pointer)
         8 |   int var_a
           | [sizeof=16, dsize=12, align=8,
           |  nvsize=12, nvalign=8]

*** Dumping AST Record Layout
         0 | class B
         0 |   (B vtable pointer)
         8 |   int var_b
           | [sizeof=16, dsize=12, align=8,
           |  nvsize=12, nvalign=8]

*** Dumping AST Record Layout
         0 | class C
         0 |   class A (primary base)
         0 |     (A vtable pointer)
         8 |     int var_a
        16 |   class B (base)
        16 |     (B vtable pointer)
        24 |     int var_b
        28 |   int var_c
           | [sizeof=32, dsize=32, align=8,
           |  nvsize=32, nvalign=8]

================================================================================================

// 编码源文件，使用 lldb 调试
clang++ -std=c++20 -stdlib=libc++ -g ./CPP-Multiple-Inheritance-04.cpp && lldb ./a.out



(lldb) p/x ptrC
(C *) $0 = 0x0000600000208000
(lldb) p sizeof(*ptrC)
(unsigned long) $1 = 32

// memory of *ptrC
(lldb) x -fx -s8 -c4 0x0000600000208000
0x600000208000: 0x0000000100004030 0x00000000000000aa
0x600000208010: 0x0000000100004050 0x000000cc000000bb

// lookup vtable image info
(lldb) image lookup -va 0x0000000100004030
      Address: a.out[0x0000000100004030] (a.out.__DATA_CONST.__const + 16)
      Summary: a.out`vtable for C + 16
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000003c}, range = [0x0000000100004020-0x0000000100004058), name="vtable for C", mangled="_ZTV1C"

(lldb) image lookup -va 0x0000000100004050
      Address: a.out[0x0000000100004050] (a.out.__DATA_CONST.__const + 48)
      Summary: a.out`vtable for C + 48
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000003c}, range = [0x0000000100004020-0x0000000100004058), name="vtable for C", mangled="_ZTV1C"

// vtable size
(lldb) p 0x0000000100004058-0x0000000100004020
(long) $2 = 56

// vtable memory
(lldb) x -fx -s8 0x0000000100004020
0x100004020: 0x0000000000000000 0x0000000100004078
0x100004030: 0x0000000100003f50 0x0000000100003f60
0x100004040: 0xfffffffffffffff0 0x0000000100004078
0x100004050: 0x0000000100003f70 0x00000002026592b0

// typeinfo for C
(lldb) image lookup -va 0x0000000100004078
      Address: a.out[0x0000000100004078] (a.out.__DATA_CONST.__const + 88)
      Summary: a.out`typeinfo for C
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000003f}, range = [0x0000000100004078-0x00000001000040b0), name="typeinfo for C", mangled="_ZTI1C"

// typeinfo size
(lldb) p 0x00000001000040b0 - 0x0000000100004078
(long) $3 = 56

// A::foo()
(lldb) image lookup -a 0x0000000100003f50
      Address: a.out[0x0000000100003f50] (a.out.__TEXT.__text + 324)
      Summary: a.out`A::foo() at CPP-Multiple-Inheritance-04.cpp:6

// C::bar()
(lldb) image lookup -a 0x0000000100003f60
      Address: a.out[0x0000000100003f60] (a.out.__TEXT.__text + 340)
      Summary: a.out`C::bar() at CPP-Multiple-Inheritance-04.cpp:20

// non-virtual thunk to C::bar()
(lldb) image lookup -va 0x0000000100003f70
      Address: a.out[0x0000000100003f70] (a.out.__TEXT.__text + 356)
      Summary: a.out`non-virtual thunk to C::bar() at CPP-Multiple-Inheritance-04.cpp
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
  CompileUnit: id = {0x00000000}, file = "/Users/admin/Desktop/CPP-Multiple-Inheritance-04.cpp", language = "c++14"
     Function: id = {0x000021d8}, name = "non-virtual thunk to C::bar()", mangled = "_ZThn16_N1C3barEv", range = [0x0000000100003f70-0x0000000100003f88)
     FuncType: id = {0x000021d8}, byte-size = 0, decl = CPP-Multiple-Inheritance-04.cpp:20, compiler_type = "void (void)"
       Blocks: id = {0x000021d8}, range = [0x100003f70-0x100003f88)
    LineEntry: [0x0000000100003f70-0x0000000100003f88): /Users/admin/Desktop/CPP-Multiple-Inheritance-04.cpp
       Symbol: id = {0x00000032}, range = [0x0000000100003f70-0x0000000100003f88), name="non-virtual thunk to C::bar()", mangled="_ZThn16_N1C3barEv"

(lldb) dis -s 0x0000000100003f70 -e 0x0000000100003f88
a.out`non-virtual thunk to C::bar():
    0x100003f70 <+0>:  sub    sp, sp, #0x10
    0x100003f74 <+4>:  str    x0, [sp, #0x8]
    0x100003f78 <+8>:  ldr    x8, [sp, #0x8]
    0x100003f7c <+12>: subs   x0, x8, #0x10
    0x100003f80 <+16>: add    sp, sp, #0x10
    0x100003f84 <+20>: b      0x100003f60               ; C::bar at CPP-Multiple-Inheritance-04.cpp:20

// the memory of typeinfo for C
(lldb) x -fx -s8 0x0000000100004078
0x100004078: 0x0000000202659380 0x8000000100003fa4
0x100004088: 0x0000000200000000 0x0000000100004058
0x100004098: 0x0000000000000002 0x0000000100004068
0x1000040a8: 0x0000000000001002 0x0000000000000000

// typeinfo type
(lldb) image lookup -a 0x0000000202659380
      Address: libc++abi.dylib[0x00000001dd389380] (libc++abi.dylib.__AUTH_CONST.__const + 12224)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__vmi_class_type_info + 16
(lldb) p/c (char *)0x000000100003fa4
(char *) $4 = \xa4?\0\0\x01\0\0\0 "1C"

// base class typeinfo
(lldb) image lookup -a 0x0000000100004058
      Address: a.out[0x0000000100004058] (a.out.__DATA_CONST.__const + 56)
      Summary: a.out`typeinfo for A
(lldb) image lookup -a 0x0000000100004068
      Address: a.out[0x0000000100004068] (a.out.__DATA_CONST.__const + 72)
      Summary: a.out`typeinfo for B
*/
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

clang -cc1 -fdump-record-layouts ./Multiple-Inheritance-vtable.cpp

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
clang++ -std=c++20 -stdlib=libc++ -g ./Single-Inheritance-vtable.cpp && lldb ./a.out

(lldb) expression sizeof(*ptrC)
(unsigned long) $1 = 32

(lldb) p/x ptrC
(C *) $2 = 0x0000600000208000

(lldb) x -fx -s8 -c4 0x0000600000208000
0x600000208000: 0x0000000100004100 0x00000000000000aa
0x600000208010: 0x0000000100004120 0x000000cc000000bb
(lldb) x -fx -s4 -c2 0x600000208008
0x600000208008: 0x000000aa 0x00000000
(lldb) x -fx -s4 -c2 0x600000208018
0x600000208018: 0x000000bb 0x000000cc

(lldb) image lookup -va 0x0000000100004100
      Address: a.out[0x0000000100004100] (a.out.__DATA_CONST.__const + 16)
      Summary: a.out`vtable for C + 16
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011f}, range = [0x00000001000040f0-0x0000000100004128), name="vtable for C", mangled="_ZTV1C"

(lldb) image lookup -va 0x0000000100004120
      Address: a.out[0x0000000100004120] (a.out.__DATA_CONST.__const + 48)
      Summary: a.out`vtable for C + 48
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011f}, range = [0x00000001000040f0-0x0000000100004128), name="vtable for C", mangled="_ZTV1C"

(lldb) p 0x0000000100004128 - 0x00000001000040f0
(long) $3 = 56

(lldb) x -fx -s8 -c7 0x00000001000040f0
0x1000040f0: 0x0000000000000000 0x0000000100004148
0x100004100: 0x00000001000031e4 0x00000001000031f4
0x100004110: 0xfffffffffffffff0 0x0000000100004148
0x100004120: 0x0000000100003204

(lldb) image lookup -va 0x0000000100004148
      Address: a.out[0x0000000100004148] (a.out.__DATA_CONST.__const + 88)
      Summary: a.out`typeinfo for C
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x00000122}, range = [0x0000000100004148-0x0000000100004180), name="typeinfo for C", mangled="_ZTI1C"

(lldb) image lookup -a 0x00000001000031e4
      Address: a.out[0x00000001000031e4] (a.out.__TEXT.__text + 572)
      Summary: a.out`A::foo() at Multiple-Inheritance-vtable.cpp:6
(lldb) image lookup -a 0x00000001000031f4
      Address: a.out[0x00000001000031f4] (a.out.__TEXT.__text + 588)
      Summary: a.out`C::barz() at Multiple-Inheritance-vtable.cpp:20
(lldb) image lookup -a 0x0000000100003204
      Address: a.out[0x0000000100003204] (a.out.__TEXT.__text + 604)
      Summary: a.out`B::bar() at Multiple-Inheritance-vtable.cpp:13

(lldb) p 0x0000000100004180-0x0000000100004148
(long) $4 = 56

(lldb) x -fx -s8 -c7 0x0000000100004148
0x100004148: 0x0000000202659380 0x8000000100003eae
0x100004158: 0x0000000200000000 0x0000000100004128
0x100004168: 0x0000000000000002 0x0000000100004138
0x100004178: 0x0000000000001002

(lldb) image lookup -a 0x0000000202659380
      Address: libc++abi.dylib[0x00000001dd389380] (libc++abi.dylib.__AUTH_CONST.__const + 12224)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__vmi_class_type_info + 16
(lldb) p/c (char *)0x000000100003eae
(char *) $6 = \xae>\0\0\x01\0\0\0 "1C"

(lldb) image lookup -a 0x0000000100004128
      Address: a.out[0x0000000100004128] (a.out.__DATA_CONST.__const + 56)
      Summary: a.out`typeinfo for A
(lldb) image lookup -a 0x0000000100004138
      Address: a.out[0x0000000100004138] (a.out.__DATA_CONST.__const + 72)
      Summary: a.out`typeinfo for B

(lldb) script
Python Interactive Interpreter. To exit, type 'quit()', 'exit()' or Ctrl-D.
>>> 0x0000000000001002 >> 8
16
*/
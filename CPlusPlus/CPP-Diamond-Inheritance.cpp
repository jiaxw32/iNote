#include <iostream>

class A
{
public:
    virtual void foo() {}
    int var_a;
};

class B: virtual public A
{
public:
    virtual void bar() {}
    int var_b;
};

class C : virtual public A
{
public:
    virtual void barz() {}
    int var_c;
};

class D : public B, public C
{
public:
    virtual void foobar() {}
    int var_d;
};

int main()
{
    D *ptrD = new D();
    ptrD->var_a = 0xaa;
    ptrD->var_b = 0xbb;
    ptrD->var_c = 0xcc;
    ptrD->var_d = 0xdd;

    std::cout << "size of D: %d" << sizeof(*ptrD) << std::endl;

    return 0;
}


/*

clang -cc1 -fdump-record-layouts ./CPP-Diamond-Inheritance.cpp

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
        16 |   class A (virtual base)
        16 |     (A vtable pointer)
        24 |     int var_a
           | [sizeof=32, dsize=28, align=8,
           |  nvsize=12, nvalign=8]

*** Dumping AST Record Layout
         0 | class C
         0 |   (C vtable pointer)
         8 |   int var_c
        16 |   class A (virtual base)
        16 |     (A vtable pointer)
        24 |     int var_a
           | [sizeof=32, dsize=28, align=8,
           |  nvsize=12, nvalign=8]

*** Dumping AST Record Layout
         0 | class D
         0 |   class B (primary base)
         0 |     (B vtable pointer)
         8 |     int var_b
        16 |   class C (base)
        16 |     (C vtable pointer)
        24 |     int var_c
        28 |   int var_d
        32 |   class A (virtual base)
        32 |     (A vtable pointer)
        40 |     int var_a
           | [sizeof=48, dsize=44, align=8,
           |  nvsize=32, nvalign=8]

================================================================================================

// 编码源文件，使用 lldb 调试
clang++ -std=c++20 -stdlib=libc++ -g ./CPP-Diamond-Inheritance.cpp && lldb ./a.out



*/
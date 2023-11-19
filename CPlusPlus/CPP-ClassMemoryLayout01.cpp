#include <iostream>
using namespace std;

class NonVirtualClass
{
public:
    void foo() {}
};

class VirtualClass
{
public:
    virtual void foo() {}
};

int main()
{
    // int size = sizeof(NonVirtualClass);
    // size = sizeof(VirtualClass);

    cout << "Size of NonVirtualClass: " << sizeof(NonVirtualClass) << endl;
    cout << "Size of VirtualClass: " << sizeof(VirtualClass) << endl;
    return 0;
}

/*
// 编译并运行 ClassMemoryLayout01.cpp
$ clang++ ./ClassMemoryLayout01.cpp && ./a.out

// 输出结果如下:
Size of NonVirtualClass: 1
Size of VirtualClass: 8

// 使用 clang dump ClassMemoryLayout01 内存布局
$ clang -cc1 -fdump-record-layouts ./ClassMemoryLayout01.cpp

// 输出结果如下
*** Dumping AST Record Layout
         0 | class NonVirtualClass (empty)
           | [sizeof=1, dsize=1, align=1,
           |  nvsize=1, nvalign=1]

*** Dumping AST Record Layout
         0 | class VirtualClass
         0 |   (VirtualClass vtable pointer)
           | [sizeof=8, dsize=8, align=8,
           |  nvsize=8, nvalign=8]
*/
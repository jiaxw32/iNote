#include <iostream>

class Parent
{
public:
    virtual void Foo() {}
    virtual void FooNotOverridden() {}
};

class Derived : public Parent
{
public:
    void Foo() override {}
};

int main()
{
    // std::cout << __cplusplus << std::endl;

    Parent *p1 = new Parent();
    Parent *p2 = new Parent();
    std::cout << "size of Parent: " << sizeof(*p1) << std::endl;
    
    Parent *d1 = new Derived();
    Parent *d2 = new Derived();
    std::cout << "size of Derived: " << sizeof(*p1) << std::endl;
}

/*

// 编译源文件并运行
clang++ -std=c++20 -stdlib=libc++ -g ./Single-Inheritance-vtable.cpp && ./a.out

// 编码源文件，使用 lldb 调试
clang++ -std=c++20 -stdlib=libc++ -g ./Single-Inheritance-vtable.cpp && lldb ./a.out

// -g 选项说明
-g Generate source-level debug information

================================================================================================

// Derived 内存及 vtable 信息

// 查看 Parent 类大小
(lldb) expression sizeof(*p1)
(unsigned long) $0 = 8

(lldb) p/x p1
(Parent *) $1 = 0x0000600000008000
(lldb) p/x p2
(Parent *) $2 = 0x0000600000008010

// 查看 p1、p2 内存
(lldb) x -fx -s8 -c1 0x0000600000008000
0x600000008000: 0x00000001000040f8
(lldb) x -fx -s8 -c1 0x0000600000008010
0x600000008010: 0x00000001000040f8

================================================================================================

// 查看 Parent vtable 镜像信息
(lldb) image lookup -va 0x00000001000040f8
      Address: a.out[0x00000001000040f8] (a.out.__DATA_CONST.__const + 16)
      Summary: a.out`vtable for Parent + 16
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011b}, range = [0x00000001000040e8-0x0000000100004108), name="vtable for Parent", mangled="_ZTV6Parent"

// Parent vtable 内存大小
(lldb) p 0x0000000100004108 - 0x00000001000040e8
(long) $3 = 32

// 查看 Parent vtable 内存信息       
(lldb) x -fx -s8 -c4 0x00000001000040e8
0x1000040e8: 0x0000000000000000 0x0000000100004108
0x1000040f8: 0x0000000100003180 0x0000000100003190

// Parent::Foo() function
(lldb) image lookup -a 0x0000000100003180
      Address: a.out[0x0000000100003180] (a.out.__TEXT.__text + 552)
      Summary: a.out`Parent::Foo() at Single-Inheritance-vtable.cpp:6

// Parent::FooNotOverridden() function
(lldb) image lookup -a 0x0000000100003190
      Address: a.out[0x0000000100003190] (a.out.__TEXT.__text + 568)
      Summary: a.out`Parent::FooNotOverridden() at Single-Inheritance-vtable.cpp:7

// 查看 0x0000000100004108 镜像信息
(lldb) image lookup -va 0x0000000100004108
      Address: a.out[0x0000000100004108] (a.out.__DATA_CONST.__const + 32)
      Summary: a.out`typeinfo for Parent
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011c}, range = [0x0000000100004108-0x0000000100004118), name="typeinfo for Parent", mangled="_ZTI6Parent"

// 查看 Parent 类型信息
(lldb) x -fx -s8 -c2 0x0000000100004108
0x100004108: 0x00000002026592b0 0x8000000100003e9f

(lldb) image lookup -a 0x00000002026592b0
      Address: libc++abi.dylib[0x00000001dd3892b0] (libc++abi.dylib.__AUTH_CONST.__const + 12016)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__class_type_info + 16

(lldb) image lookup -a 0x8000000100003e9f
      Address: a.out[0x0000000100003e9f] (a.out.__TEXT.__const + 0)
      Summary: a.out`typeinfo name for Parent

(lldb) p/c (char *)0x000000100003e9f
(char *) $6 = \x9f>\0\0\x01\0\0\0 "6Parent"

================================================================================================

// 查看 Derived 类大小
(lldb) expression sizeof(*d1)
(unsigned long) $10 = 8

(lldb) p/x d1
(Derived *) $7 = 0x000060000000c000
(lldb) p/x d2
(Derived *) $8 = 0x0000600000010000

// 查看 Derived 实例内存内容
(lldb) x -fx -s8 -c1 0x000060000000c000
0x60000000c000: 0x0000000100004128
(lldb) x -fx -s8 -c1 0x0000600000010000
0x600000010000: 0x0000000100004128

// vtable for Derived
(lldb) image lookup -va 0x0000000100004128
      Address: a.out[0x0000000100004128] (a.out.__DATA_CONST.__const + 64)
      Summary: a.out`vtable for Derived + 16
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011d}, range = [0x0000000100004118-0x0000000100004138), name="vtable for Derived", mangled="_ZTV7Derived"

// vtable memory for Derived
(lldb) x -fx -s8 -c4 0x0000000100004118
0x100004118: 0x0000000000000000 0x0000000100004138
0x100004128: 0x00000001000031e4 0x0000000100003190

// function Derived::Foo()
(lldb) image lookup -a 0x00000001000031e4
      Address: a.out[0x00000001000031e4] (a.out.__TEXT.__text + 652)
      Summary: a.out`Derived::Foo() at Single-Inheritance-vtable.cpp:13

// function Parent::FooNotOverridden()
(lldb) image lookup -a 0x0000000100003190
      Address: a.out[0x0000000100003190] (a.out.__TEXT.__text + 568)
      Summary: a.out`Parent::FooNotOverridden() at Single-Inheritance-vtable.cpp:7

// typeinfo for Derived 
(lldb) image lookup -va 0x0000000100004138
      Address: a.out[0x0000000100004138] (a.out.__DATA_CONST.__const + 80)
      Summary: a.out`typeinfo for Derived
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011e}, range = [0x0000000100004138-0x0000000100004150), name="typeinfo for Derived", mangled="_ZTI7Derived"

// typeinfo size for Derived
(lldb) p 0x0000000100004150-0x0000000100004138
(long) $11 = 24

(lldb) x -fx -s8 -c3 0x0000000100004138
0x100004138: 0x0000000202659318 0x8000000100003ea7
0x100004148: 0x0000000100004108

// vtable for __si_class_type_info
(lldb) image lookup -a 0x0000000202659318
      Address: libc++abi.dylib[0x00000001dd389318] (libc++abi.dylib.__AUTH_CONST.__const + 12120)
      Summary: libc++abi.dylib`vtable for __cxxabiv1::__si_class_type_info + 16

// class name for Derived
(lldb) image lookup -a 0x8000000100003ea7
      Address: a.out[0x0000000100003ea7] (a.out.__TEXT.__const + 8)
      Summary: a.out`typeinfo name for Derived

// pointer for Paranet class typeinfo, 指向父类的类型信息
(lldb) image lookup -va 0x0000000100004108
      Address: a.out[0x0000000100004108] (a.out.__DATA_CONST.__const + 32)
      Summary: a.out`typeinfo for Parent
       Module: file = "/Users/admin/Desktop/a.out", arch = "arm64"
       Symbol: id = {0x0000011c}, range = [0x0000000100004108-0x0000000100004118), name="typeinfo for Parent", mangled="_ZTI6Parent"

*/
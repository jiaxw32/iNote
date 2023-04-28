# Running arm64 code on your Intel Mac 🖥 using Unicorn emulator

> 原文链接：https://danylokos.github.io/0x04/

Unicorn is a lightweight multi-platform, multi-architecture CPU emulator framework™ - [official website](https://www.unicorn-engine.org/). How is it useful? I’ve used it to trace and analyze heavily obfuscated and deeply nested code parts in iOS arm64 binaries. So it can be a very nice tool to help with some dynamic code analysis. You can run the code compiled for architecture that differs from your host computer and instantly see the results.

Unicorn是一个轻量级的多平台、多架构CPU仿真器框架™ - [官方网站](https://www.unicorn-engine.org/)。它有什么用处？我曾经使用它来跟踪和分析iOS arm64二进制文件中严重混淆和嵌套的代码部分。因此，它可以成为一种非常好的工具，帮助进行一些动态代码分析。您可以运行针对与主机计算机不同的体系结构编译的代码，并立即查看结果。

## Demo app

Here is a very basic app I’ve made for this demo. As you can see, it asks the user for a key and compares it with a pre-defined XOR-encrypted key. If they match, we have a “Success” message printed or a “Wrong key” message otherwise.

这是我为此演示制作的一个非常基本的应用程序。正如您所看到的，它会要求用户输入密钥并将其与预定义的XOR加密密钥进行比较。如果匹配，则打印“成功”消息，否则打印“错误的密钥”消息。

```log
mbp:~ ./demo
Enter key:
AAAAAAAAAA
Wrong key.
```

The source code:

源代码：

```c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define KEY_LEN 11

const char enc_key[] = { 0x32, 0x24, 0x22, 0x33, 0x24, 0x35, 0x1e, 0x2a, 0x24, 0x38, 0x41 }; // "secret_key" xor 0x41

int check_key(char *key) {
    char dec_key[KEY_LEN];
    for (int i=0; i<KEY_LEN; i++) {
        dec_key[i] = enc_key[i] ^ 0x41;
    }
    return strcmp(dec_key, key);
}

int main(int argc, char* argv[]) {
    printf("Enter key:\n");
    char key[KEY_LEN];
    scanf("%10s", key);
    if (check_key(key) == 0) {
        printf("Success!\n");
    } else {
        printf("Wrong key.\n");
    }
    return 0;
}
```

To showcase the power of emulation, I will compile it as an `arm64` binary using iOS SDK. My host machine is `x86_64` Intel Mac. Xcode is needed for compilation. (In reality, the target platform such as iOS doesn’t matter much because we are emulating CPU and not the whole platform with a binary loader, dynamic linker, etc. But theoretically, calling convention may differ from platform to platform in generated assembly code.)

为展示仿真的威力，我将使用iOS SDK将其编译为`arm64`二进制文件。我的主机是`x86_64`英特尔Mac。需要使用Xcode进行编译。（实际上，目标平台如 iOS 并不重要，因为我们正在模拟CPU而不是整个平台与二进制加载器、动态链接器等。但从理论上讲，在生成的汇编代码中调用约定可能会因平台而异。）

```bash
mbp:~ clang demo.c -o demo -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -fno-stack-protector
```

I’ve added `-fno-stack-protector` option, which disables stack canaries, just to make this demo a bit easier.

我已经添加了`-fno-stack-protector`选项，它禁用了堆栈保护机制，只是为了让这个演示变得更容易一些。

If everything is done right, the result will look like this, fully functional iOS arm64 binary:

如果一切都做得正确，结果将会是这样一个完全功能的iOS arm64二进制文件：

```text
mbp:~ file demo
demo: Mach-O 64-bit executable arm64
```

## Some assembly

Here is the disassembly of the `check_key` function (as seen by `objdump`)

这是`check_key`函数的反汇编结果（通过`objdump`查看）

```bash
mbp:~ objdump --disassemble-symbols=_check_key demo
```

```asm
0000000100007e78 <_check_key>:
100007e78: sub  sp, sp, #48
100007e7c: stp  x29, x30, [sp, #32]
100007e80: add  x29, sp, #32
100007e84: stur x0, [x29, #-8]
100007e88: str  wzr, [sp, #8]
100007e8c: ldr  w8, [sp, #8]
100007e90: subs w8, w8, #11
100007e94: b.ge 0x100007ed0 <_check_key+0x58>
100007e98: ldrsw    x9, [sp, #8]
100007e9c: adrp x8, 0x100007000 <_check_key+0x24>
100007ea0: add  x8, x8, #3972
100007ea4: ldrsb    w8, [x8, x9]
100007ea8: mov  w9, #65
100007eac: eor  w8, w8, w9
100007eb0: ldrsw    x10, [sp, #8]
100007eb4: add  x9, sp, #13
100007eb8: add  x9, x9, x10
100007ebc: strb w8, [x9]
100007ec0: ldr  w8, [sp, #8]
100007ec4: add  w8, w8, #1
100007ec8: str  w8, [sp, #8]
100007ecc: b    0x100007e8c <_check_key+0x14>
100007ed0: ldur x1, [x29, #-8]
100007ed4: add  x0, sp, #13
100007ed8: bl   0x100007f78 <_strcmp+0x100007f78>
100007edc: ldp  x29, x30, [sp, #32]
100007ee0: add  sp, sp, #48
100007ee4: ret
```

We will try to emulate this piece of code instead of doing static analysis to get the value of `enc_key` - our secret key that user input is compared against.

我们将尝试模仿这段代码，而不是进行静态分析来获取`enc_key`的值 - 这是我们与用户输入进行比较的秘密密钥。

If I were using a debugger, I would typically try to put a breakpoint at address `0x100007ed8` - a `strcmp` function call that actually performs the strings comparison and analyze the registers. But here, we are analyzing binary of different target architecture, and we can’t run or debug it directly.

如果我使用调试器，通常会尝试在地址`0x100007ed8`处设置断点 - 这是一个实际执行字符串比较的`strcmp`函数调用，并分析寄存器。但是在这里，我们正在分析不同目标架构的二进制文件，无法直接运行或调试它。

We know `strcmp` takes two arguments. According to [arm64 calling convetion](https://en.wikipedia.org/wiki/Calling_convention) first 8 arguments are passed through the registers `x0-x7`.

我们知道`strcmp`需要两个参数。根据[arm64调用约定]()，前8个参数通过寄存器`x0-x7`传递。

As we can see right before the `strcmp` call, we have `ldur x1, [x29, -8]` instruction which loads a value from memory that `x29` register points to decremented by `8` into `x1` register and `add x0, sp, #13` which adds `13` to the `sp` (stack pointer) value and stores it into `x0`. According to the calling convention, those should be the addresses of our `dec_key` and `key` variables from the source code above.

正如我们在`strcmp`调用之前看到的那样，我们有`ldur x1，[x29，-8]`指令，它将从内存中加载一个值，并将`x29`寄存器所指向的地址减去`8`放入`x1`寄存器中，并且`add x0, sp, #13`会将`13`添加到`sp`（堆栈指针）值并将其存储到x0中。根据调用约定，这些应该是源代码中`dec_key`和`key`变量的地址。

Let’s run this piece of the code in an emulator and dump contents of `x0` and `x1` right before `strcmp` call. We will not be loading the C runtime library into our emulator anyway, so `strcmp` will not point to the real function and so will not work. Also, it will require doing some function stubs re-binding, which is out of the scope of this post.

让我们在模拟器中运行此代码片段，并在`strcmp`调用之前转储`x0`和`x1`的内容。无论如何我们都不会将C运行时库加载到模拟器中，因此`strcmp`不会指向真实函数也不起作用。此外，它还需要进行一些函数桩重绑定操作，在本文范围之外。

## Emulator

Create a new virtual environment, install all the dependencies using `pip`:

创建一个新的虚拟环境，使用pip安装所有依赖项：

```bash
mbp:~ python3 -m venv .venv/ && source .venv/bin/activate
(.venv) mbp:~ pip install unicorn capstone hexdump
```

Capstone is a multi-architecture disassembly framework. I will use it to disassemble and log instructions on the fly.

Capstone是一个多架构反汇编框架。我将使用它来实时反汇编和记录指令。

Here is a fully working emulator code. Let’s review it part by part.

这里是一个完全可用的模拟器代码。让我们逐部分进行审查。

```python
#!/usr/bin/env python3

from hexdump import hexdump
from unicorn import *
from unicorn.arm64_const import *
from capstone import *

# 1
BASE_ADDR = 0x1_0000_0000 # base address
BASE_SIZE = 100 * 1024 # enough memory to fit the binary image

HEAP_ADDR = 0x5_0000_0000 # arbitrary address
HEAP_SIZE = 0x21_000 # some default heap size

STACK_ADDR = 0x9_0000_0000 # arbitrary address
STACK_SIZE = 0x21_000 # some default stack size
STACK_TOP = STACK_ADDR + STACK_SIZE # stack grows downwards

# 6
def hook_code(uc, address, size, user_data):
    code = BINARY[address-BASE_ADDR:address-BASE_ADDR+size]
    for i in md.disasm(code, address):
        print("0x%x:\t%s\t%s" % (i.address, i.mnemonic, i.op_str))
        # stop emulation when function returns
        if i.mnemonic == "ret":
            uc.emu_stop()
    return True


try:
    # 2
    print("[+] Init")
    md = Cs(CS_ARCH_ARM64, UC_MODE_ARM)
    mu = Uc(UC_ARCH_ARM64, UC_MODE_ARM)

    # 3
    print("[+] Create memory segments")
    mu.mem_map(BASE_ADDR, BASE_SIZE)
    mu.mem_map(STACK_ADDR, STACK_SIZE)
    mu.mem_map(HEAP_ADDR, HEAP_SIZE)

    # 4
    print("[+] Load and map binary")
    BINARY = open("./demo", "rb").read()
    mu.mem_write(BASE_ADDR, BINARY)

    # 5
    print("[+] Add hooks")
    mu.hook_add(UC_HOOK_CODE, hook_code)

    # 7
    print("[+] Setup stack pointer")
    mu.reg_write(UC_ARM64_REG_SP, STACK_TOP)

    # 8
    # write our input to heap
    mu.mem_write(HEAP_ADDR, b"A" * 10)
    mu.reg_write(UC_ARM64_REG_X0, HEAP_ADDR)

    # 9
    print("[+] Start emulation")
    start_addr = 0x1_0000_7e78 # check_key
    end_addr = 0x1_0000_7ed8 # strcmp
    mu.emu_start(start_addr, end_addr)

    # 10
    # print x0 and x1 values
    print("[+] x0: 0x%x" % (mu.reg_read(UC_ARM64_REG_X0)))
    hexdump(mu.mem_read(mu.reg_read(UC_ARM64_REG_X0), 16))

    print("[+] x1: 0x%x" % (mu.reg_read(UC_ARM64_REG_X1)))
    hexdump(mu.mem_read(mu.reg_read(UC_ARM64_REG_X1), 16))  

    print("[+] Done")
except UcError as err:
    print("[E] %s" % err)
```

Let’s break this down.

1. Here, I set up addresses of basic memory segments we will use in emulation. `BASE_ADDR` - address where our binary will be loaded at. `BASE_SIZE` - should be enough to hold the entire binary. `HEAP_ADDR` and `STACK_ADDR` - heap and stack addresses with some arbitrary size of `0x21000`. If we ever exhaust heap or stack memory during emulation (and probably crash), we can always increase these values and restart emulation. Unicorn is a CPU emulator. It will not increase our stack or heap dynamically. That’s the job of the OS.

2. Initialize Unicorn and Capstone engines with `*_ARCH_ARM64` architecture and `UC_MODE_ARM` mode.

3. Create our three memory segments: main binary, heap, and stack with corresponding sizes.

4. Read our compiled arm64 `demo` binary and write it into mapped memory at `BASE_ADDR`.

5. Setup hook. Here I’m using `UC_HOOK_CODE` to hook each instruction, disassemble and print in `hook_code` function. There are multiple hooks available: memory read/write hooks, CPU interruption hook (I’ve used this one to trace `syscalls`), etc.

6. Our hook function, which disassembles code using Capstone, also it checks it we reached a `ret` instruction. At that point we can probably stop emulation, which can be helpful if we are interested in the emulation of a single function.

7. Setup an initial value of a stack pointer, which should point to the top of the stack as the stack grows downwards.

8. Our `check_key` function takes a single argument which is passed thought `x0` register. Here we simulate user input by writing `AAAAAAAAAA` (10 * `A`) into the heap and placing pointer to the start of the heap into x0

9. Start emulation. `0x100007e78` is the address where `check_key` starts and where we want to start the emulation. `0x100007ed8` is the address of the `strcmp` - address where we want our emulation to end.

10. After emulation ends, we want to inspect addresses at `x0` and `x1` and dump the memory at corresponding addresses.

***

让我们分解这个问题。

1. 这里，我设置了我们在仿真中将使用的基本内存段地址。`BASE_ADDR` - 我们二进制文件加载的地址。`BASE_SIZE` - 应足以容纳整个二进制文件。   `HEAP_ADDR`和`STACK_ADDR` - 带有任意大小为`0x21000`的堆和栈地址。如果我们在仿真期间耗尽堆或栈内存（并可能崩溃），则可以随时增加这些值并重新启动仿真。Unicorn是一个CPU模拟器，它不会动态增加我们的堆栈空间，这是操作系统的工作。

2. 使用`*_ARCH_ARM64`架构和`UC_MODE_ARM`模式初始化Unicorn和Capstone引擎。

3. 创建三个内存段：主要二进制、堆和栈，并分别设置其大小。

4. 读取已编译的arm64演示二进制文件，并将其写入映射到`BASE_ADDR`处的内存中。

5. 设置钩子函数。我在此处使用`UC_HOOK_CODE`来挂钩每条指令、反汇编并打印`hook_code`函数中内容。有多种可用于挂钩功能：内存读/写挂钩、CPU中断挂钩（我使用此功能来跟踪系统调用）等等。

6. 我们的hook函数通过Capstone反汇编代码，并检查是否达到`ret`指令点，在那一点上，如果我们只对单个函数进行仿真，则可以停止仿真过程，这可能会有所帮助。

7. 设置堆栈指针的初始值，它应该指向堆栈顶部，因为堆栈是向下增长的。

8. 我们的`check_key`函数接受一个参数，该参数通过`x0`寄存器传递。在这里，我们通过将`AAAAAAAAAA`（10 * `A`）写入堆中并将指针放置到堆开始处来模拟用户输入，并将其放入`x0`中。

9. 开始仿真。 `0x100007e78`是`check_key`开始的地址和我们想要启动仿真的地方。 `0x100007ed8`是`strcmp`的地址 - 我们希望仿真结束时到达此处。

10. 仿真结束后，我们需要检查`x0`和`x1`处的地址，并转储相应地址上的内存内容。


## Output

Here we can see a successful run of the emulator. And our `secret_key` value dumped into a console!

在这里，我们可以看到模拟器成功运行。并且我们的 `secret_key` 值被转储到控制台！

```text
(.venv) mbp:~ ./demo_emu.py
[+] Init
[+] Map memory
[+] Load and map binary
[+] Add hooks
[+] Setup stack pointer
[+] Starting at: 0x100007e78
[+] x0: 0x900020fdd
00000000: 73 65 63 72 65 74 5F 6B  65 79 00 00 00 00 00 05  secret_key......
[+] x1: 0x500000000
00000000: 41 41 41 41 41 41 41 41  41 41 00 00 00 00 00 00  AAAAAAAAAA......
[+] Done
```

## Links

* [Tutorial for Unicorn](https://www.unicorn-engine.org/docs/tutorial.html)
* [Sources for demo.c and demo_emu.py](https://github.com/danylokos/unicorn-demo)
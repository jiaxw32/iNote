# Part 2 – iOS Native Code Obfuscation and Syscall Hooking | 第二部分 - iOS原生代码混淆和系统调用挂钩

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/featured.png)

> The first part is here: [Part 1 – SingPass RASP Analysis][]

After `SingPass`, I had a look at another application protected with the same obfuscator but with enhanced protections.

在研究了SingPass之后，我又看了一个使用相同混淆器但增强保护的应用程序。

Compared to the previous application, this new application crashes immediately as soon as it is launched.

与之前的应用程序相比，这个新应用程序启动就立即崩溃。

By checking the crash log, we don’t get any meaningful information since the obfuscator **trashes** some registers like LR before crashing. By trashing LR, the iOS crash analytics service is not able to correctly build the call stack of the functions that led to the crash.

通过检查崩溃日志，我们无法获得任何有意义的信息，因为混淆器会在崩溃前破坏一些寄存器（如LR）。通过破坏LR，iOS崩溃分析服务无法正确构建导致崩溃的函数调用堆栈。

On the other hand, by tracing the libraries loaded by the application, we can identify in which loaded library the application crashes, and thus, the library is likely in charge of checking the environment’s integrity.

另一方面，通过跟踪应用程序加载的库，我们可以确定应用程序崩溃时所加载的库，并且该库很可能负责检查环境完整性。

```text
$ ijector.py --spawn ios.app
iTrace started
PID: 63969 | tid: 771
Home: /private/var/mobile/Containers/Data/Application/A59541E1-106A-4C31-8188-0830E651449E
...
ImageLoader::containsAddress(0x1065f948c): cxxreact!1948c
ImageLoader::containsAddress(0x10564e270): ReactCommon!1a270
ImageLoader::containsAddress(0x103e5ed84): GRDB!12ed84
ImageLoader::containsAddress(0x104407790): Intercom!1bb790
ImageLoader::containsAddress(0x104c29d7c): KaaSLogging!9d7c
ImageLoader::containsAddress(0x105871bb4): RxSwift!91bb4
ImageLoader::containsAddress(0x1056f00cc): RxBluetoothKit!440cc
ImageLoader::containsAddress(0x104633f50): KaaSBle!bbf50
---> CRASH!
```

So the application crashes when loading the `KaaSBle` library embedded as a third-party framework of the application.

当将 KaaSBle 库作为第三方框架嵌入应用程序时，加载该库时应用程序会崩溃。

Compared `SingPass`, the library does not leak symbols about the RASP checks nor about the obfuscator. In addition, some functions are obfuscated with control-flow flattening and Mixed Boolean-Arithmetic (MBA) expressions as we can observe in the following figure:

与SingPass相比，该库不会泄漏有关 RASP 检查或混淆器的符号。此外，一些函数使用控制流平坦化和混合布尔算术（MBA）表达式进行了混淆，如下图所示：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/cfg_flat_macho_ctor.webp "Figure 1 - Control-Flow Flattening in the Constructor of KaaSBle")

Based on the previous analysis of `SingPass`, we know that RASP checks related to jailbreak or debugger detection use uncommon functions like getpid, unmount or pathconf. It turns out that, these functions are also imported by KaaSBle which enables to identify where some of the RASP checks are located.

根据之前对 SingPass 的分析，我们知道 RASP 检查与越狱或调试器检测相关的使用了像 getpid、unmount 或 pathconf 这样不常见的函数。结果发现，这些函数也被 KaaSBle 导入，从而能够确定一些 RASP 检查所在的位置。

>   Uncommon imported functions like unmount are usually a good signature to identify potential RASP checks
> 
> 不常见的导入函数，比如 unmount，通常是识别潜在 RASP 检查的良好标志

For instance, the function `sub_EBDC` which uses `getpid` is likely involved in the debugger detection. This function is obfuscated with an MBA and control-flow flattening and, its graph is represented in Figure 2[^1]

例如，使用 getpid 的函数 `sub_EBDC` 可能涉及调试器检测。该函数采用MBA和控制流平坦化进行混淆，它的控制流图形在图2中表示。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig02-BinaryNinja_HLIL_Graph_of_sub_EBDC.png "Figure 2 - BinaryNinja HLIL Graph of sub_EBDC")


## Control-Flow Flattening

I won’t detail how generally control-flow flattening works as it already exists a good bunch of articles on this topic:

我不会详细介绍控制流平坦化的工作原理，因为已经有很多关于这个主题的文章：

* [Deobfuscation: recovering an OLLVM-protected program][] by Quarkslab
* [Automated Detection of Control-flow Flattening][] by Tim Blazytko
* [D810: A journey into control flow unflattening][] by eShard

Nevertheless, we can notice that the state variable that is used to drive the execution through the flattened blocks is linear and not encoded:

尽管如此，我们可以注意到用于驱动执行平坦块的状态变量是线性而非编码的。

> The state variable set at the end of the basic block exactly defines the next basic block to execute.
>
> 基本块末尾设置的状态变量确切地定义了要执行的下一个基本块。


This means that given:

这意味着，给定：

1. A state value
2. The switch table
3. The switch base address

It is possible to easily compute the targeted basic block:

可以轻松计算出目标基本块：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/cfg-flat.webp "Fig 3. Computation of the Basic Block from a State Variable")


![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig04-Simplified_Overview.png "Fig 4. Simplified Overview")


Since there is no encoding, we can determine the next states of a basic block by looking at the constant written in the local stack variable `[sp, 0x50+var_4c]` or the `state_variable` of the BinaryNinja High Level IL representation ([Figure 2]()).

由于没有编码，我们可以通过查看本地堆栈变量`[sp, 0x50+var_4c]`中写入的常量或BinaryNinja高级IL表示法（图2）的状态变量来确定基本块的下一个状态。

From a graph recovery perspective, this design **completely fits** in the case of the Quarkslab’s blog: [recovering an OLLVM-protected program][], thus the original graph could be completely recovered.

从图形恢复的角度来看，这种设计完全符合Quarkslab博客中所述情况：恢复OLLVM保护程序，因此原始图形可以完全恢复。

> I also checked other large control-flow-flattened functions in the binary and they follow the same design with the same weakness.
>
> 我还检查了二进制文件中的其他大型控制流扁平化函数，它们都采用相同的设计，并存在着相同的弱点。

## Improvements

> **Spoiler**: This example comes from an on-going larger project: [open-obfuscator][].

Actually we can enhance the protections of the control-flow flattening by encoding the state variable and by identifying the basic blocks of the switch table with random numbers (instead of 1, 2, 3 etc).

实际上，我们可以通过对状态变量进行编码，并使用随机数（而不是1、2、3等）来识别switch表的基本块，从而增强控制流平坦化的保护。

The following figure outlines this design:

下图概述了这个设计：

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig05-Control-Flow_Flattening_with_Random_ID_and_Encoding.png "Fig 5. Control-Flow Flattening with Random ID and Encoding")

Concretely, the code generated **does not use a lookup-switch table** and the dispatcher is a succession of conditions:

具体而言，生成的代码不使用查找表，调度程序是一系列条件。

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/cfg-flat-omvll-head.webp "Figure 6 - Head of the Control-Flow Flattening
")

We can also observe the encoding block at the end of the graph:

我们还可以观察到图表末尾的编码块：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/cfg-flat-omvll-tail.webp "Figure 7 - Tail of the Control-Flow Flattening")


In this example, the encoding is simply `E(X)=X⊕A+B` but it could be protected with an MBA and generated with different expressions, unique per function. Globally speaking, any injective (or bijective) function should fit as an encoding.

在这个例子中，编码仅仅是XOR加上常数的形式：E(X)=X⊕A+B。但是它可以通过MBA进行保护，并且使用不同的表达式生成，每个函数都有唯一的表达式。总体而言，任何单射（或双射）函数都适用于编码。

In the end, it would increase the complexity of recovering the original graph **at scale** (even though the design is known).

最终，这将增加恢复大规模原始图像的复杂性（即使设计已知）。

## Mixed-Boolean Arithmetic

We can also observe in [Figure 2]() that the function uses an MBA as an opaque zero or more precisely an opaque boolean.

从图2中我们也可以观察到，该函数使用MBA作为不透明的零或更准确地说是一个不透明的布尔值。

Generally speaking, MBA are widely used by the obfuscator but they are usually represented under their simple form like `(A⊕B)+(A&B)×2`. In other words, we **can’t quickly** identify the underlying arithmetic operation but with limited efforts, we can simplify the expression using public tools.

一般来说，混淆器广泛使用MBA，但它们通常以简单形式表示，如(A⊕B)+(A&B)×2。换句话说，我们无法快速识别底层算术运算，但通过有限的努力，我们可以使用公共工具简化表达式。

If you want to dig more into MBA deobfuscation, I highly recommend this recent blog post [Improving MBA Deobfuscation using Equality Saturation][] by [Tim Blazytko][] and [Matteo][] which also lists open-source tools that can be used for simplifying MBA like:

如果你想深入了解MBA反混淆，我强烈推荐阅读[Tim Blazytko][]和[Matteo][]最近发表的博客文章[Improving MBA Deobfuscation using Equality Saturation][]，其中列出了可以用于简化MBA的开源工具：

* [sspam][]
* [msynth][] (Used for this binary)

>   [Triton][] also supports program synthesis: [synthesizing_obfuscated_expressions.py][]

## Strings Encoding

Most of the strings used in the library are encoded which prevents identifying quickly sensitive functions.

库中使用的大多数字符串都是编码的，这防止了快速识别敏感函数。

These encoded strings are decoded just-in-time near the instruction that uses given the string. In the blog post about [PokemonGO][], **all the strings** were decrypted at once in the Mach-O constructors which enabled to recover all of these strings without caring about reverse engineering the decoding routines. For the current obfuscator, we can’t exactly apply this technique.

这些编码字符串在使用给定字符串的指令附近即时解码。在有关PokemonGO的博客文章中，所有字符串都一次性解密到Mach-O构造函数中，从而使得可以恢复所有这些字符串而不必担心反向工程解码例程。对于当前的混淆器，我们无法完全应用此技术。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig08-Differences_in_Designing_String_Encryption.png "Fig 8. Differences in Designing String Encryption")

To better understand the difficulty, let’s take a closer look at how strings are encoded with the `_unmount()` function. As a reminder, this function is used as a part of jailbreak detection.

为了更好地理解难点，让我们仔细看一下如何使用_unmount()函数对字符串进行编码。提醒一下，这个函数是越狱检测的一部分。

In the KaaSBle library, there are five cross-references to  `_unmount()`:

在KaaSBle库中，有五个交叉引用指向_unmount()：

```text
P sub_61d94+178                     BL _unmount
P sub_8fa98+1c8                     BL _unmount
P _mbedtls_entropy_gather_0+128     BL _unmount
P _mbedtls_ssl_get_session+11c      BL _unmount
P sub_177998+c                      BL _unmount
```

When looking at the prologue of the `_unmount()` calls, we get the following basic blocks:

当查看_unmount()调用的序言时，我们得到以下基本块：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/boostrapped.webp "Figure 9 - Decoding Routine for the String /.bootstrapped
")

Which is equivalent to this snippet:

这相当于以下代码片段：

```python
from itertools import cycle

def decode(encrypted: bytes, key: str, op):
    key       = bytes.fromhex(key)
    encrypted = bytes.fromhex(encrypted)
    out = ""
    for idx, (k, v) in enumerate(zip(encrypted, cycle(key))):
        out += chr(op(idx, k, v) & 0xFF)
    return out

# /.bootstrapped
clear = decode("9f0b698a3abc17e70bb54332271180", # Encoded string
               "b0250be555c8649379d43342427580", # Key
               lambda _, k, v: (k ^ v))          # Operation
```

It is worth mentioning that the string is not decoded in-placed but in another __data variable. This means that an encoded string takes potentially twice its size in the final binary.

值得一提的是，该字符串并非在原地解码，而是在另一个__data变量中进行解码。这意味着，在最终二进制文件中，编码后的字符串可能会占用其大小的两倍。

Another example of a decoding routine:

另一个解码例程：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/installed_odyssey.webp "Figure 10 - Decoding Routine for the String /.installed_odyssey")

Which is equivalent to:

```python
# /.installed_odyssey
clear = decode("1bec336463362f66602b365d672e4f756f3353", # Encoded string
               "ecbdc8f3",                               # Key
               lambda i, k, v: (k - v - i))              # Operation
```

In this case, the key is an uint32_t integer for which the bytes are accessed through a stack variable. The weird operation `x12 = x8 & (x8 ^ 0xfffffffffffffffc)` is simply a modulus sizeof(uint32_t) :)

在这种情况下，关键是一个uint32_t整数，其字节通过堆栈变量访问。奇怪的操作 `x12 = x8 & (x8 ^ 0xfffffffffffffffc)`只是模 sizeof(uint32_t) :）

In summary, because of the **disparity** of the encodings which are mixed with MBA and unique keys, it would be quite difficult to **statically** decode all the strings of the library. On the other hand, since the clear strings are written in the __data section of the binary, we can dump – at some point in the execution – this section and observe the clear strings (c.f. [Singpass RASP Analysis - Jailbreak Detection][]).

总之，由于MBA和唯一密钥混合使用的编码不同，静态解码库中所有字符串将非常困难。另一方面，由于明文字符串写在二进制文件的__data部分中，我们可以在执行过程中某个时刻转储该部分并观察明文字符串（参见[Singpass RASP Analysis - Jailbreak Detection][]）。

## Crash Analysis

When the obfuscator detects that the environment is compromised (jailbroken device, debugger attached, …), it reacts by crashing the application. This crash occurs through different techniques among which:

当混淆器检测到环境被破坏（越狱设备、调试器已连接等）时，它会通过不同的技术使应用程序崩溃。这些崩溃技术包括：

1. Corrupting a global pointer
2. Executing a break instruction (BRK #1)
3. Trashing the link register and frame register (LR / FP)
4. Calling objc_msgSend with corrupted parameters

***

1. 破坏全局指针
2. 执行断点指令（BRK #1）
3. 损坏链接寄存器和帧寄存器（LR / FP）
4. 使用损坏的参数调用 objc_msgSend


The instructions involved in crashing the application are **inlined** in the function where the check occurs. This means that there is as many crash routine as there are RASP checks.

导致应用程序崩溃的指令是内联在进行检查的函数中的。这意味着有多少个 RASP 检查就有多少个崩溃例程。

In particular, with such a design, we can’t target a single function to bypass the different checks as I did for SingPass.

特别地，在这种设计下，我们无法针对单个函数绕过不同的检查，就像我为 SingPass 所做的那样。

## Hooking the Syscalls

> This approach is inspired by this talk at Pass the Salt: [Jailbreak Detection and How to Bypass Them][]

To better understand the problem, let’s recap the situation:

1. The code is obfuscated with CFG flattening, MBA, etc
2. The RASP checks are inlined in the code
3. The application crashes near the detection spot. In particular and compared to SingPass, there is no RASP endpoint that can be hooked.

为了更好地理解问题，让我们回顾一下情况：

1. 该代码已使用CFG平坦化、MBA等进行混淆。
2. RASP检查被内联在代码中。
3. 应用程序在检测点附近崩溃。特别是与SingPass相比，没有可以挂钩的RASP端点。


The following figure depicts the differences in the RASP reaction between the two applications:

以下图表描述了两个应用程序之间RASP反应的差异：

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig11-RASP_Reaction-User_Callback_vs_Crash.png "Figure 11 - RASP Reaction: User Callback vs Crash")

We can’t actually hook a function to bypass the RASP checks but the structure of the AArch64 instructions has a valuable property:

我们实际上无法挂钩函数来绕过 RASP 检查，但是 AArch64 指令的结构具有宝贵的特性：

**The size of an AArch64 instruction is fixed**

AArch64指令的大小是固定的。

As a consequence, we can **linearly** search the `SVC #80` instructions which are encoded as `0xD4001001`.

作为结果，我们可以线性搜索编码为0xD4001001的SVC＃80指令。

### Interception

Let’s consider the following approach to intercept the syscalls:

1. We linearly scan the __text section to find the SVC instructions (i.e. the four-bytes 0xD4001001)
2. We replace this instruction with a branch (BL #imm) to a function we control
3. We process the redirection to disable the RASP checks

我们考虑以下拦截系统调用的方法：

1. 线性扫描 __text 段以查找 SVC 指令（即四字节 0xD4001001）
2. 将此指令替换为跳转指令（BL #imm）到我们控制的函数
3. 处理重定向以禁用 RASP 检查

For the first point, thanks to the fixed instruction’s size, we can search syscalls by reading the whole __text section:

首先，由于固定指令大小的存在，我们可以通过读取整个__text节来搜索系统调用：

```c
static constexpr uint32_t SVC         = 0xD4001001; // SVC #0x80
static constexpr size_t   SIZEOF_INST = 4;

for (size_t addr = text_start; addr < text_end; addr += SIZEOF_INST) {
  // Read the instruction
  auto inst = *reinterpret_cast<uint32_t*>(addr);
  if (inst != SVC) {
    continue;
  }

  // We found a syscall instruction at: `addr`
}
```

For the second point, on a syscall instruction, we have to patch the syscall with a branch. To do so, Frida’s gum_memory_patch_code is pretty convenient:

对于第二点，在syscall指令上，我们需要使用分支来修补syscall。为此，Frida的gum_memory_patch_code非常方便：

```c
void* svc_addr = /* Address of the syscall to patch */

gum_memory_patch_code(svc_addr, /* sizeof an arm64 inst */ 4,
                      [] (void* addr, void*) {
                        GumArm64Writer* writer = gum_arm64_writer_new(addr);

                        /* Transform a SVC #0x80 into BL #AABBCC */
                        gum_arm64_writer_put_bl_imm(writer, 0xAABBCC);
                      }, nullptr);
);
```

The pending question is where to branch the new BL instruction instead of 0xAABBCC?

待解决的问题是在哪里分支新的BL指令，而不是0xAABBCC？

Ideally, we would like to jump on our own dedicated stub:

理想情况下，我们希望跳转到自己专用的存根：

```c
void handler() {
  // ...
}

{
  // ...
  gum_arm64_writer_put_bl_imm(writer, &handler);
}
```

**But**, the `bl #imm` instruction only accepts an immediate value in the range of [-0x8000000, 0x8000000]. This range might be too narrow to encode our absolute pointer &handler.

但是，bl #imm指令只接受范围在]-0x8000000; 0x8000000[之间的立即值。这个范围可能太窄了，无法编码我们的绝对指针&handler。

> The BL instruction encodes the signed #imm as a multiple of 4 on 26 bits. Thus, and because of the sign bit, this #imm can range from: ±1 << (26 + 2 - 1);
>
> BL指令将带符号的#imm编码为26位上4的倍数。因此，由于符号位，这个#imm可以范围从：±1 << (26 + 2 - 1)；

We can actually workaround this restriction by using a trampoline located **in the library** where the RASP checks occur. It is quite common for large binary to find small functions with one or two instructions that are not likely or rarely used:

我们实际上可以通过在RASP检查发生的库中使用跳板来绕过这个限制。对于大型二进制文件来说，找到只有一两条指令的小函数并不常见或很少被使用：

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/small_func_1.webp "Figure 12 - Small C++ vtable function")

![](https://www.romainthomas.fr/post/22-09-ios-obfuscation-syscall-hooking/imgs/small_func_2.webp "Figure 13 - Small C++ vtable function")

The idea is to use one of these functions as a placeholder to write **two instructions** which enables to branch an **absolute address**:

这个想法是使用其中一个函数作为占位符，编写两条指令来使得可以跳转到绝对地址：

```asm
LDR   x15, =&handler
BR    x15
```

Since this placeholder function is located within the library where the syscalls take place, we can `BL #imm` to this function without risking too much that #imm overflows the range [-0x8000000, 0x8000000]

由于此占位符函数位于系统调用发生的库中，我们可以对该函数进行`BL #imm`操作，而不必担心#imm 会溢出范围 [-0x8000000; 0x8000000]。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig14-Syscall_Patch.png "Fig 14. Syscall Patch")

Now that we found a mechanism to redirect the syscall instruction, we can focus on the handler function which aims at welcoming the syscall’s redirection.

现在我们找到了一个重定向syscall指令的机制，可以专注于处理程序函数，该函数旨在欢迎syscall的重定向。

First, the SVC instructions are atomic which means that our handler function must take care of not corrupting the values of the registers.

首先，SVC指令是原子性的，这意味着我们的处理程序函数必须注意不破坏寄存器值。

In particular, handler can’t follow the ARM64 calling convention. If we consider the following instructions:

特别地，处理程序不能遵循ARM64调用约定。如果我们考虑以下指令：

```asm
mov x6, #0
...
svc #0x80
...
mov x2, x6
```

svc #0x80 does not corrupt x6 while this code:

当使用svc #0x80时，不会破坏x6寄存器，而以下代码：

```asm
mov x6, #0
...
BL #imm
...
mov x2, x6
```

could corrupt x6 according to the ARM64 calling convention. Therefore, our handler() function must **really** mimic an interruption and take care of correctly saving/restoring the registers.

根据ARM64调用约定，可能会破坏x6。因此，我们的handler()函数必须真正模拟中断并正确保存/恢复寄存器。

In other words, we must write a small assembly stub to save and restore the registers[^2]

换句话说，我们必须编写一个小型汇编桥接程序来保存和恢复寄存器。

```asm
stp x0,  x1,  [sp, -16]!
...
stp x28, x29, [sp, -16]!
stp x30, xzr, [sp, -16]!

mov x0, sp

bl _syscall_handler;

ldp x30, xzr, [sp], 16
ldp x28, x29, [sp], 16
...
ldp xzr, x1,  [sp], 16
ret

```

The syscall_handler function takes a pointer to the stack frame as a parameter. Thus, we can access the saved registers:

syscall_handler函数以指向堆栈帧的指针作为参数。因此，我们可以访问保存的寄存器：

```c
extern "C" {
uintptr_t syscall_handler(uintptr_t* sp) {
  uintptr_t x16 = sp[14]; // Syscall number
  return -1;
}
}
```

> Apple prefixes (or mangles) symbols with a _ this is why syscall_handler is referenced by _syscall_handler in the assembly code.
>
> 苹果在符号前缀（或混淆）中使用 _，这就是为什么汇编代码中的 syscall_handler 会被引用为 _syscall_handler 的原因。

Given our syscall_handler function, we have access to the original AArch64 registers such as we can access the syscall number and its parameters. We are also able to modify the return value since the original syscall is replaced by a branch.

通过我们的syscall_handler函数，我们可以访问原始的AArch64寄存器，例如我们可以访问系统调用号及其参数。由于原始系统调用被替换为分支指令，因此我们还能够修改返回值。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/iOS-Obfuscation/Fig15-Syscall_Redirection.png "Fig 15. Syscall Redirection")

A PoC that wraps all this logic will be published on GitHub.

将包含所有这些逻辑的 PoC 将会在 GitHub 上发布。

## Conclusion

Whilst this application uses the same obfuscator as in the previous blog post, it was configured with multi-layered code obfuscation which includes control-flow flattening and MBA. In addition, the RASP checks are also configured to crash the application instead of calling a callback function and displaying a message. These improvements in the configuration of the obfuscator make the reverse engineering of the application harder compared to the previous SingPass application.

虽然此应用程序使用与先前博客文章中相同的混淆器，但它配置了多层代码混淆，包括控制流平坦化和MBA。此外，RASP检查也被配置为崩溃应用程序而不是调用回调函数并显示消息。与之前的SingPass应用程序相比，这些混淆器配置的改进使得反向工程变得更加困难。

This blog post also detailed a new AArch64-generic technique to intercept RASP syscalls which resulted in a successful bypass of the RASP checks. This technique should also apply to Android AArch64.

本博客文章还详细介绍了一种新的AArch64通用技术来拦截RASP系统调用，并成功地绕过了RASP检查。该技术也适用于Android AArch64。

This is the last part of this series about iOS obfuscation. As I said in the first disclaimer, the obfuscator used for protecting these applications is and remains a good choice to protect assets from reverse engineering.

这是关于iOS混淆的系列文章的最后一部分。正如我在第一个免责声明中所说，保护这些应用程序所使用的混淆器仍然是保护资产免受反向工程攻击的良好选择。


[^1]: The graph is more convenient to explore if Javascript is enabled. 
[^2]: We don’t restore x0 as we want to change the return value from _syscall_handler.

[open-obfuscator]: https://github.com/open-obfuscator
[Improving MBA Deobfuscation using Equality Saturation]: https://secret.club/2022/08/08/eqsat-oracle-synthesis.html
[Tim Blazytko]: https://twitter.com/mr_phrazer
[Matteo]: https://twitter.com/fvrmatteo
[sspam]: https://github.com/quarkslab/sspam
[msynth]: https://github.com/mrphrazer/msynth/
[Triton]: https://triton-library.github.io/
[synthesizing_obfuscated_expressions.py]: https://github.com/JonathanSalwan/Triton/blob/96104b1a860dc7ddb9ab123859b2fd668e388f72/src/examples/python/synthesizing_obfuscated_expressions.py
[PokemonGO]: https://www.romainthomas.fr/post/21-07-pokemongo-anti-frida-jailbreak-bypass/
[Singpass RASP Analysis - Jailbreak Detection]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/#jailbreak-detection
[Jailbreak Detection and How to Bypass Them]: https://archives.pass-the-salt.org/Pass%20the%20SALT/2021/slides/PTS2021-Talk-01-JailBreak_detection.pdf
[Part 1 – SingPass RASP Analysis]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/
[Deobfuscation: recovering an OLLVM-protected program]: https://blog.quarkslab.com/deobfuscation-recovering-an-ollvm-protected-program.html
[Automated Detection of Control-flow Flattening]: https://synthesis.to/2021/03/03/flattening_detection.html
[D810: A journey into control flow unflattening]: https://eshard.com/posts/D810-a-journey-into-control-flow-unflattening
[recovering an OLLVM-protected program]: https://blog.quarkslab.com/deobfuscation-recovering-an-ollvm-protected-program.html
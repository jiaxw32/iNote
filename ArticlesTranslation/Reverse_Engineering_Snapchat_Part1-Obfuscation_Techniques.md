# Reverse Engineering Snapchat (Part I): Obfuscation Techniques

> 原文链接：https://hot3eed.github.io/2020/06/18/snap_p1_obfuscations.html

When you have 200+ million daily users, you’ll definitely want to keep your API private from spammers and co., so you’ll have to keep a secret in the binary that authorizes it to make API calls to your server. 
Snapchat (as of version 10.81.6.81) does this by including an X-Snapchat-Client-Auth-Token header in each request, a typical one would look like:

当你拥有2亿以上的日活用户时，你肯定会想要将API保护起来，以免遭到垃圾邮件发送者等人的攻击。因此，你需要在二进制文件中添加一个秘密授权码，用于向服务器发出API调用请求。
Snapchat（截至版本10.81.6.81）通过在每个请求中包含X-Snapchat-Client-Auth-Token头部来实现这一点。一个典型的头部如下：

```text
v8:7841EAFE02CD9DE06AE8E41C6478D504:2B8115D1C5873C8BD5A3A9DDA7F976B21A672A643D8AB2AC91CE223C84BA5F9EB112B65B7C85AFD9CEA86A9DC36D5F6405B8D23B369A94A5657894207F09E432CBD21953F8E4F50E44373B59FB39270360DE5113FA983D1F06FF71A0D540488403A848D1C52A2421AF4341E6BBCD702F4921E5DC134ECCF99EDBD599EAA1AAA8556C6122334A63C86711740E58E453A7049FE94634DEC8FFE2E26C28780FFA46994818F7D0915E6DB3061188784D46D381CE2BF4D15E83BEC1ABFFE29207D2A58906CAC598AD314F368CF41E1892CA032859485DC99882F97D5064D4C7C5C2A4A4975C59530F4D0289EF4BC4E7CFC89FC8279038FB6E623C88A8AB38678F1D2757F7C0914C1A162E4F5B173E694109CD67E73762D8C090D8780714861DB883977D3B85D6F503D8D8CD5167B43A2DB18B79804841FE8064AD1A8078EAEF472698AD482AA77BC5D7EB012F0946DAFB923CFD10BA06675730EF338A96D1D0081B174BE5989B77FD07DCEDCDC635DEF1EE986F65798D87A358742F152AA929800FD5BA2CC29E
```

## Control flow obufscations: | 控制流混淆

Forget about doing static analysis on this binary. Here’s what they do on a high level: the CFG (control flow graph) is destroyed (not flattened), dead code, library calls are mostly dynamic, and all symbols for the token generation function (let’s call it gen_token) and its callees are stripped. They’re implemented in C and not Objective-C for this reason, because you can always use the [ObjC runtime against itself][1] (Trivia: they only started using Swift recently, but for other tasks.)

别想对这个二进制文件进行静态分析。这是他们在高层次上所做的事情：破坏CFG（控制流图），死代码，库调用大多数都是动态的，并且所有生成令牌函数（我们称之为gen_token）及其被调用者的符号都已剥离。它们使用C而不是Objective-C实现，因为你总可以利用ObjC运行时反过来攻击自己（趣闻：他们最近才开始使用Swift，但是用于其他任务）。

### Indirect branches and opaque predicates | 间接分支和不透明谓词

Let’s take a look at the very first block in gen_token. The block loads some values from different sections of the binary and then:

让我们来看一下gen_token中的第一个块。该块从二进制文件的不同部分加载一些值，然后：

```asm
orr       w8,wzr,#0x3
cmp       x8,#0xb
orr       w9,wzr,#0x6
csel      x8,x9,x8,hi
adrp      x28,0x106941000
add       x28,x28,#0xe40 ; jump table
ldr       x8,[x28, x8, LSL #0x3]
br        x8
```

See the first two instructions. Why would they compare x8 with 0xb right after storing 0x3 in it? [Opaque predicates][2]. The csel condition will always be false, but that doesn’t matter, because as far as the disassembler is concerned, this is a condition, and conditions need to be evaluated at runtime. Replace every single jump (including legit conditions) with a similar block, and you’ve completely destroyed the CFG for any modern disassembler. Now Ghidra/IDA would be happy to display what it thinks is a small function with a tail call, which is in fact a huge function. I’ll give Ghidra that it’s able to calculate the address in br x8 but only for the first block (because that’s where it thinks the function ends). Now that’s a plugin idea: use emulation to calculate all the addresses in indirect branches with opaque predicates. I actually worked for a bit on implementing this but then that’s not even half the battle for this binary.

看一下前两个指令。为什么在将0x3存储到x8之后会立即将其与0xb进行比较？这是不透明谓词的应用。csel条件总是为false，但这并不重要，因为对于反汇编器来说，这是一个条件，并且需要在运行时评估条件。用类似的块替换每个跳转（包括合法条件），你已经完全破坏了任何现代反汇编器的CFG。现在Ghidra/IDA可以愉快地显示它认为是一个带有尾调用的小函数，实际上却是一个巨大的函数。我承认Ghidra能够计算br x8中地址，但只限于第一个块（因为它认为函数结束）。那么插件想法就出来了：使用仿真来计算具有不透明谓词的间接分支中所有地址。我曾经试图实现这个想法，但那甚至还没有完成二进制文件处理工作量的一半。

### Bogus instructions AKA dead code | 虚假指令，也称死代码

Every few blocks you’ll find a block that loads a global constant, does some complex-looking operations on it, then just discards it and branches to somewhere else. Those are just there to confuse you and are easily detectible once you see them for a couple of times, so it’s not much of a hindrance.

每隔几个块，你会发现有一个块加载了一个全局常量，对其进行一些看起来很复杂的操作，然后将其丢弃并跳转到其他地方。这些只是为了让你困惑而已，在看到它们几次后就很容易检测出来，所以不会造成太大的阻碍。

### Dynamic library calls | 动态库调用

To make the code as bland as possible, and to prevent you from making educated guesses when you see a call to SecItemCopyMatching for example, most library calls are dynamic.

为了让代码尽可能平淡无奇，并防止您在看到调用SecItemCopyMatching时做出有根据的猜测，大多数库调用都是动态的。

So for example instead of a simple bl SecItemCopyMatching, they would do:

因此，例如，他们不会使用简单的bl SecItemCopyMatching，而是：

```asm
adrp x23 <address of SecItemCopyMatching>
```

Then, in another block they would:

```asm
blr x23
```

The disassembler doesn’t know the value of x23 here because, as stated above, it treats the block as if it doesn’t belong to the current function.

正如上面所述，反汇编器将该块视为不属于当前函数的一部分，因此无法确定x23的值。

### Loop unrolling | 循环展开

When you have a loop that comes with a pre-determined/fixed counter, you can get rid of the counter, and hardcode the loop iterations. This comes at a cost of the binary size, and it’s slightly faster than using a counter. Snap uses this technique in an encryption function. This block moves a huge array of bytes to another, notice how the offsets increment, replacing the counter:

当您有一个带有预定/固定计数器的循环时，可以摆脱计数器，并硬编码循环迭代。这会增加二进制文件大小的成本，但比使用计数器略快。Snap在加密函数中使用了这种技术。此块将大量字节移动到另一个数组中，请注意偏移量如何递增以替换计数器：

```asm
ldr        w8,[sp, #0x278]
str        w8,[sp, #0x226c]
ldr        w8,[sp, #0x27c]
str        w8,[sp, #0x2268]
ldr        w8,[sp, #0x280]
str        w8,[sp, #0x2264]
ldr        w8,[sp, #0x284]
str        w8,[sp, #0x2260]
ldr        w8,[sp, #0x288]
str        w8,[sp, #0x225c]
ldr        w8,[sp, #0x28c]
str        w8,[sp, #0x2258]
ldr        w8,[sp, #0x290]
str        w8,[sp, #0x2254]
; and so on
```

### Joint functions | 联合函数

Suppose you have a function that fills some structure with the right data and another that converts bytes to ASCII:

假设您有一个函数，用于填充某些结构体的正确数据，另一个函数将字节转换为ASCII：

```c
void set_struct_fields(some_struct *p);
void bin2ascii(char *in, char *out, size_t nbytes);
```

With a little effort you could intercept calls to both and understand what they do just by watching their behavior. Snapchat has quite a clever way of thwarting this. Instead of the two above, there would be:

只要稍加努力，您就可以拦截这两个应用程序的通话并通过观察它们的行为来理解它们的功能。Snapchat有一种相当聪明的方法来防止这种情况发生。与上述两者不同，它会采取以下方式：

```c
void joint_function(uint64_t function_id, void *retval, void *argv[]) {
    switch (function_id) {
        case SET_STRUCT_FIELDS_FI:
            // Get argument from argv
            set_struct_fields(p);
            break;
        case BINS2ASCII_FI:
            bin2sacii(in, out, nbytes);
            break;
        // etc
    }
}
```

argv would include all the arguments needed. Now strip all symbols, add the above obfuscations and you’ve got an unintelligble mammoth of a function. You would think that you could still trace all calls to the joint function and treat the function_id as an identifier to the function you’re interested in. But breakpoints won’t act as you’d expect them to. See next.

argv将包含所有所需的参数。现在剥离所有符号，添加上述混淆，你就得到了一个难以理解的庞然大物函数。你可能认为仍然可以跟踪对联合函数的所有调用，并将function_id视为您感兴趣的函数的标识符。但断点不会按照您预期的方式起作用。请参见下一步。

## The solution: not breakpoints (AKA anti-debugging measures) | 解决方案：不允许断点（也就是反调试措施）

Now most control flow obfuscation is against static analysis, using a debugger to get past the above would do it. Not so fast. Most functions call an anti-debugging function, which I named appropriately and whose signature is:

现在大多数控制流混淆都是针对静态分析的，使用调试器来绕过上述问题。但不要太快。大多数函数调用反调试功能，我适当地命名了其签名为：

```c
uint64_t fuckup_debugging(/* some args */, void *func);
```

There’s at least 9 such functions, all the same behavior. I haven’t taken the time to reverse them but their behavior is clear. 

至少有9个这样的函数，行为都相同。我还没有花时间去逆向它们，但它们的行为是清晰明了的。

Software breakpoints work by patching the instruction at the designated address in memory. The patch is an instruction that triggers an interrupt that’s handled by the parent process, [the debugger][3]. That makes them easily detectable; if you have a checksum of what a certain area in memory looks like, a breakpoint in that area will invalidate the checksum. Or, you could look for the interrupt instruction’s (brk) bytes in the binary.

软件断点通过在内存中指定地址处修补指令来工作。该修补程序是一个触发由父进程（调试器）处理的中断的指令。这使得它们很容易被检测到；如果您有某个特定内存区域外观的校验和，则该区域中的断点将使校验和无效。或者，您可以在二进制文件中查找中断指令（brk）字节。

After doing its check, fuckup_debugging will return a uint64_t, its value which depends on whether there was a breakpoint detected. So actually there’s only two possible values. Isn’t that called a bool? Yes. But a boolean would be trivial to patch. But with an int you can’t guess the “right” value. The fuckup_debugging caller uses the return value (I’ll call it the path_key) to load an address from a jump table, if there was a breakpoint, the fetched address would lead to an infinite loop, leading the app to just keep loading with no feedback, which is the right way to do it.

完成其检查后，fuckup_debugging将返回一个uint64_t值，其取决于是否检测到了断点。因此实际上只有两种可能的值。那不就叫做布尔型吗？是啊。但布尔类型很容易被修补程序所破解。而使用int则无法猜出“正确”的值。fuckup_debugging调用方使用返回值（我称之为path_key）从跳转表加载地址，如果存在断点，则获取到的地址将导致无限循环，并使应用程序继续加载而没有任何反馈信号，这才是正确操作。

## Data flow obufscations | 数据流混淆

Data obfuscation is one of the harder things to work with in this binary.
Here we have lots of MBA (mixed-boolean arithmetic) and scratch arguments passed to functions just to distract you.

数据混淆是在这个二进制文件中最难处理的问题之一。
我们有很多MBA（混合布尔运算）和scratch参数传递给函数，只是为了让你分心。

### Mixed-boolean arithmetic | 混合布尔算术

One of the less resarched areas in obfuscation techniques is MBA (shoutout to the awesome [Quarkslab][4] for their research on this and many other things). Those are typically used in cryptography but can be utilized for obufscation. Basically they’re expressions that mix logical operations with pure arithmetic. For example, x = (a ^ b) + (a & b).

在混淆技术中，较少研究的领域之一是MBA（向Quarkslab致敬，感谢他们对此及其他许多事情的研究）。这些通常用于密码学，但也可用于混淆。基本上它们是将逻辑运算与纯算术相结合的表达式。例如：x = (a ^ b) + (a & b)。

The interesting thing about those here is identities, for example x + y can be re-written as [(x ^ y) + 2 * (x & y)][5]. Now imagine how huge the simple x + y expression could get if you substituted each term recursively with its MBA equivalent, crazy stuff.

有趣之处在于这些身份证明，例如x+y可以重写为(x^y)+2*(x&y)5。现在想象一下如果您递归地使用每个项的MBA等效项替换简单的x+y表达式会变得多么庞大和复杂。

An example in assembly. All what that block does is timestamp * 1000:

以下是汇编示例。该块所做的全部工作就是时间戳*1000：

```asm
add        x0,sp,#0x1b8             ; struct timeval *tval
mov        x1,#0x0                  ; struct timezonze *tzone
adrp       x8,0x109499000
ldr        x8,[x8, #0x1d0]
blr        x8                       ; gettimeofday(tval, tone)
ldr        x8,[sp, #0x1b8]          ; tval->tv_sec
mov        w9,#0x3e8
mul        x8,x8,x9
ldrsw      x9,[sp, #0x1c0]
lsr        x9,x9,#0x3
mov        x10,#0xf7cf
movk       x10,#0xe353, LSL #16
movk       x10,#0x9ba5, LSL #32
movk       x10,#0x20c4, LSL #48
umulh      x9,x9,x10
mov        x10,#0xe6b3
movk       x10,#0x7dba, LSL #16
movk       x10,#0xecfa, LSL #32
movk       x10,#0xd0e1, LSL #48
add        x9,x10,x9, LSR #0x4
orr        x11,x9,x8
lsl        x11,x11,#0x1
eor        x8,x9,x8
sub        x8,x11,x8
eor        x9,x8,x10
mov        x10,#0xe6b3
movk       x10,#0x7dba, LSL #16
movk       x10,#0xecfa, LSL #32
movk       x10,#0x50e1, LSL #48
bic        x8,x10,x8
sub        x8,x9,x8, LSL #0x1     ; effectively tv_sec *= 1000
```

### Scratch arguments | Scratch参数

This one isn’t very prevalent in the binary but it’s still interesting to mention. I’ve seen it used in a function that reads the first 8 bytes at a pointer. It has the signature:

这个在二进制中并不是很普遍，但还是值得一提的。我曾经看到它被用于读取指针处前8个字节的函数中。其签名为：

```c
uint64_t get_first_qword(uint64_t scratch1, void *src, uint64_t scratch2);
```

scratch1 and 2 are overwritten without being used at all, again, there to slow you down a bit.

scratch1和scratch2根本没有被使用，只是为了让你稍微慢下来。

## Clever shit/time buyers | 聪明的人/时间买家

### In-house memmove? | 自实现 memmove

To make your life even more miserable, Snap ocassionally deprives you of recognizing some basic standard lib functions, namely memmove, by implementing their own, or maybe just copying the source. You won’t be very happy after spending a day or two reversing a function to find it’s memmove in the end.

为了让你的生活更加痛苦，Snap偶尔会剥夺你识别一些基本标准库函数的能力，比如memmove，他们实现了自己的版本，或者只是复制了源代码。在花费一两天时间反向一个函数后最终发现它其实是memmove时，你肯定不会很开心。

### Loading by overflowing | 溢出式加载

Another honorary mention. This one has a base address and an index and it loads bytes from an array using a loop. Instead of simply adding the base address to the counter to get the byte, they do a calculation that yields two big 64-bit integers that will overflow but whose sum will be equivalent to the simple calculation. So instead of:

另一个荣誉提名。这个有一个基地址和一个索引，它使用循环从数组中加载字节。他们不是简单地将基地址加到计数器上以获取字节，而是进行了一种计算，得出两个大的64位整数，虽然会溢出但其总和等同于简单的计算结果。所以不再是：

```asm
add        x10, sp, #0x338             ;base
ldr        x9, [sp, #0x270]            ;counter
ldrb       w9, [x10, x9]    
```          

They do:

他们这样做：

```asm
add        x10, sp, #0x338              ;base
ldr        x9,[sp, #0x270]              ;counter
mov        x11,#0x5bdd
movk       x11,#0x7d38, LSL #16
movk       x11,#0x1e74, LSL #32
movk       x11,#0x6d7c, LSL #48
add        x9,x9,x11
mov        x12,#0x3f94
movk       x12,#0x7886, LSL #16
movk       x12,#0xf6b2, LSL #32
movk       x12,#0xb119, LSL #48
add        x9,x9,x12
sub        x9,x9,x11
add        x9,x9,#0x10
mov        x11,#0xd943
movk       x11,#0xb8b5, LSL #16
movk       x11,#0x5fd9, LSL #32
movk       x11,#0x6bd2, LSL #48       ; x11 = 0x6bd25fd9b8b5d943
sub        x9,x9,x11
sub        x9,x9,x12
add        x9,x10,x9                  ; x9 = 0x942da027b272bb75
ldrb       w9,[x9, x11]               ; overflowing sum but right stack offset
```

### __mod_init_func

In Mach-O binaries, functions whose pointers are in the __mod_init_func section run before main. Using otool to see how many of those are in Snap, we find a staggering 816 functions:

在 Mach-O 二进制文件中，指针位于 __mod_init_func 段的函数会在 main 函数之前运行。使用 otool 工具查看 Snap 中有多少个这样的函数，我们发现有惊人的 816 个函数：

```bash
$ otool -s __DATA __mod_init_func Snapchat
```

Snapchat:
Contents of (__DATA,__mod_init_func) section

```text
0000000106819610	0042de58 00000001 0042de58 00000001
0000000106819620	0042de58 00000001 0042de58 00000001
0000000106819630	0042de58 00000001 0042de58 00000001
0000000106819640	0042de58 00000001 0042de58 00000001
0000000106819650	0042de58 00000001 0042de58 00000001
0000000106819660	0042de58 00000001 0042de58 00000001
0000000106819670	0042de58 00000001 0042de58 00000001
0000000106819680	0042de58 00000001 0042de58 00000001
0000000106819690	0042de58 00000001 0042de58 00000001
00000001068196a0	0042de58 00000001 0042de58 00000001
...and a lot more
```

Hmm, seems too much to count manually. Let’s wc it:

嗯，手动计数太麻烦了。让我们用 wc 命令：

```bash
$ otool -s __DATA __mod_init_func Snapchat | wc -l
     410
```

And since it’s two function pointers per line, their actual number is 816 (after discarding the first two lines). But wait, all of those point to the same function? They’re probably using duplicates as a distraction and to make your job harder, let’s see how many are there. After doing some regex to get the functions pointers, I found there’s 769 unique functions, still a huge number.

由于每行有两个函数指针，实际数量为816（舍弃前两行）。但是等等，它们全部指向同一个函数？它们可能使用重复项来分散注意力并使您的工作更加困难。让我们看看有多少个。通过一些正则表达式获取函数指针后，我发现有769个唯一的函数，仍然是一个巨大的数字。

```bash
$ cat mod_init_func | sort -u | wc -l
     769
```

Some of those are dummy functions that do nothing useful. For example the very first one loads a constant, stores it on the stack, then discards it and returns:

其中一些是无用的虚拟函数。例如，第一个函数加载一个常量，将其存储在堆栈上，然后丢弃它并返回：

```asm
sub        sp,sp,#0x10
adrp       x8,0x10641a000
add        x8,x8,#0x340
str        x8,[sp, #0x8]
add        sp,sp,#0x10
ret
```

Among those 769 functions some will definitely be doing some real initializations, and some could be there as another stealthy jailbreak/debugger detection. Filtering out the dummies should be easy, but we’re still talking about 700+ function, so to find the ones you’re interested in you’ll have to have some idea about how Snap is doing it, so you can get there without having to sift throught all those functions.

在这769个函数中，有些肯定会进行一些真正的初始化操作，而有些可能只是作为另一个隐蔽的越狱/调试器检测。过滤掉虚假函数应该很容易，但我们仍然需要处理700多个函数，所以要找到你感兴趣的那些函数，你必须对Snap是如何实现它有一些想法，这样就可以不必筛选所有这些函数。

## What’s next | 下一步如何

I’ll probably do a part II on how to bypass all of this.

我可能会写第二部分，介绍如何绕过所有这些。

> 注：本文使用 ChatGPT 翻译，人工较正，如有不当之处，欢迎指正！

[1]: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtHowMessagingWorks.html#//apple_ref/doc/uid/TP40008048-CH104-SW1
[2]: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtHowMessagingWorks.html#//apple_ref/doc/uid/TP40008048-CH104-SW1
[3]: https://eli.thegreenplace.net/2011/01/23/how-debuggers-work-part-1#id11
[4]: https://www.quarkslab.com/
[5]: https://blog.quarkslab.com/what-theoretical-tools-are-needed-to-simplify-mba-expressions.html
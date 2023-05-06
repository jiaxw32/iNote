# Reverse Engineering Snapchat (Part II): Deobfuscating the Undeobfuscatable

> 原文链接：https://hot3eed.github.io/2020/06/22/snap_p2_deobfuscation.html

## Black box | 黑盒

Many Hackernews users suggested using emulation to generate the token, treating the whole thing as a black box. The problem with this solution as I mentioned in a comment is that there’s way too many real device dependencies. X-Snapchat-Client-Auth-Token isn’t random gibberish. It contains lots of info about the device, encrypted. Even if you use [Corellium][0], I’ll just leave it at saying that the chances of it working are slim. I don’t see an alternative to reversing it.

许多Hackernews用户建议使用仿真来生成令牌，将整个过程视为黑盒子。但是，正如我在评论中提到的那样，这种解决方案存在太多实际设备依赖性。X-Snapchat-Client-Auth-Token不是随机的无意义字符串。它包含有关加密设备的大量信息。即使您使用Corellium，我只能说其工作机会很小。我认为没有其他选择除了对其进行反向操作。

## Deoptimizing optimizations | 反优化

First of all how is all this monstrosity achieved? When you compile hello.c using clang, clang is just the front end, llvm is the real deal; meaning clang takes the C source and converts it to an [intermediate representation (IR)][1], llvm then interprets this IR, optimizes and compiles it to machine code. The advantage of this system is that the backend remains language-agonstic, you just write an LLVM-IR-compatible-front end for each language and leave the rest to llvm. Now what we’re interested in is optimizations AKA optimization passes. llvm operates on the IR to generate more efficient code, which might look a bit different in assembly than what you expect.

首先，这个怪物是如何实现的呢？当你使用clang编译hello.c时，clang只是前端，真正的操作在llvm中进行；也就是说，clang将C源代码转换为中间表示（IR），然后llvm解释这个IR，并对其进行优化和编译成机器码。这种系统的优点在于后端保持了语言无关性，你只需要为每种语言编写一个LLVM-IR兼容的前端即可让剩下的工作交给llvm。现在我们感兴趣的是优化——也就是所谓的“优化通道”。LLVM通过对IR进行操作来生成更高效的代码，在汇编中可能会与您预期有些不同。

That’s where obfuscation comes; instead of actually optimizing the code, we can change it however we want as long as we keep the semantics. That’s how [O-LLVM][2] works; at the compiler level, because no one can maintain source code like that. ([The team behind O-LLVM is now acquired by Snap][3]) 

而混淆技术则可以改变代码以达到混淆目标而不必实际上对其进行任何优化。O-LLVM 就利用了这一点；因为没有人能像那样维护源代码。（O-LLVM团队现已被Snap收购）

If we understand the obfuscations can’t we just do the reverse and generate something that resembles the original assembly? As well articulated by [one Hackernews user][4], obfuscation is mostly lossy; deobfuscate all you want (many cool [libraries][5] allow you to do this), but you’re way better off getting your hands dirty with the binary directly.

如果我们理解了混淆技术，难道不能反向生成类似原始汇编码吗？正如Hackernews用户所表述得那样：大多数情况下, 混淆都具有损失性; 无论你如何去除它们 (很多酷炫库都可以做到)，但直接处理二进制文件会更好。

## “Evan Spiegel Hates This Trick!”: or, How to Bypass the Breakpoint Check

> “Evan Spiegel” 指 Snap Inc. 的创始人之一 Evan Spiegel。他可能不喜欢某些黑客使用的技巧来绕过软件程序的安全检查。

This might end my Snapchat reversing career (or the whole post really). One of the biggest hurdles with this binary is fuckup_debugging. You won’t be able to do any kind of dynamic analysis (which is the only way to go in this binary in my opinion) because of it. And you can’t patch fuckup_debugging to return the right path_key so that it takes the right execution and not the infinite loop because there are anti-tamepring checks to stop you from communicating with the server in a modified binary. But first how do you even get the right path_key, by defnition you’ll have to set a breakpoint so that you can get to fuckup_debugging in the first place? Is it a dead lock? Let’s see it in action:
Here we’re in the function that returns the token, this is the block that calls fuckup_debugging, I know that because when I debug it, the block right after that is an infinite loop.

这可能会结束我的Snapchat反向工程生涯（或整篇文章）。这个二进制文件最大的障碍之一是fuckup_debugging。由于存在防篡改检查以阻止您在修改后的二进制文件中与服务器通信，因此您将无法进行任何动态分析（在我看来，这是唯一可行的方法）。而且你不能修补fuckup_debugging以返回正确的path_key，使其执行正确路径而不是无限循环。但首先，如何获取正确的path_key？根据定义，您必须设置断点才能首先到达fuckup_debugging吗？它是否死锁了？让我们看看它实际操作：

```asm
mov        x8,#0x4458
movk       x8,#0x1e6, LSL #16
movk       x8,#0x1, LSL #32
movk       x8,#0x0, LSL #48
mov        x9,#0x4714
movk       x9,#0x1e6, LSL #16
movk       x9,#0x1, LSL #32
movk       x9,#0x0, LSL #48
add        x1,x8,x27                    ; arg1 = func pointer
add        x2,x9,x27                    ; arg2 = another func pointer
mov        w0,#0xad51 
movk       w0,#0xeb37, LSL #16          ; arg3 = don't care
blr        x24                          ; fuckup_debugging called
adrp       x8,0x109e5b000
ldr        w8,[x8, #0x6a8]
eor        w8,w8,w0                     ; returned path_key
cmp        x8,#0xb
orr        w9,wzr,#0x6
csel       x8,x9,x8,hi
ldr        x8,[x28, x8, LSL #0x3]
br         x8
```

So how do you “hide” breakpoints from fuckup_debugging?

1. Set a breakpoint right before it’s called.
2. Disable this breakpoint (I disable all of them just in case):
    ```lldb
    (lldb) br dis
    ```
3. Single step inside fuckup_debugging.
    ```
    (lldb) si
    ```
4. Now as far as fuckup_debugging is concerned, no breakpoints exist.
5. Set a breakpoint before it returns and stop at it:
    ``` 
    (lldb) b <you know where>
    (lldb) c
    ```
6. Now you have the correct path_key in x0.
7. Profit.

那么你如何在 fuckup_debugging 中“隐藏”断点？

1. 在调用它之前设置一个断点。
2. 禁用此断点（我会禁用所有的断点以防万一）：
    ```lldb
    (lldb) br dis
    ```
3. 在fuckup_debugging内部单步执行。
    ```lldb
    (lldb) si
    ```
4. 现在，就fuckup_debugging而言，不存在任何断点。
5. 在返回之前设置一个断点并停止：
    ```lldb
    (lldb) b <you know where>
    (lldb) c
    ```
6. 现在你有了正确的path_key（路径键）x0。
7. 任务完成。

> “Profit”在这里是一个俚语，类似于“任务完成”，“目标达成”等表达方式。例如，“我终于通过考试了！profit！”（I finally passed the exam! Profit!)

A couple of gotchas here:

1. If you got smart like I did and after disabling all breakpoints, stepped over fuckup_debugging using `(lldb) ni` instead of single stepping, you’ll get an infinite loop, because you’ve just set another breakpoint. That’s because stepping over is essentially a breakpoint at the address of the next instruction. While single stepping has a sweet little ptrace command of its own ([PTRACE_SINGLESTEP][6]), or in other words it executes at the CPU level, no code patching.
2. The weakness of fuckup_debugging is that it doesn’t check breakpoints for itself. That’s why you’d be able to set a breakpoints inside it harmlessly. There, a new challenge for future Snap reverse engineers after they patch this.

这里有一些需要注意的地方：

1. 如果你像我一样聪明，禁用了所有断点，并使用`(lldb) ni`跳过 fuckup_debugging 函数而不是单步执行，那么你会陷入无限循环中，因为你刚刚设置了另一个断点。这是因为跳过操作本质上就是在下一条指令的地址处设置一个断点。而单步执行则具有自己甜美小巧的ptrace命令(PTRACE_SINGLESTEP),换句话说它在CPU级别上执行，没有代码修补。
2. fuckup_debugging 函数的弱点在于它不检查自身是否存在断点。这就是为什么你可以毫无危险地在其中设置断点。对于未来Snap逆向工程师来说，他们将面临新的挑战：修复此问题。

Now we’ve bypassed one breakpoint check for one function. Not every function in token generation is breakpoint-checked. But now for every check that you bypass using the above method, you can add a comment with the correct path key. So in the future it will be a matter of:

现在我们已经绕过了一个函数的断点检查。并非令牌生成中的每个函数都进行断点检查。但是，现在对于使用上述方法绕过的每个检查，您可以添加带有正确路径键的注释。因此，在将来：

```lldb
(lldb) ni
(lldb) po $x0 = <path_key>
```

We stepped over fuckup_debugging and patched the return value on the fly. We’re a bit slowed down because we’ll have to do this with every patched function, but now we can at least do some real debugging.

我们跨过了fuckup_debugging并即时修补了返回值。虽然我们需要对每个被修补的函数都这样做，但现在至少可以进行一些真正的调试。

## Getting what you want

Here’s what happens on a very high level with the token. We have the joint function gen_token, which calls set_token_params, which is a mammoth joint function that calls many other functions. Then the token is encrypted and returned from gen_token. To get info like this, you have to spend some time on the binary and make educated guesses until you have a rough big picture, then you can go for something specific, or a bottom-up approach to be concise. Let’s go over an example of how you would reverse a specific token parameter.

仅从高层次上讲，Token 的处理过程如下。我们有一个名为 gen_token 的联合函数，它调用 set_token_params 函数，这是一个庞大的联合函数，调用了许多其他函数。然后 Token 被加密并从 gen_token 返回。要获取此类信息，您必须花费一些时间在二进制文件上，并进行猜测直到您有一个粗略的大局图，然后可以采取特定的方法或自下而上的方法来简洁地实现目标。接下来我们将介绍如何逆向具体 Token 参数的示例。

### Anchor addresses

Having bookmarks in critical areas of the binary will save you lots of time and headache. For example I had bookmarks where the token params are being written, right before the token is encrypted, etc. That way I can start working on a certain parameter just by knowing its offset in the token structure, since that’s the closest trace I know to where it’s generated. But how do you find these anchor addresses in the first place?

在二进制文件的关键区域设置书签可以节省大量时间和麻烦。例如，我在令牌参数被写入、令牌加密之前等位置设置了书签。这样一来，我只需知道该参数在令牌结构中的偏移量，就能开始处理它，因为那是我所知道的最接近生成该参数的跟踪点。但是你如何找到这些锚定地址呢？

### Watchpoints are underrated/观察点被低估了

If you asked me to give you only one word that will solve more than half of your problems with the Snap binary, I would tell you: watchpoints. For example you have no idea where to start with anything, but you know that gen_token returns the token’s pointer, so that’s your lead. You then trace gen_token before it returns, and you find that this pointer is actually written to by another function before being returned by gen_token, say the equivalent C code:

如果你让我只选一个词来解决Snap二进制文件中一半以上的问题，我会告诉你：观察点。例如，你不知道从哪里开始处理任何东西，但是你知道gen_token返回令牌指针，这就是你的线索。然后，在它返回之前跟踪gen_token，并发现在被gen_token返回之前实际上由另一个函数写入了该指针，比如等效的C代码：

```c
char *gen_token() {
    // Do stuff

    char token_out[TOKEN_LEN];
    real_deal(token_out);

    return token_out;
}
```

Now before real_deal is called, you set a watchpoint on token_out, disable all breakpoints so that fuckup_debugging is happy, continue execution, then the watchpoint will stop the process as it’s being written to/read from, getting you to a possibly critical point of the code that you can use as an anchor. There’s my second ace with the Snap binary.

现在，在调用real_deal之前，您需要在token_out上设置一个监视点，并禁用所有断点，以使fuckup_debugging感到满意。然后继续执行，监视点将在写入/读取时停止进程，让您到达可能关键的代码点作为锚定。这是我分析Snap二进制的第二个王牌。

```lldb
(lldb) w s e -w write -- $x0
(lldb) c
```

... Now it will stop as soon as the address at $x0 is accessed and you have your anchor address.

现在只要访问$x0地址，它就会停止，并且您将获得锚点地址

### No trick is too dirty

Watchpoints are nice and all, but what about registers? You can’t set a watchpoints on those, or in theory you could, but that’s for another time. So what if the value you’re interested in is in a register? The answer is an execution trace and a text editor that supports regex.

观察点很好，但是寄存器呢？你不能在它们上面设置观察点，或者理论上可以，但那是另一回事了。那么如果您感兴趣的值在一个寄存器中怎么办？答案是执行跟踪和支持正则表达式的文本编辑器。

Suppose we’re in set_token_params and we know that the value we’re interested in is in x2:

假设我们正在set_token_params函数中，并且我们知道我们感兴趣的值在x2中：

```asm
ldr        x9,[sp, #0x80]	; token parameter offset
str        x2,[x9]		; token parameter	
; other instructions..
```

Since that’s the start of the block and there’s no CFG, we have no idea where x2 came from.

由于这是该块的开头且没有CFG，我们不知道x2来自哪里。

What I did is I generated an execution trace using [Frida’s Stalker][7] from a point near set_token_params enough and one that I know isn’t policed by fuckup_debugging; because Frida patches instructions to hook to functions, which will trigger the breakpoints check. Now I had a sequential execution trace. Then I used a good old text editor to find the above block, and searched for points before it where x2 is written to, where the source of the data is.

我的做法是使用Frida的Stalker从set_token_params附近生成执行跟踪，并选择一个我知道不受fuckup_debugging监管的点；因为Frida会修补指令以钩住函数，这将触发断点检查。现在我有了一个顺序执行跟踪。然后我使用传统文本编辑器找到上述块，并搜索它之前写入x2的位置，即数据来源。

### Dreams of Assembly

Once you find that a certain paramter is generated by the function gen_param1, I see no other way but to reverse it to its high level source code equivalent. I see C (haha) as the best fit for this as you can accurately translate data structures/types from assembly to C. And as close as C is to the CPU, you still have to know how struct alignment works, make educated guesses about certain values and their types, and keep track of all stack offsets. I had dreams of assembly instructions while working on this binary, no shit.

一旦您发现某个参数是由函数gen_param1生成的，我认为除了将其逆向转换为高级源代码等效形式外，别无他法。 我认为C语言（哈哈）最适合此项工作，因为您可以准确地将数据结构/类型从汇编翻译成C语言。 虽然C与CPU非常接近，但仍然需要了解结构对齐方式、对某些值及其类型进行有根据的猜测，并跟踪所有堆栈偏移量。 在处理这个二进制文件时，我曾经梦见过汇编指令。

### MBA, again

MBA expressions are the trickiest thing in this binary. [The latest research][8] on MBA says that there are effectively two ways to simplify MBA expressions. Let’s explain them then give an example from the binary.

MBA表达式是这个二进制中最棘手的事情。最新的MBA研究表明，简化MBA表达式实际上有两种方法。让我们解释一下，然后从二进制中举一个例子。

#### Synthesis

In this [method][9] you treat the whole expression as a black box “oracle”, you give it input, observe the output, and try to generate a function simulating that behavior. 
The biggest problem with this is that it’s impractical for [complex expressions][8].

在这种方法中，您将整个表达式视为黑盒“oracle”，输入数据并观察输出结果，然后尝试生成一个模拟该行为的函数。
最大的问题是对于复杂表达式来说这是不切实际的。

#### Re-write rules

In this method all the rules for simplification is hardcoded, so for example you have a rule that says:

在这种方法中，所有简化规则都是硬编码的，例如您有这样一个规则：

```text
(x | y) - y + (~x & y) == x ^ y.
```

Then you try to match the rules with the expression recursively, after which you use an SMT solver to prove that the original expressions is identical to the simplified tone.

然后你尝试递归地将规则与表达式匹配，之后使用SMT求解器证明原始表达式与简化的语调相同。

The problem with this is that the rules aren’t universal like boolean/algebraic simplification, so it won’t be able to handle expressions outside the hardcoded ones.

这种方法的问题在于规则不像布尔/代数简化那样通用，因此它无法处理硬编码以外的表达式。

#### Standing on the shoulders of giants

The first step to this is extracting the expressions from the binary, we can do it using [symbolic execution][10]. Which is basically a way of executing the binary where we don’t assign concrete values to variables, only symbols. A good fit for this is the awesome [Triton][11] framework. After extracting the expressions, for synthesis you could still use [Triton][12], and for re-write rules there exists [SSPAM][13] by Quarkslab, which is Python 2 only.

首先，我们需要从二进制文件中提取表达式。这可以通过符号执行来完成。符号执行是一种在执行二进制文件时不为变量分配具体值而只使用符号的方法。一个很好的工具是Triton框架。在提取表达式后，您仍然可以使用Triton进行综合，并且对于重写规则，Quarkslab开发了Python 2版本的SSPAM。

#### MBA simplification example

This example involves a 120+ instruction block, whose input is two values from the stack, and whose output is in 4 registers. The trickiest output is in x27, so we’ll do that one. First we need to extract the expressions. We symbolize the block’s input using Triton.symbolizeMemory, then after emulating the block, we get the full expression in the register using Triton.getSymbolicRegister(x27).regAst().unroll(), which, brace yourselves, prints to:

这个例子涉及一个120+指令块，其输入是来自堆栈的两个值，输出在4个寄存器中。最棘手的输出在x27中，所以我们将从那里开始。首先需要提取表达式。我们使用Triton.symbolizeMemory符号化块的输入，然后在模拟块之后，使用Triton.getSymbolicRegister(x27).regAst().unroll()获取寄存器中的完整表达式, 这会打印出：

```text
((((((((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xc92460b4173d8ad1) | ((~((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff))) & 0xffffffffffffffff) & (~(0xc92460b4173d8ad1) & 0xffffffffffffffff))) ^ ((0xc92460b4173d8ad1 & (~((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xffffffffffffffff)) | ((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff) & (~(0xc92460b4173d8ad1) & 0xffffffffffffffff)))) | (~(((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff)) | (~((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xffffffffffffffff))) & 0xffffffffffffffff)) | 0x253a41858a5c76d6) - ((((((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xc92460b4173d8ad1) | ((~((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff))) & 0xffffffffffffffff) & (~(0xc92460b4173d8ad1) & 0xffffffffffffffff))) ^ ((0xc92460b4173d8ad1 & (~((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xffffffffffffffff)) | ((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff) & (~(0xc92460b4173d8ad1) & 0xffffffffffffffff)))) | (~(((0x431e33362537db49 | (~((~(0xbac03a4c7e26a10c ^ ((0xbac03a4c7e26a10c & (~(bss_val1) & 0xffffffffffffffff)) | (bss_val1 & (~(0xbac03a4c7e26a10c) & 0xffffffffffffffff)))) & 0xffffffffffffffff)) & 0xffffffffffffffff)) | (~((((0x431e33362537db4a | (~(bss_val1) & 0xffffffffffffffff)) - (~(bss_val1) & 0xffffffffffffffff)) & 0xffffffffffffffff)) & 0xffffffffffffffff))) & 0xffffffffffffffff)) & 0x253a41858a5c76d6)) & 0xffffffffffffffff)
```

The real expression is less scary than that because Triton adds bit masks. Let’s see what SSPAM has to say:

真实表达并不像那么可怕，因为Triton添加了位掩码。让我们看看SSPAM的说法：

```text
$ sspam "`cat x27_exprs`"
((((((4836359357488159561L | (~ (~ (13456819786791428364L ^ ((13456819786791428364L & (~ bss_val1)) | (bss_val1 & 4989924286918123251L)))))) & 14493815827385387729L) | ((~ (4836359357488159561L | (~ (~ (13456819786791428364L ^ ((13456819786791428364L & (~ bss_val1)) | (bss_val1 & 4989924286918123251L))))))) & 3952928246324163886L)) ^ ((14493815827385387729L & (~ ((- (~ bss_val1)) + (4836359357488159562L | (~ bss_val1))))) | (((- (~ bss_val1)) + (4836359357488159562L | (~ bss_val1))) & 3952928246324163886L))) | (~ ((4836359357488159561L | (~ (~ (13456819786791428364L ^ ((13456819786791428364L & (~ bss_val1)) | (bss_val1 & 4989924286918123251L)))))) | (~ ((- (~ bss_val1)) + (4836359357488159562L | (~ bss_val1))))))) ^ 2682528569860323030L)
```

That’s not too good. So SSPAM, the only tool that I know to exist for MBA re-write rules, didn’t give a meaningful simplification. So I thought let’s try some synthesis, I used Python’s eval to plug in different inputs to this expression and see how the bits in the output react (try it yourself, it’s fun). In the end my synthesized expression was:

这不太好。所以，我知道的 MBA 重写规则唯一工具 SSPAM 并没有给出有意义的简化。因此，我想尝试一些综合方法，使用 Python 的 eval 将不同的输入插入到该表达式中，并观察输出中的位如何反应（你也可以自己尝试一下，很有趣）。最终我的综合表达式是：

```text
0x99DB8D4C50945260 ^ bss_val1 & ~0x3
```

Can’t see it getting simpler than this, but is it identical to the obfuscated expression? Let’s ask Z3:

看起来再简单不过了，但它和混淆表达式完全相同吗？让我们问问Z3：

```text
>>> z3.prove(obfsc_expr == simp_expr)
```

proved
证明了
Bingo!
耶！

EDIT: @adriengnt brought to my attention Arybo which he worked on at Quarkslab (they seem to have a monopoly on MBA). It was able to simplify the expression above in one [go][14]. I’d say this is state of the art as far as MBA obfuscation goes. Its [concepts][15] are interesting if you wanna get technical.

编辑：@adriengnt提醒我Quarkslab的Arybo，他在那里工作（他们似乎垄断了MBA）。它能够一次性简化上面的表达式。我认为这是目前最先进的MBA混淆技术。如果你想要技术方面的内容，它的概念很有趣。

## We cool, Snap?

There’s much more to token generation than obfuscations. Being able to work with the binary at this level is only half the battle. I won’t disclose how to communicate with the API, because if Godfather has taught us anything, it’s that the perfect number of sequels is one.

令牌生成不仅涉及混淆。能够在这个级别上处理二进制文件只是战斗的一半。我不会透露如何与API通信，因为如果教父电影告诉我们任何事情，那就是完美的续集数量只有一个。

> 注：本文使用 ChatGPT 翻译，如有不当之处，欢迎指正！

[0]: https://www.corellium.com/
[1]: https://releases.llvm.org/2.6/docs/tutorial/JITTutorial1.html
[2]: https://github.com/obfuscator-llvm/obfuscator/wiki/Bogus-Control-Flow
[3]: https://www.bloomberg.com/news/articles/2017-07-21/snap-hires-swiss-team-behind-software-protection-startup
[4]: https://news.ycombinator.com/item?id=23562878
[5]: https://github.com/ksluckow/awesome-symbolic-execution
[6]: https://www.man7.org/linux/man-pages/man2/ptrace.2.html
[7]: https://frida.re/docs/stalker/
[8]: https://dl.acm.org/doi/abs/10.1145/2995306.2995308?download=true
[9]: https://inria.hal.science/hal-01241356v2/document
[10]: https://en.wikipedia.org/wiki/Symbolic_execution
[11]: https://github.com/JonathanSalwan/Triton
[12]: https://github.com/JonathanSalwan/Triton/blob/master/src/examples/python/synthetizing_obfuscated_expressions.py
[13]: https://github.com/quarkslab/sspam
[14]: https://twitter.com/adriengnt/status/1274970522816851971
[15]: https://pythonhosted.org/arybo/concepts.html#sec-theory-esf
# Part 1 – SingPass RASP Analysis

> 原文链接：https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/

![](https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/featured.png)

## Introduction

I started to dig into the [SingPass][] application which turned out to be obfuscated and protected with Runtime Application Self-Protection (RASP).

我开始深入研究[SingPass][]应用程序，结果发现它被混淆并受到运行时应用自我保护（RASP）的保护。

Retrospectively, this application is pretty interesting to analyze RASP functionalities since:

1. It embeds advanced RASP functionalities (Jailbreak detection, Frida Stalker detection, …).
2. The native code is lightly obfuscated.
3. The application starts by showing an error message which is a good oracle to know whether we managed to circumvent the RASP detections.

回顾来看，这个应用程序非常有趣，可以分析RASP功能，因为：

1. 它嵌入了高级的RASP功能（越狱检测、Frida Stalker检测等）。
2. 本地代码轻度混淆。
3. 该应用程序首先显示一个错误消息，这是一个很好的预示，知道我们是否成功规避了RASP检测。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/SingPass-RASP.png)

> **Context**
> 
> All the findings and the details of this blog post has been shared with the editor of the obfuscator. The overall results have also been shared with SingPass. In addition, SingPass is part of a bug bounty program on HackerOne. Bypassing these RASP checks are a prerequisite to go further in the security assessment of this application.
>
> 本博客文章的所有发现和细节已与混淆器的编辑分享。总体结果也已与SingPass分享。此外，SingPass是HackerOne上漏洞赏金计划的一部分。绕过这些RASP检查是进一步进行该应用程序安全评估的先决条件。


By grepping some keywords in the install directory of the application, we actually get two results which reveal the name of the obfuscator:

通过在应用程序的安装目录中使用grep一些关键字，我们实际上得到了两个结果，揭示了混淆器的名称：

```
iPhone:/private/[...]/SingPass.app root# grep -Ri +++++++ *
Binary file Frameworks/NuDetectSDK.framework/NuDetectSDK matches
Binary file SingPass matches
```

The NuDetectSDK binary also uses the same obfuscator but it does not seem involved in the early jailbreak detection shown in the previous figure. On the other hand, SingPass is the main binary of the application and we can observe strings related to threat detections:

NuDetectSDK二进制文件也使用了相同的混淆器，但似乎与前面图中展示的早期越狱检测无关。另一方面，SingPass是应用程序的主要二进制文件，我们可以观察到与威胁检测相关的字符串：

```
$ SingPass.app strings ./SingPass|grep -i +++++++
+++++++ThreatLogAPI(headers:)
+++++++CallbackHandler(context:)
```

> **Binary**
> 
> For those who would like to follow this blog post with the original binary, you can download the decrypted SingPass Mach-O binary [here][1]. The name of the obfuscator has been redacted but it does not impact the content of the code.
>
> 对于那些想要使用原始二进制文件跟随本博客文章的人，您可以在此处下载已解密的SingPass Mach-O二进制文件。混淆器的名称已被删除，但这不会影响代码内容。

Unfortunately, the binary does not leak other strings that could help to identify where and how the application detects jailbroken devices but fortunately, the application does not crash …

不幸的是，二进制文件没有泄漏其他字符串，这些字符串可以帮助识别应用程序如何检测越狱设备以及在哪里进行检测。但幸运的是，该应用程序并不会崩溃...

If we assume that the obfuscator decrypts strings at runtime, we can try to dump the content of the `__data` section when the error message is displayed. At this point of the execution, the strings used for detecting jailbroken devices are likely decoded and clearly present in the memory.

如果我们假设混淆器在运行时解密字符串，则可以尝试在显示错误消息时转储__data部分的内容。在执行此操作时，用于检测越狱设备的字符串可能已被解码并清晰地存在于内存中。

> This is actually quite the same technique used in PokemonGO: [What About LIEF][]
>
> 这实际上是PokemonGO中使用的相同技术：[What About LIEF][]

1. We run the application and we wait for the jailbreak message
2. We attach to SingPass with Frida and we inject a library that:
   * Parses in-memory the SingPass binary (thanks to LIEF)
   * Dumps the content of the __data section
   * Write the dump in the iPhone’s /tmp directory

*** 

1. 我们运行应用程序并等待越狱消息。
2. 我们使用Frida连接到SingPass，并注入一个库：
     * 通过LIEF在内存中解析SingPass二进制文件
     * 转储__data部分的内容
     * 将转储写入iPhone的/tmp目录

Once the data section is dumped, we end up with the following changes in some parts of the `__data` section:
一旦数据部分被转储，我们会在 `__data` 部分的某些部分看到以下更改：

```text
__data:00000001010B97FA qword_1010B97FA DCQ 0x942752767D91608E
__data:00000001010B97FA
__data:00000001010B9802 byte_1010B9802  DCB 0x98
__data:00000001010B9802
__data:00000001010B9803 dword_1010B9803 DCD 0x2318E9A2
__data:00000001010B9803
__data:00000001010B9807                 DCQ 0x222AD8A21325DEE5
__data:00000001010B980F byte_1010B980F  DCB 0xE0
__data:00000001010B980F
__data:00000001010B9810 byte_1010B9810  DCB 0xE5
__data:00000001010B9810
__data:00000001010B9811 byte_1010B9811  DCB 0xB7
__data:00000001010B9811
__data:00000001010B9812 dword_1010B9812 DCD 0x8491650B
__data:00000001010B9812
__data:00000001010B9816                 DCQ 0xB7D0892EFAB11BBF
__data:00000001010B981E                 DCQ 0x4B9FF985643894C5
__data:00000001010B9826                 DCQ 0x38D0ABE65C497CF0
__data:00000001010B9826
__data:00000001010B982E                 DCQ 0xD769CDDBCB49C500
__data:00000001010B9836                 DCQ 0xF1C4BCB1A563CD53
__data:00000001010B983E                 DCD 0x52BB5CBC
__data:00000001010B9842 byte_1010B9842  DCB 0x42
__data:00000001010B9842
__data:00000001010B9843 dword_1010B9843 DCD 0x2451DD96
__data:00000001010B9843
__data:00000001010B9847                 DCQ 0x6248099506559926
__data:00000001010B984F                 DCD 0xFAF2AF09
__data:00000001010B9853 dword_1010B9853 DCD 0xD8B63318
__data:00000001010B9853
__data:00000001010B9857                 DCQ 0xD1CA2820CCC72C5F
__data:00000001010B985F                 DCQ 0xE7CE3B62D1C62F5E
__data:00000001010B9867                 DCD 0x77CE475E
__data:00000001010B986B dword_1010B986B DCD 0x7AB7291C
__data:00000001010B986B
__data:00000001010B986F                 DCQ 0x75C9251C6AC41E5F
__data:00000001010B9877                 DCQ 0x71CF165D64C42C4E
__data:00000001010B987F                 DCQ 0x6EC22E5133BA165C
__data:00000001010B9887 word_1010B9887  DCW 0xB54F
__data:00000001010B9887
__data:00000001010B9889 dword_1010B9889 DCD 0xDEDB09A0
__data:00000001010B9889
```

***

```text
__data:00000001010B97FA aTaurine        DCB "/taurine",0
__data:00000001010B97FA
__data:00000001010B9803 aTaurineCstmp   DCB "/taurine/cstmp",0
__data:00000001010B9803
__data:00000001010B9812 aTaurineJailbre DCB "/taurine/jailbreakd",0
__data:00000001010B9812
__data:00000001010B9812
__data:00000001010B9826                 DCD 0
__data:00000001010B982A aTaurineLaunchj DCB "/taurine/launchjailbreak",0
__data:00000001010B982A
__data:00000001010B982A
__data:00000001010B9843 aTaurineJbexec  DCB "/taurine/jbexec",0
__data:00000001010B9843
__data:00000001010B9853 aTaurineAmfideb DCB "/taurine/amfidebilitate",0
__data:00000001010B9853
__data:00000001010B9853
__data:00000001010B986B aTaurinePspawnP DCB "/taurine/pspawn_payload.dylib",0
__data:00000001010B986B
__data:00000001010B986B
__data:00000001010B9889 aInstalledTauri DCB "/.installed_taurine",0
__data:00000001010B9889
__data:00000001010B9889
```

[Fig 1. Slices of the __data section before and after the dump]()

> **Note**
> 
> The string encoding routines will be analyzed in the second part of this series of blog posts
> 
> 字符串编码例程将在本系列博客文章的第二部分中进行分析。

In addition, we can observe the following strings which seem to be related to the RASP functionalities of the obfuscator:

此外，我们可以观察到以下字符串似乎与混淆器的RASP功能相关：

```text
__data:1010B8D10 aEvtCodeTracing DCB "EVT_CODE_TRACING",0         ; XREF: on_rasp_detection
__data:1010B8D30 aEvtCodeSystemL DCB "EVT_CODE_SYSTEM_LIB",0      ; XREF: on_rasp_detection
__data:1010B8D50 aEvtCodeSymbolT DCB "EVT_CODE_SYMBOL_TABLE",0    ; XREF: on_rasp_detection
__data:1010B8D70 aEvtCodePrologu DCB "EVT_CODE_PROLOGUE",0        ; XREF: on_rasp_detection
__data:1010B8D90 aEvtAppLoadedLi DCB "EVT_APP_LOADED_LIBRARIES",0 ; XREF: on_rasp_detection
__data:1010B8DB0 aEvtAppSignatur DCB "EVT_APP_SIGNATURE",0        ; XREF: on_rasp_detection
__data:1010B8DD0 aEvtEnvDebugger DCB "EVT_ENV_DEBUGGER",0         ; XREF: on_rasp_detection
__data:1010B8DF0 aEvtEnvJailbrea DCB "EVT_ENV_JAILBREAK",0        ; XREF: on_rasp_detection
__data:1010B8E10 aUsersChinweeDe DCB "/Users/***/ndi-sp-mobile-ios-swift/SingPass/*******.swift",0
__data:1010B8E10                                                  ; XREF: on_rasp_detection
```

[Fig 2. Strings Related to the RASP Features]()

All the EVT_* strings are referenced by one **and only one** function that I named `on_rasp_detection`. This function turns out to be the threat detection callback used by the app’s developers to perform action(s) when a RASP event is triggered.

所有的EVT_*字符串都被一个名为on_rasp_detection的函数引用。这个函数是应用程序开发人员用来执行操作的威胁检测回调，当RASP事件触发时使用。

To better understand the logic of the checks behind these strings, let’s start with `EVT_CODE_PROLOGUE` which is used to detect hooked functions.

为了更好地理解这些字符串背后的检查逻辑，让我们从EVT_CODE_PROLOGUE开始，它用于检测挂钩函数。

## EVT_CODE_PROLOGUE: Hook Detection

While going through the assembly code closes to the cross-references of `on_rasp_detection`, we can spot several times this pattern:

在查看靠近on_rasp_detection交叉引用的汇编代码时，我们可以发现多次出现以下模式：

![](https://github.com/jiaxw32/iNote/blob/master/images/blog/SingPass-RASP/on_rasp_detection.png?raw=true)

To detect if a given function is hooked, the obfuscator loads the **first byte** of the function and compares this byte with the value 0xFF. 0xFF might seem – at first glance – arbitrary but it’s not. Actually, regular functions start with a prologue that allocates space on stack for saving registers defined by the calling convention and stack variables required by the function. In AArch64, this allocation can be performed in two ways:

为了检测给定函数是否被挂钩，混淆器会加载该函数的第一个字节，并将其与值0xFF进行比较。乍一看，0xFF可能似乎是任意选择的，但实际上并非如此。事实上，常规函数都以前奏部分开头，在该部分中会按照调用约定定义保存寄存器和所需栈变量所需的堆栈空间。在AArch64中，这种分配可以通过两种方式来执行：

```asm
stp REG, REG, [SP, 0xAA]!
; or
sub SP, SP, 0xBB
stp REG, REG, [SP, 0xCC]
```

These instructions are **not equivalent**, but somehow and with the good offsets, they could lead to the same result. In the second case, the instruction `sub SP, SP, #CST` is encoded with the following bytes:

这些指令并不等价，但是通过适当的偏移量，它们可以导致相同的结果。在第二种情况下，指令sub SP, SP, #CST被编码为以下字节：

```text
0xff ** 0x00 0xd1
```

As we can see, the encoding of this instruction starts with 0xFF. If it is not the case, then either the function starts with a different stack-allocation prologue or potentially starts with a hooking trampoline. Since the code of the application is compiled through obfuscator’s compiler, the compiler is able to distinguish these two cases and insert the right check for the correct function’s prologue.

我们可以看到，这条指令的编码以0xFF开头。如果不是这种情况，则函数可能以不同的堆栈分配序言开始，或者潜在地以钩子跳板开始。由于应用程序代码是通过混淆器的编译器编译的，因此编译器能够区分这两种情况，并插入正确检查正确函数序言的代码。

If the first byte of the instruction of the function does not pass the check, it jumps to the **red basic block**. The purpose of this basic block is to trigger a user-defined callback that will process the detection according to the application’s design and the developers’ choices:

* Printing an error
* Crashing the application
* Corrupting internal data
* …

如果函数指令的第一个字节未通过检查，则跳转到红色基本块。该基本块的目的是触发用户定义回调，根据应用程序设计和开发人员选择处理检测：

* 打印错误
* 使应用程序崩溃
* 损坏内部数据
* ...

From the previous figure, we can observe that the detection callback is loaded from **a static variable** located at `#hook_detect_cbk_ptr`. When calling this detection callback, the obfuscator provides the following information to the callback:

1. A detection code: `0x400` for `EVT_CODE_PROLOGUE`
2. A corrupted pointer which could be used to crash the application.

从上图中，我们可以观察到检测回调是从位于`＃hook_detect_cbk_ptr`的静态变量加载的。在调用此检测回调时，混淆器向回调提供以下信息：

* 一个检测代码：0x400表示EVT_CODE_PROLOGUE
* 一个已损坏的指针，可能会导致应用程序崩溃。

Let’s now take a closer look at the design of the detection callback(s) as a whole.

现在让我们更仔细地看一下整个检测回调的设计。

## Detection Callbacks

As explained in the previous section, when the obfuscator detects tampering, it reacts by calling a detection callback stored in the **static variable** at the address: `0x10109D760`

如前一节所述，混淆器在检测到篡改时会调用存储在静态变量地址 `0x10109D760` 处的检测回调函数。

```
__data:000000010109D758 off_10109D758       DCQ sub_100ED9F00
__data:000000010109D760 hook_detect_cbk_ptr DCQ hook_detect_cbk ; Hook Detection Callback
__data:000000010109D768 word_10109D768      DCW 0xDBE3
__data:000000010109D76A byte_10109D76A      DCB 1
__data:000000010109D76B byte_10109D76B      DCB 1
```

By statically analyzing `hook_detect_cbk`, the implementation seems to corrupt the pointer provided in the callback’s parameters. On the other hand, when running the application we observe a jailbreak detection message and not a crash of the application.

通过静态分析hook_detect_cbk函数，实现似乎会破坏回调参数中提供的指针。另一方面，在运行应用程序时，我们观察到越狱检测消息而不是应用程序崩溃。

If we look at the cross-references which read or write at this address, we get this list of instructions:

如果我们查看读取或写入此地址的交叉引用，我们将得到以下指令列表：

```asm
...
R init_and_check_rasp+1D8C   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
R init_and_check_rasp+1DE4   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
R init_and_check_rasp+1E3C   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
R init_and_check_rasp+1E94   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
R init_and_check_rasp+1EEC   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
R init_and_check_rasp+1F44   LDR   X8,  [X20,#hook_detect_cbk_ptr@PAGEOFF]
W init_and_check_rasp+01BC   STR   X23, [X20,#hook_detect_cbk_ptr@PAGEOFF]
```

So actually **only one** instruction – `init_and_check_rasp+01BC` – is **overwriting** the default detection callback with another function:

实际上只有一个指令 - `init_and_check_rasp+01BC` - 用另一个函数覆盖了默认的检测回调函数。

```asm
__text:0000000100ED7E4C ADRP            X8, #sub_100206C68@PAGE
__text:0000000100ED7E50 LDRB            W8, [X8,#sub_100206C68@PAGEOFF]
__text:0000000100ED7E54 ADRL            X23, hook_detect_cbk_user_def
__text:0000000100ED7E5C STR             X23, [X20,#hook_detect_cbk_ptr@PAGEOFF]
__text:0000000100ED7E60 CMP             W8, #0xFF
__text:0000000100ED7E64 B.EQ            loc_100ED7EB0
```

Compared to the default callback: `hook_detect_cbk`, the overridden function, `hook_detect_cbk_user_def` does not corrupt a pointer that would make the application crash. Instead, it calls the function `on_rasp_detection` which references all the strings EVT_CODE_TRACING, EVT_CODE_SYSTEM_LIB, etc, listed in the [figure 2]().

与默认回调函数hook_detect_cbk相比，被覆盖的函数hook_detect_cbk_user_def不会破坏指针，从而导致应用程序崩溃。它调用on_rasp_detection函数，该函数引用图2中列出的所有字符串EVT_CODE_TRACING、EVT_CODE_SYSTEM_LIB等。

> hook_detect_cbk_user_def is called on a RASP event. That’s why this application does not crash.
>
> hook_detect_cbk_user_def在RASP事件上被调用。这就是为什么该应用程序不会崩溃的原因。

By looking at the function `init_and_check_rasp` as a whole, we can notice that the `X23` register is also used to initialize other static variables:

通过整体查看init_and_check_rasp函数，我们可以注意到X23寄存器还用于初始化其他静态变量：

```
W 0x00100ED7E5C: STR   X23, [X20, #hook_detect_cbk_ptr@PAGEOFF]
W 0x00100ED81F0: STR   X23, [X25, #EVT_CODE_TRACING_cbk_ptr@PAGEOFF]
W 0x00100ED86A0: STR   X23, [X25, #EVT_CODE_SYMBOL_TABLE_cbk_ptr@PAGEOFF]
W 0x00100ED8B48: STR   X23, [X25, #EVT_CODE_SYSTEM_LIB_cbk_ptr@PAGEOFF]
W 0x00100ED8C64: STR   X23, [X24, #EVT_ENV_JAILBREAK_cbk_ptr@PAGEOFF]
W 0x00100ED8E40: STR   X23, [X24, #EVT_APP_SIGNATURE_cbk_ptr@PAGEOFF]
W 0x00100ED91D4: STR   X23, [X24, #EVT_ENV_DEBUGGER_cbk_ptr@PAGEOFF]
W 0x00100ED9408: STR   X23, [X24, #EVT_APP_LOADED_LIBRARIES_cbk_ptr@PAGEOFF]
W 0x00100ED9694: STR   X23, [X24, #EVT_APP_MACHO_cbk_ptr@PAGEOFF]
```

[Fig 3. X23 Writes Instructions]()

These memory writes mean that the callback `hook_detect_cbk_user_def` is used to initialize other static variables. In particular, these other static variables are likely used for the other RASP checks. By looking at the cross-references of these static variables `#EVT_CODE_TRACING_cbk_ptr`, `#EVT_ENV_JAILBREAK_cbk_ptr` etc, we can locate where the other RASP checks are performed and under which conditions they are triggered.

这些内存写入意味着回调函数 `hook_detect_cbk_user_def` 用于初始化其他静态变量。特别地，这些其他静态变量很可能被用于执行其他RASP检查。通过查看 `#EVT_CODE_TRACING_cbk_ptr`、`#EVT_ENV_JAILBREAK_cbk_ptr`等静态变量的交叉引用，我们可以定位其他RASP检查是在哪里执行以及在什么条件下触发。

## EVT_CODE_SYSTEM_LIB

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/EVT_CODE_SYSTEM_LIB.png)

## EVT_ENV_DEBUGGER

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/EVT_ENV_DEBUGGER.png)

## EVT_ENV_JAILBREAK

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/EVT_ENV_JAILBREAK.png)

Thanks to the #EVT_* cross-references, we can go statically through all the basic blocks that use these #EVT_* variables and highlight the underlying checks that could trigger the RASP callback(s). Before detailing the checks, it is worth mentioning the following points:

1. Whilst the application uses a commercial obfuscator which provides native code obfuscation in addition to RASP, the code is **lightly obfuscated** which makes static assembly code analysis doable very easily.
2. As it will be discussed in "[RASP Weaknesses][]", the application setups the **same callback** for **all** the RASP events. Thus, it eases the RASP bypass and the dynamic analysis of the application.

由于 #EVT_* 交叉引用的存在，我们可以静态地遍历使用这些 #EVT_* 变量的所有基本块，并突出显示可能触发 RASP 回调的底层检查。在详细说明这些检查之前，值得提到以下几点：

1. 尽管应用程序使用了商业混淆器，在提供 RASP 的同时还提供原生代码混淆，但代码轻度混淆使得静态汇编代码分析变得非常容易。
2. 正如“RASP 弱点”中所讨论的那样，该应用程序为所有 RASP 事件设置相同的回调。因此，它简化了 RASP 绕过和应用程序动态分析。

## Anti-Debug

The version of the obfuscator used by SingPass implements two kinds of debug check. First, it checks if the parent process id (ppid) is the same as /sbin/launchd which should be **1**.

SingPass使用的混淆器版本实现了两种调试检查。首先，它会检查父进程ID（ppid）是否与/sbin/launchd相同，该值应为1。

```c
static constexpr pid_t LAUNCHD_PID = 1;
pid_t ppid = getppid();
if (ppid != LAUNCHD_PID) {
  // Trigger EVT_ENV_DEBUGGER
}
```

> getppid is called either through a function or with a syscall.
>
> getppid 可以通过函数调用或系统调用来执行。

If it is not the case, it triggers the `EVT_ENV_DEBUGGER` event. The second check is based on sysctl which is used to access the `extern_proc.p_flag` value. If this flag contains the `P_TRACED` value, the RASP routine triggers the `EVT_ENV_DEBUGGER` event.

如果不是这种情况，则会触发 `EVT_ENV_DEBUGGER` 事件。第二个检查基于sysctl，用于访问 `extern_proc.p_flag` 值。如果此标志包含 `P_TRACED` 值，则RASP例程将触发 `EVT_ENV_DEBUGGER` 事件。

```c
int names[] = {
  CTL_KERN,
  KERN_PROC,
  KERN_PROC_PID,
  getpid(),
};
kinfo_proc info;
int sizeof_info = sizeof(kinfo_proc);
int ret = sysctl(names, 4, &info, &sizeof_info, nullptr, nullptr);
if (info.kp_proc.p_flag  & P_TRACED) {
  // Trigger EVT_ENV_DEBUGGER
}
```

In the SingPass binary, we can find an instance of these two checks in the following ranges of addresses:

在SingPass二进制文件中，我们可以在以下地址范围内找到这两个检查的实例：

```text
ppid:   0x10071F420 – 0x10071F474
sysctl: 0x100151668 – 0x100151730
```

## Jailbreak Detection

As for most of the jailbreak detections, the obfuscator tries to detect if the device is jailbroken by checking if some files exist (or not) on the device.

对于大多数越狱检测，混淆器会尝试通过检查设备上是否存在某些文件来检测设备是否已越狱。

Files or directories are checked with syscalls or a regular functions thanks to the following helpers:

使用以下辅助程序，可以使用系统调用或常规函数来检查文件或目录：

```
pathconf:    0x100008EB0 -- 0x100008F28
utimes:      0x10000D8D4 -- 0x10000D948
stat:        0x100012188 -- 0x10001221C
open:        0x10002D478 -- 0x10002D4D8
fopen:       0x1000474E4 -- 0x100047554
stat64:      0x10006AA30 -- 0x10006AAD8
getfsstat64: 0x10047E82C -- 0x10047E914
```

While in the introduction, I mentioned that a dump of the section `__data` reveals strings related to jailbreak detection, the dump does not reveal **all the strings** used by the obfuscator.

在介绍中，我提到了一个名为__data的部分转储显示与越狱检测相关的字符串，但是这个转储并没有揭示混淆器使用的所有字符串。

By looking closely at the strings encoding mechanism, it turns out that some strings are decoded just-in-time in a temporary variable. I’ll explain the strings encoding mechanism in the second part of this series of blog posts but at this point, we can uncover the strings by setting hooks on functions like fopen, utimes and dumping the `__data` section right after these calls. Then, we can iterate over the different dumps to see if new strings appear.

通过仔细观察字符串编码机制，我们发现一些字符串会即时解码到临时变量中。我将在本系列博客文章的第二部分中解释字符串编码机制，但此时我们可以通过对`fopen`、`utimes`等函数设置钩子，并在这些调用之后立即转储`__data`节来揭示这些字符串。然后，我们可以遍历不同的转储以查看是否出现新的字符串。

```text
$ python dump_analysis.py

Processing __data_0.raw
0x01010b935c h/.installed_unc0ver
0x01010b986a w/taurine/pspawn_payload.dylib

Processing __data_392.raw
0x01010b910e y__TEXT
0x01010b91b3 /System/Library/dyld/dyld_shared_cache_arm64e
0x01010b9174 /System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e
0x01010b9136 /System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64
0x01010b9126 dyld_v1  arm64e
0x01010b9116 dyld_v1   arm64

Processing __data_393.raw
0x01010afb90 /Users/xxxxxxx/Desktop/Xcode/ndi-sp-mobile-ios-swift/SingPass/[...]
0x01010b942c /var/jb
0x01010af910 https://bio-stream.singpass.gov.sg
0x01010af6a0 https://api.myinfo.gov.sg/spm/v3
0x01010b93b0 /.mount_rw
```

In the end, the approach does not enable to have all the strings decoded but it enables to have a good coverage. The list of the files used for detecting jailbreak is given the [Annexes][].

最终，这种方法不能使所有字符串都被解码，但它可以提供良好的覆盖范围。检测越狱使用的文件列表在[Annexes][]中给出。

There is also a particular check for detecting the unc0ver jailbreak which consists in trying to `unmount /.installed_unc0ver`:

还有一种特殊的检测方法可以检测unc0ver越狱，即尝试 `unmount /.installed_unc0ver`:

```c
0x100E4D814: _unmount("/.installed_unc0ver")
```

## Environment

The obfuscator also checks environment variables that trigger the `EVT_ENV_JAILBREAK` event. Some of these checks seem to be related to code lifting detection while still triggering the `EVT_ENV_JAILBREAK` event.

混淆器还会检查触发 `EVT_ENV_JAILBREAK` 事件的环境变量。其中一些检查似乎与代码提取检测有关，同时仍然触发 `EVT_ENV_JAILBREAK` 事件。

```c
if (strncmp(_dyld_get_image_name(0), "/private/var/folders", 0x14)) {
  -> Trigger EVT_ENV_JAILBREAK
}
if (strncmp(getenv("HOME"), "/Users", 6) == 0) {
  -> Trigger EVT_ENV_JAILBREAK
}
if (strncmp(getenv("HOME"), "mobile", 6) != 0) {
  -> Trigger EVT_ENV_JAILBREAK
}
char buffer[0x400];
size_t buff_size = 0x400;
_NSGetExecutablePath(buffer, &buff_size);
if (buffer.startswith("/private/var/folders")) {
  -> Trigger EVT_ENV_JAILBREAK
}
```

> **startswith()**
> 
> From a reverse engineering perspective, startswith() is actually implemented as a succession of xor that are “or-ed” to get a boolean. This might be the result of an optimization from the compiler. You can observe this pattern in the basic block located at the address: 0x100015684.
>
> 从逆向工程的角度来看，startswith()实际上是通过一系列异或操作并进行“或”运算得到布尔值。这可能是编译器优化的结果。您可以在地址为0x100015684的基本块中观察到这种模式。

## Advanced Detections

In addition to regular checks, the obfuscator performs advanced checks like verifying the current status of the SIP (System Integrity Protection), and more precisely, the KEXTS code signing status.

除了常规检查外，混淆器还执行高级检查，例如验证SIP（系统完整性保护）的当前状态，并更精确地验证KEXTS代码签名状态。

>  From my weak experience in iOS jailbreaking, I think that no Jailbreak disables the CSR_ALLOW_UNTRUSTED_KEXTS flag. Instead, I guess that it is used to detect if the application is running on an Apple M1 which allows such deactivation.
>
> 根据我在iOS越狱方面的有限经验，我认为没有任何越狱会禁用CSR_ALLOW_UNTRUSTED_KEXTS标志。相反，我猜测它是用来检测应用程序是否运行在允许这种停用的Apple M1上。

```c
csr_config_t buffer = 0;
if (__csrctl(CSR_ALLOW_UNTRUSTED_KEXTS, buffer, sizeof(csr_config_t)) {
  /*
   * SIP is disabled with CSR_ALLOW_UNTRUSTED_KEXTS
   * -> Trigger EVT_ENV_JAILBREAK
   */
}
```

> Assembly range: 0x100004640 – 0x1000046B8

The obfuscator also uses the Sandbox API to verify if some paths exist:

混淆器还使用沙箱 API 来验证某些路径是否存在：

```c
int ret = __mac_syscall("Sandbox", /* Sandbox Check */ 2,
                        getpid(), "file-test-existence", SANDBOX_FILTER_PATH,
                        "/opt/homebrew/bin/brew");
```

The paths checked through this API are OSX-related directories, so I guess it is also used to verify that the current code has not been lifted on an Apple Silicon. Here is, for instance, a list of directories checked with the Sandbox API:

通过此 API 检查的路径是与 OSX 相关的目录，因此我猜它也用于验证当前代码是否已在 Apple Silicon 上被提取。以下是使用 Sandbox API 检查的目录列表：

```text
/Applications/Xcode.app/Contents/MacOS/Xcode
/System/iOSSupport/
/opt/homebrew/bin/brew
/usr/local/bin/brew
```

> Assembly range: 0x100ED7684 (function)

In addition, it uses the Sandbox attribute file-read-metadata as an alternative to the stat() function.

此外，它使用沙盒属性文件读取元数据作为 stat() 函数的替代方案。

> Assembly range: 0x1000ECA5C – 0x1000ECE54

The application uses the sandbox API through private syscalls to determine whether some jailbreak artifacts exists. This is very smart but I guess it’s not really compliant with the Apple policy.

该应用程序通过私有系统调用使用沙盒API来确定某些越狱工具是否存在。这很聪明，但我想它并不符合苹果的政策。

## Code Symbol Table

The purpose of this check is to verify that the addresses of the resolved imports point to the right library. In other words, this check verifies that the import table is not tampered with pointers that could be used to hook imported functions.

此检查的目的是验证已解析导入项的地址是否指向正确的库。换句话说，此检查验证导入表未被篡改为指向可用于挂钩导入函数的指针。

> Initialization: part of sub_100E544E8
> 
> Assembly range: 0x100016FC4 – 0x100017024


During the RASP checks initialization (sub_100E544E8), the obfuscator **manually** resolves the imported functions. This manual resolution is performed by iterating over the symbols in the SingPass binary, checking the library that imports the symbol, accessing (in-memory) the __LINKEDIT segment of this library, parsing the exports trie, etc. This manual resolution fills a table that contains the **absolute address** of the resolved symbols.

在RASP检查初始化（sub_100E544E8）期间，混淆器手动解析导入的函数。这种手动解析是通过迭代SingPass二进制文件中的符号、检查导入该符号的库、访问（内存中）此库的__LINKEDIT段、解析导出trie等来完成的。这种手动解析填充了一个包含已解决符号绝对地址的表。

In addition, the initialization routine setups – what I called – a metadata structure that follows this layout:

此外，初始化例程设置 - 我所说的 - 遵循此布局的元数据结构：

```data
__data:000000010109F0C8 nb_symbols      DCD 0x399
__data:000000010109F0C8
__data:000000010109F0D8                 ALIGN 0x20
__data:000000010109F0E0 ; symbols_metadata_t metadata
__data:000000010109F0E0 metadata        DCQ symbols_index       ; symbols_index
__data:000000010109F0E0                 DCQ origins             ; origins
__data:000000010109F0E0                 DCQ 0                   ; resolved_la_syms
__data:000000010109F0E0                 DCQ 0                   ; resolved_got_syms
__data:000000010109F0E0                 DCQ 0                   ; macho_la_syms
__data:000000010109F0E0                 DCQ 0                   ; macho_got_syms
__data:000000010109F0E0                 DCQ 0                   ; stub_helper_start
__data:000000010109F0E0                 DCQ 0                   ; stub_helper_end
__data:000000010109F0E0                 DCQ 0                   ; field_unknown
```

`symbols_index` is a kind of translation table that converts an index known by the obfuscator into an index in the __got or the __la_symbol_ptr section. The index’s `origin` (i.e __got or __la_symbol_ptr) is determined by the origins table which contains enum-like integers:

`symbols_index` 是一种翻译表，它将混淆器已知的索引转换为 `__got` 或 `__la_symbol_ptr` 部分中的索引。索引的来源（即__got或__la_symbol_ptr）由origins表确定，该表包含类似枚举的整数：

```c
enum SYM_ORIGINS : uint8_t {
  NONE      = 0,
  LA_SYMBOL = 1,
  GOT       = 2,
};
```

The length of both tables: `symbols_index` and `origins`, is defined by the static variable `nb_symbols` which is set to `0x399`. The metadata structure is followed by two pointers: `resolved_la_syms` and `resolved_got_syms` which point to the imports address table manually filled by the obfuscator.

两个表symbols_index和origins的长度由静态变量nb_symbols定义，其值为0x399。元数据结构后面跟着两个指针：resolved_la_syms和resolved_got_syms，它们指向导入地址表，该表是混淆器手动填充的。

> There is a dedicated table for each section: __got and __la_symbol_ptr.
>
> 每个部分都有专用的表格：__got 和 __la_symbol_ptr。

Then, `macho_la_syms` points to the beginning of the __la_symbol_ptr section while `macho_got_syms` points to the __got section.

接下来，macho_la_syms指向__la_symbol_ptr部分的开头，而macho_got_syms则指向__got部分。

Finally, `stub_helper_start / stub_helper_end holds` the memory range of the __stub_helper section. I’ll describe the purpose of these values later.

最后，stub_helper_start / stub_helper_end保存了__stub_helper部分的内存范围。我稍后会描述这些值的目的。

All the values of this metadata structure are set during the initialization which takes place in the function sub_100E544E8.

此元数据结构的所有值都在函数sub_100E544E8中进行初始化设置。

In different places of the SingPass binary, the obfuscator uses this metadata information to verify the integrity of the resolved import(s). It starts by accessing the `symbols_index` and the `origins` with a fixed value:

在SingPass二进制文件的不同位置，混淆器使用此元数据信息来验证已解析导入项的完整性。它首先访问symbols_index和origins，并使用固定值：

```asm
__text:00100016FC4 LDR             W26, [X22,#0xCA8] ; X22 -> symbols_index
__text:00100016FC8 LDR             X8, [X19,#0x498]
__text:00100016FCC STP             XZR, XZR, [X19,#0x20]
__text:00100016FD0 STP             X22, X23, [X19,#0x58]
__text:00100016FD4 LDP             Q0, Q1, [X19,#0x30]
__text:00100016FD8 STUR            Q0, [X19,#0x68]
__text:00100016F54 LDR             X25, [X19,#0x488]
__text:00100016F58 LDR             X24, [X19,#0x490]
__text:00100016F5C LDRB            W21, [X23,#0x32A] ; X23 -> origins table
__text:00100016F60 ADRL            X0, check_region_cbk ; cbk
__text:00100016F68 BL              iterate_system_region
```

> Since the symbols_index table contains uint32_t values, #0xCA8 matches #0x32A (index for the origins table) when divided by sizeof(uint32_t): 0xCA8 = 0x32A * sizeof(uint32_t)
>
> 由于 `symbols_index` 表包含 uint32_t 值，因此当除以 sizeof(uint32_t) 时，#0xCA8与origins表的索引#0x32A匹配：0xCA8 = 0x32A * sizeof(uint32_t)

In other words, we have the following operations:

换句话说，我们有以下操作：

```c
const uint32_t sym_idx   = metadata.symbols_index[0x32a];
const SYM_ORIGINS origin = metadata.origins[0x32a]
```

Then, given the sym_idx value and depending on the origin of the symbol, the function accesses either the resolved __got table or the resolved __la_symbol_ptr table. This access is done with a helper function located at sub_100ED6CC0. It can be summed up with the following pseudo-code:

然后，根据sym_idx值和符号的来源，该函数访问已解析的__got表或已解析的__la_symbol_ptr表。这个访问是通过位于sub_100ED6CC0的辅助函数完成的。它可以用以下伪代码总结：

```c
uintptr_t* section_ptr       = nullptr;
uintptr_t* manually_resolved = nullptr;

if      (origin == /* 1 */ SYM_ORIGINS::LA_SYMBOL) {
  section_ptr       = metadata.macho_la_syms;
  manually_resolved = metadata.resolved_la_syms;
}
else if (origin == /* 2 */ SYM_ORIGINS::GOT) {
  section_ptr       = metadata.macho_got_syms;
  manually_resolved = metadata.resolved_got_syms;
}

```

The entries at the index sym_idx of section_ptr and manually_resolved are compared and if they don’t match, the event `#EVT_CODE_SYMBOL_TABLE` is triggered.

比较section_ptr和manually_resolved中索引sym_idx处的条目，如果它们不匹配，则触发事件#EVT_CODE_SYMBOL_TABLE。

Actually, the comparison covers different cases. First, the obfuscator handles the case where the symbol at sym_idx is not yet resolved. In that case, section_ptr[sym_idx] points to the symbols resolution stub located in the section __stub_helper. That’s why the metadata structure contains the memory range of this section:

实际上，比较涵盖了不同的情况。首先，混淆器处理符号在sym_idx处尚未解析的情况。在这种情况下，section_ptr[sym_idx]指向位于__stub_helper部分中的符号解析存根。这就是为什么元数据结构包含此部分的内存范围：

```c
const uintptr_t addr_from_section = section_ptr[sym_idx];
if (metadata.stub_helper_start <= addr && addr < metadata.stub_helper_end) {
  // Skip
}
```

In addition, if the pointers do not match, the function verifies their location using dladdr:

此外，如果指针不匹配，该函数将使用dladdr验证它们的位置：

```c
const uintptr_t addr_from_section    = section_ptr[sym_idx];
const uintptr_t addr_from_resolution = manually_resolved[sym_idx];

if (addr_from_section != addr_from_resolution) {
  Dl_info info_section;
  Dl_info info_resolution;

  dl_info(addr_from_section,    &info_section);
  dl_info(addr_from_resolution, &info_resolution);
  if (info_section.dli_fbase != info_resolution.dli_fbase) {
    // --> Trigger EVT_CODE_SYMBOL_TABLE;
  }
}
```

> Two pointers might not match if, for instance, an imported function is hooked with Frida.
>
> 如果使用Frida钩取了一个导入函数，那么两个指针可能不匹配。

In the case where the `origin[sym_idx]` is set to `SYM_ORIGINS::NONE` the function skips the check. Thus, we can simply disable this RASP check by filling the original table with 0. The number of symbols is close to the metadata structure and the address of the metadata structure is leaked by the `___atomic_load` and `___atomic_store` functions.

在 origin[sym_idx] 被设置为 SYM_ORIGINS::NONE 的情况下，该函数会跳过检查。因此，我们可以通过将原始表格填充为 0 来简单地禁用此 RASP 检查。符号数量接近元数据结构，并且元数据结构的地址由 ___atomic_load 和 ___atomic_store 函数泄漏。

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/Code_Symbol_Table.png)

## Code Tracing

The Code Tracing check aims to verify that the current is not traced. By looking at the cross-references of `#EVT_CODE_TRACING_cbk_ptr`, we can identify two kinds of verification.

代码追踪检查旨在验证当前是否被跟踪。通过查看#EVT_CODE_TRACING_cbk_ptr的交叉引用，我们可以确定两种验证方式。

### GumExecCtx

`EVT_CODE_TRACING` seems able to **detect** if the `Frida’s Stalker` is running. It’s the first time I can observe this kind of check and it’s very smart. For those who would like to follow this analysis with the raw assembly code, I will use this range of addresses from the [SingPass][] binary:

EVT_CODE_TRACING 似乎能够检测到 Frida 的 Stalker 是否正在运行。这是我第一次看到这种检查方式，非常聪明。对于那些想要使用原始汇编代码跟随此分析的人，我将使用 SingPass 二进制文件中的以下地址范围：

> 0x10019B6FC – 0x10019B82C

Here is the graph of the function that performs the Frida Stalker check:

这是执行Frida Stalker检查的函数图表：

![Code associated with Frida Stalker Detection](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/Code_associated_with_Frida_Stalker_Detection.png)

Yes, this code is able to detect the Stalker. How? Let’s start with the first basic block. `_pthread_mach_thread_np(_pthread_self())` aims at getting the thread id of the function that invokes this check.

是的，这段代码能够检测到Stalker。怎么做到的呢？让我们从第一个基本块开始说起。_pthread_mach_thread_np(_pthread_self())旨在获取调用此检查的函数的线程ID。

Then more subtly, `MRS(TPIDRRO_EL0) & #-8` is used to **manually** access the thread local storage area. On ARM64, Apple uses the least significant byte of TPIDRRO_EL0 to store the number of CPU while the MSB contains the TLS base address.

然后更微妙地，使用MRS(TPIDRRO_EL0) & #-8手动访问线程局部存储区域。在ARM64上，苹果使用TPIDRRO_EL0的最低有效字节来存储CPU数量，而MSB包含TLS基地址。

> See also: [dyld – threadLocalHelpers.s][]

Then, the second basic block – which is the loop’s entry – accesses the thread local variable with the key `tlv_idx` which ranges from 0x100 to 0x200 in the loop:

接下来，第二个基本块 - 即循环的入口 - 访问了线程局部变量，其键为tlv_idx，在循环中范围从0x100到0x200：

```c
*(tlv_table + (tlv_idx << 3))
```

The following basic block which calls `_vm_region_64(…)` is used to verify that the `tlv_addr` variable contains a valid address with a correct size (i.e. larger than 0x30). Under these conditions, it jumps into the following basic block with these strange memory accesses:

下面的基本块调用_vm_region_64(…)函数来验证tlv_addr变量是否包含一个有效地址和正确的大小（即大于0x30）。在这些条件下，它使用以下奇怪的内存访问跳转到以下基本块：

![Condition that (somehow) Triggers EVT_CODE_TRACING](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/EVT_CODE_TRACING.png)

To figure out the meaning of these memory accesses, let’s remind that this function is associated with the EVT_CODE_TRACING event. Which well-known public tool could be associated with code tracing? Without too much risk, we can assume the Frida’s Stalker.

为了弄清这些内存访问的含义，让我们想起这个函数与EVT_CODE_TRACING事件相关联。哪个众所周知的公共工具可以与代码跟踪相关联呢？不冒太大风险，我们可以假设是Frida的Stalker。

If we look at the implementation of the Stalker, we can notice this kind of initialisation (in gumstalker-arm64.c):

如果我们查看Stalker的实现，就会注意到这种初始化（在gumstalker-arm64.c中）：

```c
void gum_stalker_init (GumStalker* self) {
  [...]
  self->exec_ctx = gum_tls_key_new();
  [...]
}

void* _gum_stalker_do_follow_me(GumStalker* self, ...) {
  GumExecCtx* ctx = gum_stalker_create_exec_ctx(...);
  gum_tls_key_set_value (self->exec_ctx, ctx);
}
```

So the Stalker creates a thread local variable that is used to store a pointer to the **GumExecCtx** structure which has the following layout:

因此，Stalker创建了一个线程本地变量，用于存储指向GumExecCtx结构的指针，该结构具有以下布局：

```c
struct _GumExecCtx {
  volatile gint state;
  gint64 destroy_pending_since;

  GumStalker * stalker;
  GumThreadId thread_id;

  GumArm64Writer code_writer;
  GumArm64Relocator relocator;
  [...]
}
```

If we add the offsets of this layout and if we virtually inline the GumArm64Writer structure, we can get this representation:

如果我们添加此布局的偏移量，并且在虚拟上内联GumArm64Writer结构，我们可以得到以下表示：

```c
struct _GumExecCtx {
  /* 0x00 */ volatile gint state;
  /* 0x08 */ gint64 destroy_pending_since;

  /* 0x10 */ GumStalker * stalker;
  /* 0x18 */ GumThreadId thread_id;

  GumArm64Writer code_writer {
  /* 0x20 */ volatile gint ref_count;
  /* 0x24 */ GumOS target_os;
  /* 0x28 */ GumPtrauthSupport ptrauth_support;
  ...
  };
}
```

> destroy_pending_since is located at the offset 0x08 and not 0x04 because of the alignment enforced by the compiler.
>
> destroy_pending_since位于偏移量0x08处，而不是0x04处，这是由编译器强制执行的对齐导致的。

With this representation, we can observe that:

* `*(tlv_table + 0x18)` effectively matches the **GumThreadId** thread_id attribute.

* `*(tlv_table + 0x24)` matches **GumOS target_os**

* `*(tlv_table + 0x28)` matches **GumPtrauthSupport ptrauth_support**

通过这种表示，我们可以观察到：

* `(tlv_table + 0x18)` 实际上匹配了 GumThreadId thread_id 属性。

* `(tlv_table + 0x24)` 匹配了 GumOS target_os

* `(tlv_table + 0x28)` 匹配了 GumPtrauthSupport ptrauth_support


GumOS and GumPtrauthSupport are enums defined in `gumdefs.h` and `gummemory.h` with these values:

GumOS和GumPtrauthSupport是在gumdefs.h和gummemory.h中定义的枚举，其值如下：

```c
enum _GumOS {
  GUM_OS_WINDOWS,
  GUM_OS_MACOS,
  GUM_OS_LINUX,
  GUM_OS_IOS,
  GUM_OS_ANDROID,
  GUM_OS_QNX
};


enum _GumPtrauthSupport {
  GUM_PTRAUTH_INVALID,
  GUM_PTRAUTH_UNSUPPORTED,
  GUM_PTRAUTH_SUPPORTED
};
```

GumOS contains 6 entries starting from `GUM_OS_WINDOWS = 0` up to `GUM_OS_QNX = 5` and similarly, `GUM_PTRAUTH_INVALID = 0` while the last entry is associated with `GUM_PTRAUTH_SUPPORTED = 2`

GumOS 包含 6 个条目，从 GUM_OS_WINDOWS = 0 到 GUM_OS_QNX = 5。类似地，GUM_PTRAUTH_INVALID = 0 而最后一个条目与 GUM_PTRAUTH_SUPPORTED = 2 相关联。

Therefore, the previous strange conditions are used to fingerprint the GumExecCtx structure:

因此，前面的奇怪条件用于指纹识别 GumExecCtx 结构：

```c
bool in_range = address <= tlv_addr && tlv_addr < address + size;
bool cond     = _GumExecCtx->thread_id                   == tid &&
                _GumExecCtx->code_writer.target_os       <= 5   &&
                _GumExecCtx->code_writer.ptrauth_support <  3;
if (in_range && cond) {
  -> Trigger EVT_CODE_TRACING
}
```

One way to prevent this Stalker detection would be to recompile Frida with swapped fields in the _GumExecCtx structure.

防止Stalker检测的一种方法是重新编译Frida，交换_GumExecCtx结构中的字段。

### Thread Check

An alternative to the previous Frida stalker check consists in accessing the current thread status through the following call:

除了之前的Frida stalker检查方法外，还可以通过以下调用访问当前线程状态：

```c
thread_read_t target = pthread_mach_thread_np(pthread_self());
uint32_t count = ARM_UNIFIED_THREAD_STATE_COUNT;
arm_unified_thread_state state;
thread_get_state(target, ARM_UNIFIED_THREAD_STATE, &state, &count);
```

Then, it checks if `state->ts_64.__pc` is within the `libsystem_kernel.dylib` thanks to the following comparison:

然后，它通过以下比较检查state->ts_64.__pc是否在libsystem_kernel.dylib中：

```c
const auto mach_msg_addr = reinterpret_cast<uintptr_t>(&mach_msg);
const uintptr_t delta = abs(state->ts_64.__pc - mach_msg_addr)
if (delta > 0x4000) {
  rasp_event_info info;
  info.event = 0x2000; // EVT_CODE_TRACING;
  info.ptr = (uintptr_t*)0x13b71a24724edfe;
  EVT_CODE_TRACING_cbk_ptr(info);
}
```

In other words, `state->ts_64.__pc` is considered to be in `libsystem_kernel.dylib`, if its distance from &mach_msg is smaller than 0x4000.

换句话说，如果state->ts_64.__pc与&mach_msg之间的距离小于0x4000，则认为它在libsystem_kernel.dylib中。

At first sight, I was a bit confused by this RASP check but since the previous checks, associated with `EVT_CODE_TRACING`, aims at detecting the Frida Stalker, this check is also likely designed to detect the Frida Stalker.

一开始我对这个RASP检查有点困惑，但由于先前的检查旨在检测Frida Stalker，因此这个检查也很可能是设计用来检测Frida Stalker的。

To confirm this hypothesis, I developed a small test case that reproduces this check, in a standalone binary and we can observe a difference depending on whether it runs through the Frida stalker or not:

为了确认这个假设，我开发了一个小测试案例，在独立二进制文件中重现了这个检查，并且我们可以观察到是否通过Frida stalker运行会有所不同。

![Output of the Test Case with the Stalker](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/Output_of_the_Test_Case_with_the_Stalker.png)


![Output of the Test Case without the Stalker](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/Output_of_the_Test_Case_without_the_Stalker.png)

This check can be bypassed without too much difficulty by using the function [gum_stalker_exclude][] to exclude the library libsystem_kernel.dylib from the stalker:

可以使用函数gum_stalker_exclude将库libsystem_kernel.dylib从stalker中排除，从而很容易地绕过此检查：

```c
GumStalker* stalker = gum_stalker_new();
exclude(stalker, "libsystem_kernel.dylib");
{
  // Stalker Check
}
```

As a result of this exclusion, `state->ts_64.__pc` is located in libsystem_kernel.dylib:

由于这种排除，state->ts_64.__pc 位于 libsystem_kernel.dylib 中：

![Output of the Test Case with Excluded Memory Ranges](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/Output_of_the_Test_Case_with_Excluded_Memory_Ranges.png)

## App Loaded Libraries

The RASP event `EVT_APP_LOADED_LIBRARIES` aims at checking the integrity of the Mach-O’s dependencies. In other words, it checks that the Mach-O imported libraries have not been altered.

RASP 事件 EVT_APP_LOADED_LIBRARIES 的目的在于检查 Mach-O 的依赖项完整性。换句话说，它会检查 Mach-O 导入的库是否被篡改。

>  Assembly ranges: 0x100E4CDF8 – 0x100e4d39c

The code associated with this check starts by accessing the Mach-O header thanks to the dladdr function:

与此检查相关的代码首先通过dladdr函数访问Mach-O头：

```c
Dl_info dl_info;
dladdr(&static_var, &dl_info);
```

`Dl_info` contains the base address of the library which encompasses the address provided in the first parameter and since, a Mach-O binary is loaded with its header, `dl_info.dli_fbase` actually points to a `mach_header_64`.

`Dl_info` 包含了覆盖第一个参数提供的地址的库的基地址，因此，当 Mach-O 二进制文件被加载时，`dl_info.dli_fbase` 实际上指向 `mach_header_64`。

Then the function iterates over the LC_ID_DYLIB-like commands to access dependency’s name:

然后该函数迭代LC_ID_DYLIB类似的命令以访问依赖项的名称：

![](https://raw.githubusercontent.com/jiaxw32/iNote/master/images/blog/SingPass-RASP/App_Loaded_Libraries.png)

This name contains the path to the dependency. For instance, we can access this list as follows:

这个名称包含了依赖项的路径。例如，我们可以按照以下方式访问此列表：

```python
import lief

singpass = lief.parse("./SingPass")

for lib in singpass.libraries:
  print(lib.name)

# Output:
/System/Library/Frameworks/AVFoundation.framework/AVFoundation
/System/Library/Frameworks/AVKit.framework/AVKit
...
@rpath/leveldb.framework/leveldb
@rpath/nanopb.framework/nanopb
```

The dependency’s names are used to fill a hash table in which a hash value in encoded on 32 bits:

依赖项的名称用于填充哈希表，其中哈希值编码为32位：

```c
// Pseudo code
uint32_t TABLE[0x6d]
for (size_t i = 0; i < 0x6d; ++i) {
  TABLE[i] = hash(lib_names[i]);
}
```

Later in the the code, this computed table is compared with another hash table – **hard-coded in the code** – which looks like this:

后来在代码中，这个计算出的表格会与另一个硬编码在代码中的哈希表进行比较，它看起来像这样：

```asm
__text:0000000100E4CF38 loc_100E4CF38                   ; CODE XREF: sub_100E4CC54+230↑j
__text:0000000100E4CF38                 MOV             X10, SP
__text:0000000100E4CF3C                 SUB             X8, X10, #0x1C0
__text:0000000100E4CF40                 MOV             SP, X8
__text:0000000100E4CF44                 MOV             X9, #0
__text:0000000100E4CF48                 MOV             X11, #0x1D2A29E0195DDC1
__text:0000000100E4CF58                 MOV             X12, #0x4AA0A7902C19769
__text:0000000100E4CF68                 STP             X11, X12, [X8]
__text:0000000100E4CF6C                 MOV             X11, #0x64CAED105C09EBA
__text:0000000100E4CF7C                 MOV             X12, #0xEDC68A50A44D7D1
__text:0000000100E4CF8C                 STP             X11, X12, [X8,#0x10]
__text:0000000100E4CF90                 MOV             X11, #0x128801E010DCF774
__text:0000000100E4CFA0                 MOV             X12, #0x14EDACA112DF984A
__text:0000000100E4CFB0                 STP             X11, X12, [X8,#0x20]
__text:0000000100E4CFB4                 MOV             X11, #0x166DA22D164DF42A
__text:0000000100E4CFC4                 MOV             X12, #0x1B2CAF8A1ACDDCCF
__text:0000000100E4CFD4                 STP             X11, X12, [X8,#0x30]
__text:0000000100E4CFD8                 MOV             X11, #0x1CF2CE101BB56374
__text:0000000100E4CFE8                 MOV             X12, #0x235D2E461E37FF16
__text:0000000100E4CFF8                 STP             X11, X12, [X8,#0x40]
__text:0000000100E4CFFC                 MOV             X11, #0x28F80E87260C94F3
__text:0000000100E4D00C                 MOV             X12, #0x2CBB87222BFB0F4D
__text:0000000100E4D01C                 STP             X11, X12, [X8,#0x50]
```

[Fig 4. Examples of Hashes]()

If some libraries have been modified to inject, for instance, `FridaGadget.dylib` then the hash dynamically computed will not match the hash hard-coded in the code.

如果某些库已被修改以注入FridaGadget.dylib等内容，则动态计算的哈希值将与代码中硬编码的哈希值不匹配。

Whilst the implementation of this check is pretty “standard”, there are a few points worth mentioning:

* Firstly, the hash function seems be a derivation of the `MurmurHash`.

* Secondly, the hash is encoded on **32 bits** but the code in the **Figure 4** references the X11/X12 registers which are 64 bits. This is actually a compiler optimization to limit the number of memory accesses.

* Thirdly, the hard coded hash values are duplicated in the binary for each instance of the check. In SingPass, this RASP check is present twice thus, we find these values at the following locations: `0x100E4CF38, 0x100E55678`. This duplication is likely used to prevent a single spot location that would be easy to patch.

虽然这个检查的实现相当“标准”，但有一些值得注意的地方：

* 首先，哈希函数似乎是 MurmurHash 的一个派生版本。

* 其次，哈希值编码为 32 位，但图4中的代码引用了 X11/X12 寄存器，这实际上是一种编译器优化来限制内存访问次数。

* 第三，在二进制文件中硬编码的哈希值在每个检查实例中都会重复出现。在 SingPass 中，此 RASP 检查出现两次，因此我们可以在以下位置找到这些值：0x100E4CF38、0x100E55678。这种重复很可能是为了防止单个易于修补的位置。

## Code System Lib

This check is associated with the event `EVT_CODE_SYSTEM_LIB` which consists in verifying the integrity of the **in-memory** system libraries with their content in the dyld shared cache (**on-disk**).

此检查与事件EVT_CODE_SYSTEM_LIB相关联，其目的在于验证内存中系统库与dyld共享缓存（磁盘上）中内容的完整性。

> Assembly ranges: 0x100ED5BF8 – 0x100ED5D6C and 0x100ED5E0C – 0x100ED62D4

This check usually starts with the following pattern:

这个检查通常以以下模式开始：

```asm
__text:00100E80AF0     ADR         X0, check_region_cbk ; cbk
__text:00100E80AF4     NOP
__text:00100E80AF8     BL          iterate_system_region
__text:00100E80AFC     ORR         W8, W0, W21
__text:00100E80B00     CBZ         W8, loc_100E80B50
__text:00100E80B04     MOV         X21, SP
__text:00100E80B08     ADRP        X8, #EVT_CODE_SYSTEM_LIB_cbk_ptr@PAGE
__text:00100E80B0C     LDR         X8, [X8,#EVT_CODE_SYSTEM_LIB_cbk_ptr@PAGEOFF]
__text:00100E80B10     MOV         X9, SP
__text:00100E80B14     SUB         X10, X9, #0x10
__text:00100E80B18     MOV         SP, X10
__text:00100E80B1C     MOV         X11, #0x13B851C07E9DBCD
__text:00100E80B2C     STUR        X11, [X9,#-0x10]
__text:00100E80B30     MOV         X9, SP
__text:00100E80B34     SUB         X0, X9, #0x10
__text:00100E80B38     MOV         SP, X0
__text:00100E80B3C     MOV         W11, #0x1000
__text:00100E80B40     STUR        W11, [X9,#-0x10]
__text:00100E80B44     STUR        X10, [X9,#-8]
__text:00100E80B48     BLR         X8
__text:00100E80B4C     MOV         SP, X21
```

If the result of `iterate_system_region` with the given `check_region_cbk` callback is not 0, it triggers the `EVT_CODE_SYSTEM_LIB` event:

如果使用给定的check_region_cbk回调函数进行iterate_system_region操作的结果不为0，则会触发EVT_CODE_SYSTEM_LIB事件：

```c
if (iterate_system_region(check_region_cbk) != 0) {
// Trigger `EVT_CODE_SYSTEM_LIB`
}
```

To understand the logic behind this check, we need to understand the purpose of the `iterate_system_region` function and its relationship with the callback `check_region_cbk`.

为了理解这个检查背后的逻辑，我们需要了解iterate_system_region函数的目的以及它与回调函数check_region_cbk之间的关系。

### iterate_system_region

> As for all the functions referenced in the blog post, their names come from my own analysis and might be inaccurate. Most of the functions related to the RASP checks were obviously stripped. In this case, iterate_system_region matches the original sub_100ED5BF8
>
> 至于博客文章中提到的所有函数，它们的名称来自我的分析，可能不准确。大多数与RASP检查相关的功能显然已被剥离。在这种情况下，iterate_system_region匹配原始sub_100ED5BF8。

This function aims to call the system function `vm_region_recurse_64` and then, filter its output on conditions that could trigger the callback given in the first parameter: `check_region_cbk`.

该函数旨在调用系统函数 `vm_region_recurse_64`，然后根据可能触发第一个参数中给定的回调函数 `check_region_cbk` 的条件对其输出进行过滤。

`iterate_system_region` starts by accessing the base address of the dyld shared cache thanks to the `SYS_shared_region_check_np` syscall. This address is used to read and **memoize** a few attributes from the `dyld_cache_header` structure:

1. The shared cache header
2. The shared cache end address
3. Other limits related to the shared cache

`iterate_system_region` 函数通过访问 `SYS_shared_region_check_np` 系统调用获取dyld共享缓存的基地址。使用该地址从`dyld_cache_header` 结构中读取并记录一些属性：

1. 共享缓存头部
2. 共享缓存结束地址
3. 与共享缓存相关的其他限制

The following snippet gives an overview of these computations:

以下代码片段概述了这些计算：

```c
static dyld_shared_cache* header = nullptr; /* At: 0x1010DE940 */
static uintptr_t g_shared_cache_end;        /* At: 0x1010DE948 */
static uintptr_t g_overflow_address;        /* At: 0x1010DE950 */
static uintptr_t g_module_last_addr;        /* At: 0x1010DE958 */

if (header == nullptr) {
// return;
}

uintptr_t shared_cache_base;
syscall(SYS_shared_region_check_np, &shared_cache_base);
header = shared_cache_base;

g_shared_cache_end = shared_cache_addr + header->mappings[0].size;
g_overflow_address = -1;
g_module_last_addr = g_shared_cache_end;
if (header->imagesTextCount > 0) {
  uintptr_t slide = shared_cache_addr - header->mappings[0].address;
  uintptr_t tmp_overflow_address = -1;
  uintptr_t shared_cache_end_tmp = shared_cache_end;

  for (size_t i = 0; i < header->imagesTextCount; ++i) {
    const uintptr_t txt_start_addr = slide      + header->imagesText[i].loadAddress;
    const uintptr_t txt_end_addr   = start_addr + header->imagesText[i].textSegmentSize;

    if (txt_start_addr >= shared_cache_end_tmp && txt_start_addr < tmp_overflow_address) {
      g_overflow_address   = start_addr;
      tmp_overflow_address = start_addr;
    }

    if (txt_end_addr >= shared_cache_end_tmp) {
      g_module_last_addr   = txt_end_addr;
      shared_cache_end_tmp = txt_end_addr;
    }
  }
}
```

> From a reverse engineering point of view, the stack variable used to memoize these information is aliased with the parameter info of vm_region_recurse_64 that is called later. I don’t know if this aliasing is on purpose, but it makes the reverse engineering of the structures a bit more complicated.
>
> 从逆向工程的角度来看，用于备忘这些信息的堆栈变量与稍后调用的vm_region_recurse_64函数的参数info存在别名。我不知道这种别名是否是有意为之，但它使得结构体的逆向工程变得更加复杂。

Following this memoization, there is a loop on `vm_region_recurse_64` which queries the `vm_region_submap_info_64` information for these addresses in the range of the dyld shared cache. We can identify the type of the query (`vm_region_submap_info_64`) thanks to the `mach_msg_type_number_t *infoCnt` argument which is set to **19**:

在这个记忆化之后，有一个循环遍历 `vm_region_recurse_64`，在范围为dyld共享缓存的地址中查询 `vm_region_submap_info_64` 信息。我们可以通过 `mach_msg_type_number_t *infoCnt` 参数来确定查询类型（`vm_region_submap_info_64`），该参数设置为 19：

```asm
; In this basic block, the stack variable `#0xB0+info` is aliased with
; the variable used for, saving (temporarily) the shared cache information
; c.f. loc_100ED5C68
__text:0000000100ED5D24 loc_100ED5D24
__text:0000000100ED5D24                 X9 <- shared cache base address
__text:0000000100ED5D24 STR             X9, [SP,#0xB0+pAddr]
__text:0000000100ED5D28 MOV             W8, #0x13 ; -> 19 <=> vm_region_submap_info_64
__text:0000000100ED5D2C STR             W8, [SP,#0xB0+infoCnt]
__text:0000000100ED5D30 ADD             X1, SP, #0xB0+pAddr      ; address
__text:0000000100ED5D34 SUB             X2, X29, #-size          ; size
__text:0000000100ED5D38 SUB             X3, X29, #-nesting_depth ; nesting_depth
__text:0000000100ED5D3C ADD             X4, SP, #0xB0+info       ; info
__text:0000000100ED5D40 ADD             X5, SP, #0xB0+infoCnt    ; infoCnt
__text:0000000100ED5D44 MOV             X0, X20                  ; target_task
__text:0000000100ED5D48 BL              _vm_region_recurse_64
__text:0000000100ED5D4C CBZ             W0, loc_100ED5D70
```

This loop breaks under certain conditions and the callback is triggered with other conditions. As it is explained a bit later, the callback verifies the in-memory integrity of the library present in the dyld shared cache.

这个循环在特定条件下会中断，并且回调函数会在其他条件下被触发。正如稍后所解释的那样，回调函数验证了dyld共享缓存中库的内存完整性。

The verification and the logic behind this check is prone to take time, that’s why the authors of the check took care of filtering the addresses to check to avoid useless (heavy) computations.

由于验证和检查逻辑需要时间，因此检查程序的作者们注意到要过滤掉不必要（繁重）的计算以避免浪费时间。

Basically, the callback that performs the in-depth inspection of the shared cache is triggered if:

基本上，如果以下情况之一成立，则会触发执行共享缓存深度检查的回调函数：

```c
if (info.pages_swapped_out != 0 ||
    info.pages_swapped_out == 0 && info.protection & VM_PROT_EXECUTE)
{
  bool integrity_failed = check_region_cbk(address);
}
```

#### check_region_cbk

When the conditions are met, `iterate_system_region` calls the `check_region_cbk` with the suspicious address in the first parameter:

当条件满足时，`iterate_system_region` 将使用第一个参数中的可疑地址调用check_region_cbk函数：

```c
int iterate_system_region(callback_t cbk) {
  int ret = 0;
  if (cond(address)) {
    ret = cbk(address) {
      // Checks on the dyld_shared_cache
    }
  }
  return ret;
}
```

During the analysis of SingPass, only **one** callback is used in pair with `iterate_system_region`, and its code is not **especially obfuscated** (except the strings). Once we know that the checks are related to the dyld shared cache, we can quite easily figure out the structures involved in this function. This callback is located at the address 0x100ed5e0c and renamed `check_region_cbk`.

在对 SingPass 进行分析时，只使用了一个回调函数与 `iterate_system_region` 配对，并且它的代码并不特别混淆（除了字符串）。一旦我们知道这些检查与dyld共享缓存有关，就可以很容易地找出此函数中涉及的结构。该回调位于地址0x100ed5e0c处，并重命名为`check_region_cbk`。

Firstly, it starts by accessing the information about the address:

首先，它开始访问有关地址的信息：

```c
int check_region_cbk(uintptr_t address) {
  Dl_info info;
  dladdr(address, info);
  // ...
}
```

This information is used to read the content of the `__TEXT segment` associated with the **address** parameter:

这些信息用于读取与地址参数相关联的 `__TEXT` 段的内容：

```c++
auto* header = reinterpret_cast<mach_header_64*>(info.dli_fbase);

segment_command_64 __TEXT = get_text_segment(header);

vm_offset_t data = 0;
mach_msg_type_number_t* dataCnt = 0;

vm_read(task_self_trap(), info.dli_fbase, __TEXT.vmsize, &data, &dataCnt);
```

> The __TEXT strings is encoded as well as the different paths of the shared cache like /System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e and the header’s magic values: 0x01010b9126: dyld_v1 arm64e or 0x01010b9116: dyld_v1 arm64
>
> __TEXT字符串以及共享缓存的不同路径（例如/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e）都是经过编码的，还有头部魔数值：0x01010b9126表示dyld_v1 arm64e，0x01010b9116表示dyld_v1 arm64。

On the other hand, the function opens the `dyld_shared_cache` and looks for the section of the shared cache that contains the library associated with the address parameter:

另一方面，该函数打开dyld_shared_cache并查找包含与地址参数相关联的库的共享缓存部分：

```c
int fd = open('/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64');
(1) mmap(nullptr, 0x100000, VM_PROT_READ, MAP_NOCACHE | MAP_PRIVATE, fd, 0x0): 0x109680000

// Look for the shared cache entry associated with the provided address
(2) mmap(nullptr, 0xad000, VM_PROT_READ, MAP_NOCACHE | MAP_PRIVATE, fd, 0x150a9000): 0x109681000
```

The purpose of the second call to **mmap()** is to load the slice of the shared cache that contains the code of the library. Then, the function checks **byte per byte** that the __TEXT segment’s content matches the in-memory content. The loop which performs this comparison is located between these addresses: 0x100ED6C58 - 0x100ED6C70.

第二次调用 **mmap()** 的目的是加载包含库代码的共享缓存片段。然后，该函数逐字节检查 `__TEXT` 段内容是否与内存中的内容匹配。执行此比较的循环位于这些地址之间：0x100ED6C58 - 0x100ED6C70。

***

As we can observe from the description of this RASP check, the authors paid a lot of attention to avoid performance issues and memory overhead. On the other hand, the callback `check_region_cbk` was never called during my experimentations (even when I hooked system function). I don’t know if it’s because I misunderstood the conditions but in the end, I had to manually force the conditions (by forcing the **pages_swapped_out** to 1).

从这个RASP检查的描述中，我们可以看出作者们非常注重避免性能问题和内存开销。另一方面，在我的实验中从未调用回调函数 `check_region_cbk`（即使我钩取了系统函数）。我不知道是否是因为我误解了条件，但最终，我不得不手动强制条件（通过将 **pages_swapped_out** 强制设置为1）。

> **vm_region_recurse_64** seems also always paired with an anti-hooking verification that is slightly different from the check described at the beginning of this blog post. Its analysis is quite easy and can be a good exercise.
>
> vm_region_recurse_64 似乎总是与一种反钩子验证配对，该验证与本博客文章开头描述的检查略有不同。它的分析非常简单，可以作为一个很好的练习。

## RASP Design Weaknesses

Thanks to the different `#EVT_*` static variables that hold function pointers, the obfuscator enables to have dedicated callbacks for the supported RASP events. Nevertheless, the function `init_and_check_rasp` defined by the application’s developers setup **all** these pointers **to the same** callback: `hook_detect_cbk_user_def`. In such a design, all the RASP events end up in a single function which weakens the strength of the different RASP checks.

由于不同的 `#EVT_*` 静态变量保存了函数指针，混淆器可以为支持的 `RASP` 事件设置专用回调。然而，应用程序开发人员定义的 `init_and_check_rasp` 函数将所有这些指针都设置为相同的回调：`hook_detect_cbk_user_def`。在这样的设计中，所有RASP事件最终都会进入一个单一函数中，从而削弱了不同 RASP检查的强度。

It means that we only have to target this function to disable or bypass the RASP checks.

这意味着我们只需要针对此功能进行定位以禁用或绕过RASP检查。

Using Frida Gum, the bypass is as simple as using gum_interceptor_replace with an empty function:

使用Frida Gum，绕过非常简单，只需使用gum_interceptor_replace和空函数：

```c
enum class RASP_EVENTS : uint32_t {
  EVT_ENV_JAILBREAK        = 0x1,
  EVT_ENV_DEBUGGER         = 0x2,
  EVT_APP_SIGNATURE        = 0x20,
  EVT_APP_LOADED_LIBRARIES = 0x40,
  EVT_CODE_PROLOGUE        = 0x400,
  EVT_CODE_SYMBOL_TABLE    = 0x800,
  EVT_CODE_SYSTEM_LIB      = 0x1000,
  EVT_CODE_TRACING         = 0x2000,
};

struct event_info_t {
  RASP_EVENTS event;
  uintptr_t** ptr_to_corrupt;
};

void do_nothing(event_info_t info) {
  RASP_EVENTS evt = info.event;
  // ...
  return;
}

// This is **pseudo code**
gum_interceptor_replace(
  listener->interceptor,
  reinterpret_cast<void*>(&hook_detect_cbk_user_def)
  do_nothing,
  reinterpret_cast<void*>(&hook_detect_cbk_user_def)
);
```

Thanks to this weakness, I could prevent the error message from being displayed as soon as the application starts.

由于这个漏洞，我可以防止应用程序启动时立即显示错误消息。

<video src="https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/poc.webm" controls="controls" type="video/webm" width="500" height="300"></video>

[SingPass Jailbreak & RASP Bypass][]

> It exists two other RASP checks: EVT_APP_MACHO and EVT_APP_SIGNATURE which were not enabled by the developers and thus, are not present in SingPass.
>
> 还存在另外两个RASP检查：EVT_APP_MACHO和EVT_APP_SIGNATURE，这些检查未被开发人员启用，因此在SingPass中不存在。

## Conclusion

This first part is a good example of the challenges when using or designing an obfuscator with RASP features. On one hand, the commercial solution implements strong and advanced RASP functionalities with, for instance, inlined syscalls spread in different places of the application. On the other hand, the app’s developers weakened the RASP functionalities by setting the **same callback** for all the events. In addition, it seems that the application **does not use the native code obfuscation** provided by the commercial solution which makes the RASP checks un-protected against static code analysis. It could be worth to enforce code obfuscation on these checks regardless the configuration provided by the user.

这是使用或设计具有RASP功能的混淆器时面临的挑战的一个很好的例子。商业解决方案实现了强大和先进的RASP功能，例如在应用程序不同位置分散内联系统调用。但另一方面，应用程序开发人员通过为所有事件设置相同回调来削弱了RASP功能。此外，似乎该应用程序未使用商业解决方案提供的本地代码混淆，这使得RASP检查无法抵御静态代码分析攻击。因此，在用户提供配置之前对这些检查进行代码混淆可能值得考虑。

From a developer point of view, it can be very difficult to understand the impact in term of reverse-engineering when choosing to setup the same callback while it can be a good design decision from an architecture perspective.

从开发者角度来看，在架构层面上选择设置相同回调可能是一个良好的设计决策，但难以理解其反向工程影响。

In the second part of this series about iOS code obfuscation, we will dig a bit more in native code obfuscation through another application, where the application reacts differently to the RASP events and where the code is obfuscated with MBA, Control-Flow Flattening, etc.

在关于iOS代码混淆系列文章中第二部分中，我们将通过另一个应用程序更加详细地探讨本地代码混淆，并介绍MBA、控制流平坦化等技术。

If you have questions feel free to ping me 📫.

如果您有任何问题，请随时联系我📫。


## Annexes | 附录

| JB Detection Files | Listed in PokemonGO |
| :--- | :--- |
/.bootstrapped | NO
/.installed_taurine | NO
/.mount_rw | NO
/Library/dpkg/lock | NO
/binpack | YES
/odyssey/cstmp | NO
/odyssey/jailbreakd | NO
/payload	| No
/payload.dylib	| No
/private/var/mobile/Library/Caches/kjc.loader	| No
/private/var/mobile/Library/Sileo	| No
/taurine	| No
/taurine/amfidebilitate	| No
/taurine/cstmp	| No
/taurine/jailbreakd	| No
/taurine/jbexec	| No
/taurine/launchjailbreak	| No
/taurine/pspawn_payload.dylib	| No
/var/dropbear	| No
/var/jb	| No
/var/lib/undecimus/apt	| No
/var/motd	| No
/var/tmp/cydia.log	| No

***

| Flagged Packages |
| :--- |
/Applications/AutoTouch.app/AutoTouch |
/Applications/iGameGod.app/iGameGod |
/Applications/zxtouch.app/zxtouch |
/Library/Activator/Listeners/me.autotouch.AutoTouch.ios8 |
/Library/LaunchDaemons/com.rpetrich.rocketbootstrapd.plist |
/Library/LaunchDaemons/com.tigisoftware.filza.helper.plist |
/Library/MobileSubstrate/DynamicLibraries/ATTweak.dylib |
/Library/MobileSubstrate/DynamicLibraries/GameGod.dylib |
/Library/MobileSubstrate/DynamicLibraries/LocalIAPStore. dylib |
/Library/MobileSubstrate/DynamicLibraries/Satella.dylib |
/Library/MobileSubstrate/DynamicLibraries/iOSGodsiAPCracker.dylib |
/Library/MobileSubstrate/DynamicLibraries/pccontrol.dylib |
/Library/PreferenceBundles/SatellaPrefs.bundle/SatellaPrefs |
/Library/PreferenceBundles/iOSGodsiAPCracker.bundle/iOSGodsiAPCracker |


[SingPass]: https://apps.apple.com/sg/app/singpass/id1340660807
[1]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/bin/SingPass
[What About LIEF]: https://www.romainthomas.fr/post/21-07-pokemongo-anti-frida-jailbreak-bypass//#what-about-lief
[RASP Weaknesses]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/#rasp-design-weaknesses
[Annexes]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/#annexes
[SingPass Jailbreak & RASP Bypass]: https://www.romainthomas.fr/post/22-08-singpass-rasp-analysis/poc.webm
[dyld – threadLocalHelpers.s]: https://github.com/apple-oss-distributions/dyld/blob/5c9192436bb195e7a8fe61f22a229ee3d30d8222/libdyld/threadLocalHelpers.s#L237-L238
[gum_stalker_exclude]: https://github.com/oleavr/frida-gum/blob/b679d454b1f323fa9c181f324ec17d515a7c2f81/gum/gumstalker.h#L62-L63
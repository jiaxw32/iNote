## 0x01 Intro to Reversing iOS Swift Apps with radare2

> 原文链接：https://grepharder.github.io/blog/0x01_intro_to_reversing_ios_swift_apps_with_radare2.html

For this little intro to Swift reversing with r2 we will use the iGoat app. Get it from [here](https://github.com/OWASP/iGoat-Swift/). Our goal is to get a feeling of how does a disassembled iOS Swift app look like.

对于这个使用r2进行Swift反向的简短介绍，我们将使用iGoat应用程序。从[这里](https://github.com/OWASP/iGoat-Swift/)获取它。我们的目标是了解一个反汇编的iOS Swift应用程序看起来像什么。

> This is a Swift version of original iGoat Objective C project. Using OWASP iGoat, you can learn exploiting and defending vulnerabilities in iOS Swift applications.
> 
> 这是原始iGoat Objective C项目的Swift版本。使用OWASP iGoat，您可以学习在iOS Swift应用程序中利用和防御漏洞。

![](https://raw.githubusercontent.com/swaroopsy/test/master/h1.gif)

Let’s play with the Keychain Exercise: [KeychainExerciseVC.swift](https://github.com/OWASP/iGoat-Swift/blob/master/iGoat-Swift/iGoat-Swift/Source/Exercises/InsecureLocalDataStorage/KeychainAnalyze/KeychainExerciseVC.swift).

让我们来玩一下钥匙串练习：[KeychainExerciseVC.swift](https://github.com/OWASP/iGoat-Swift/blob/master/iGoat-Swift/iGoat-Swift/Source/Exercises/InsecureLocalDataStorage/KeychainAnalyze/KeychainExerciseVC.swift)。

```swift
class KeychainExerciseVC: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        secureStore(userName: "iGoat", password: "taoGi")
    }


    func secureStore(userName: String, password: String) {
        do {
            // This is a new account, create a new keychain item with the account name.
            let passwordItem = KeychainPasswordItem(service: "SaveUser",
                                                    account: userName,
                                                    accessGroup: nil)

            // Save the password for the new item.
            try passwordItem.savePassword(password)
        } catch {
            fatalError("Error updating keychain - \(error)")
        }
    }
```


As soon as `viewDidLoad()` gets called it will call `secureStore` with `userName: "iGoat"` and `password: "taoGi"`. This is what we will investigate here: **how does these methods look like in the disassembly**.

一旦调用`viewDidLoad()`，它将使用用户名“iGoat”和密码“taoGi”调用`secureStore`。我们在这里要研究的是：这些方法在反汇编中看起来如何。

## Preparation

Before we start we have to thin the binary. This can be done of course using radare2’s `rabin2`:

在我们开始之前，我们必须对二进制文件进行精简。当然，可以使用radare2的`rabin2`来完成这个任务：

```bash
$ cd Payload/iGoat-Swift.app
$ rabin2 -x iGoat-Swift
```

This creates a folder `iGoat-Swift.fat/` including the two binaries (32/64 bit).

这将创建一个名为`iGoat-Swift.fat/`的文件夹，其中包括两个二进制文件（32位/64位）。

Open the 32 bit binary, do the analysis and enable the **string emulation**:

打开32位二进制文件，进行分析并启用字符串仿真：

> Be careful when using **aaaa**, it can take very long for other apps, I knew it was safe so that’s why I use it here)
> 
> 使用 **aaaa** 时要小心，它可能会使其他应用程序运行缓慢。我知道它是安全的，所以才在这里使用。

```bash
$ r2 -e bin.demanglecmd=true -e emu.str=true iGoat-Swift.fat/iGoat-Swift.arm_32.0
[0x000bfe60]> aaaa
```

Notice that we won’t find the swift symbols we would like to have (the ones from the app itself). The only thing we will have is demangled symbols from the standard library (see `is~..`).

请注意，我们找不到我们想要的 Swift 符号（来自应用程序本身的符号）。我们唯一拥有的是标准库中解码后的符号（请参见`is〜..`）。

Let’s see what we can find about swift among the sections of the binary:

让我们看看二进制文件中关于 Swift 的部分能找到什么：

```text
iS~swift
09 0x0022f400 10501 0x00233400 10501 -r-x 9.__TEXT.__swift3_typeref
10 0x00231d08   456 0x00235d08   456 -r-x 10.__TEXT.__swift3_assocty
11 0x00231ed0   656 0x00235ed0   656 -r-x 11.__TEXT.__swift2_proto
12 0x00232160  3284 0x00236160  3284 -r-x 12.__TEXT.__swift3_fieldmd
13 0x00232e34    60 0x00236e34    60 -r-x 13.__TEXT.__swift3_builtin
14 0x00232e70  2772 0x00236e70  2772 -r-x 14.__TEXT.__swift3_reflstr
16 0x002339ec  1552 0x002379ec  1552 -r-x 16.__TEXT.__swift3_capture
```

See that `__swift3_reflstr`? Yes, it is using reflection.

看到那个`__swift3_reflstr`了吗？是的，它正在使用反射。

That’s not good for our current approach (inspect the binary using only r2, static-only approach), we cannot expect to find much within the disassembly. We will learn how to get more information in future articles (spoiler: also involving r2). For now, we will see how far we can go and how much of the code we can recognize without having all that information.

这对于我们当前的方法（仅使用r2、静态方法来检查二进制文件）不好，我们不能指望在反汇编中找到太多信息。在未来的文章中，我们将学习如何获得更多信息（剧透：也涉及r2）。现在，让我们看看能走多远，并且没有所有那些信息时可以识别出多少代码。

Let’s pretend we have not seen the source code and we want to find this “Keychain Exercise”.

假设我们还没有看过源代码，想要找到这个“Keychain Exercise”。

I assume you already know a bit of radare2 so I won’t explain the commands. If you don’t know what they do just open r2 and ask. For example, you want to know what ic does?: type `ic?`.

我假设你已经知道一点radare2了，所以我不会解释命令。如果你不知道它们是干嘛的，请打开r2并询问。例如，你想知道ic是干什么用的吗？输入`ic?`即可。

```text
$ r2 --
 -- Radare2, what else?
[0x00000000]> ic?
| ic                 List classes, methods and fields
| icc                List classes, methods and fields in Header Format
```

Watch a video if you’re lazy to ask. [This one](https://www.youtube.com/watch?v=ARH1S8ygDnk&ab_channel=PancakeNopcode) from r2con 2018 for example.

如果你懒得问，可以看一个视频。例如[这个](https://www.youtube.com/watch?v=ARH1S8ygDnk&ab_channel=PancakeNopcode)来自2018年r2con的视频。

## Checking the classes

First we can take a look at the classes:

首先我们可以看一下这些类：

```bash
ic~+class | grep iGoat
...
0x00281678 [0x000efe48 - 0x000f0378] (sz 1328) class 0 iGoat_Swift.HTMLViewController
0x002816b0 [0x000f4b48 - 0x000f4d60] (sz 536) class 0 iGoat_Swift.CenterContainmentSegue
0x002816c8 [0x000f4f68 - 0x000f5578] (sz 1552) class 0 iGoat_Swift.KeychainExerciseVC
0x002816ec [0x000f86bc - 0x000f8a6c] (sz 944) class 0 iGoat_Swift.CutAndPasteExerciseVC
0x00281704 [0x000f8bf0 - 0x000f92c4] (sz 1748) class 0 iGoat_Swift.BinaryPatchingVC
0x00281720 [0x000f94e4 - 0x000f9fa8] (sz 2756) class 0 iGoat_Swift.URLSchemeAttackExerciseVC
...
```

There we can find `iGoat_Swift.KeychainExerciseVC` in the address `0x002816c8`.

在那里，我们可以在地址`0x002816c8`中找到`iGoat_Swift.KeychainExerciseVC`。

## Checking the flags

Another option would be to take a look at the flags (`f`) and grep (`~`) case insensitive (`+`) for Keychain:

另一个选择是查看 Keychain 的标志（f）和 grep（~）不区分大小写（+）。

```text
[0x00044798]> f~+Keychain
0x001f2330 38 str.TtC11iGoat_Swift18KeychainExerciseVC
...
0x001f2450 26 str.Error_updating_keychain
0x001f4ccf 52 str.Unexpected_error__d_deleting_identity_from_keychain
0x001f801a 49 str.CBLOpenIDConnectAuthorizer_keychainAttributes
0x001f80fd 34 str.:_No_ID_token_found_in_Keychain
0x001f8170 32 str.:_Read_ID_token_from_Keychain
...
0x002816c8 1 class.iGoat_Swift.KeychainExerciseVC
0x000f4f68 1 method.iGoat_Swift.KeychainExerciseVC.usernameTextField
0x000f4f8c 1 method.iGoat_Swift.KeychainExerciseVC.setUsernameTextField:
0x000f4fa4 1 method.iGoat_Swift.KeychainExerciseVC.passwordTextField
0x000f4fc8 1 method.iGoat_Swift.KeychainExerciseVC.setPasswordTextField:
0x000f4fe0 1 method.iGoat_Swift.KeychainExerciseVC.viewDidLoad
0x000f5094 1 method.iGoat_Swift.KeychainExerciseVC.loginActionWithSender:
0x000f5290 368 method.iGoat_Swift.KeychainExerciseVC.initWithNibName:bundle:
0x000f5578 1 method.iGoat_Swift.KeychainExerciseVC.initWithCoder:
```

Again, we see the class `iGoat_Swift.KeychainExerciseVC` in the address `0x002816c8`.

再次看到类`iGoat_Swift.KeychainExerciseVC`在地址`0x002816c8`中。

## Class info

We can also get the full information about this class:

我们还可以获取有关这个类的完整信息：

```text
[0x00044f44]> ic iGoat_Swift.KeychainExerciseVC
class iGoat_Swift.KeychainExerciseVC
0x000f4f68 method iGoat_Swift.KeychainExerciseVC      usernameTextField
0x000f4f8c method iGoat_Swift.KeychainExerciseVC      setUsernameTextField:
0x000f4fa4 method iGoat_Swift.KeychainExerciseVC      passwordTextField
0x000f4fc8 method iGoat_Swift.KeychainExerciseVC      setPasswordTextField:
0x000f4fe0 method iGoat_Swift.KeychainExerciseVC      viewDidLoad
0x000f5094 method iGoat_Swift.KeychainExerciseVC      loginActionWithSender:
0x000f5290 method iGoat_Swift.KeychainExerciseVC      initWithNibName:bundle:
0x000f5578 method iGoat_Swift.KeychainExerciseVC      initWithCoder:
0x000f5140 method iGoat_Swift.KeychainExerciseVC      .cxx_destruct
```

Notice the method `viewDidLoad` located at `0x000f4fe0`.

请注意位于`0x000f4fe0`的`viewDidLoad`方法。

Tip: use `icc` for a nice c-header-like output:

提示：使用`icc`可以获得类似C头文件的输出。

```swift
@interface iGoat_Swift.KeychainExerciseVC :
{
   iGoat_Swift.KeychainExerciseVC::(ivar)usernameTextField
   iGoat_Swift.KeychainExerciseVC::(ivar)passwordTextField
}
- (void) setUsernameTextField:
- (void) setPasswordTextField:
- (void) viewDidLoad
- (void) loginActionWithSender:
@end
```

If you want you can save it to a file `icc > iGoat-Swift.arm_32.0.h` or just display it with the internal less: `icc~..`
如果您想要，可以将其保存到文件icc > iGoat-Swift.arm_32.0.h中，或者只需使用内部less显示它：icc〜..

Why are we insterested in the `viewDidLoad` method?

我们为什么对`viewDidLoad`方法感兴趣？

> func viewDidLoad(): This method is called after the view controller has loaded its view hierarchy into memory. This method is called regardless of whether the view hierarchy was loaded from a nib file or created programmatically in the loadView() method. You usually override this method to perform additional initialization on views that were loaded from nib files.
> 
> func viewDidLoad（）：此方法在视图控制器将其视图层次结构加载到内存后调用。无论视图层次结构是从nib文件加载还是在loadView（）方法中以编程方式创建，都会调用此方法。通常，您会重写此方法以对从nib文件加载的视图执行其他初始化。

There we will find the main code of the exercise. If we seek to `0x000f4fe0`, we see it was tagged as `method.iGoat_Swift.KeychainExerciseVC.viewDidLoad` (we’ve seen this before in the flags).

在那里，我们将找到练习的主要代码。如果我们寻求0x000f4fe0，则可以看到它被标记为method.iGoat_Swift.KeychainExerciseVC.viewDidLoad（我们之前已经见过这个标志）。

## Disassembling

We have found our “entry point”, let’s inspect it closely.

我们已经找到了我们的“入口点”，让我们仔细检查一下。

### viewDidLoad

r2 shows the following disassembly:

r2 显示以下反汇编：

```asm
[0x000f4ff4]> pdf
            ;-- method.iGoat_Swift.KeychainExerciseVC.viewDidLoad:
╭ (fcn) sub.objc_retain_fe0 180
│   sub.objc_retain_fe0 ();
│           ; var int local_0h @ sp+0x0
│           ; var int local_4h @ sp+0x4
│           ; var int local_8h @ sp+0x8
│           ; var int local_ch @ sp+0xc
│           ; UNKNOWN XREF from str. (+0x14)
│           0x000f4fe0      b0402de9       push {r4, r5, r7, lr}
│           0x000f4fe4      08708de2       add r7, sp, 8
│           0x000f4fe8      10d04de2       sub sp, sp, 0x10            ; "T"
│           0x000f4fec      e4560ce3       movw r5, 0xc6e4
│           0x000f4ff0      0040a0e1       mov r4, r0
│           0x000f4ff4      185040e3       movt r5, 0x18
│           0x000f4ff8      05509fe7       ldr r5, [0x000f5000]        ; [0xf5000:4]=0xe3550000
│           0x000f4ffc      0aae03eb       bl sym.imp.objc_retain
│           ; DATA XREF from sub.objc_retain_fe0 (0xf4ff8)
│           0x000f5000      000055e3       cmp r5, 0
│       ╭─< 0x000f5004      0a00001a       bne 0xf5034                 ; likely
│       │   0x000f5008      2c0009e3       movw r0, 0x902c
│       │   0x000f500c      180040e3       movt r0, 0x18
│       │   0x000f5010      00008fe0       add r0, pc, r0
│       │   0x000f5014      080080e2       add r0, r0, 8               ; 0x27e04c ; aav.0x0027e04c
│       │   0x000f5018      6076ffeb       bl sym.func.000d29a0; sym.func.000d29a0(0x27e04c)
│       │   0x000f501c      0050a0e1       mov r5, r0                  ; aav.0x0027e04c
│       │   0x000f5020      b0060ce3       movw r0, 0xc6b0
│       │   0x000f5024      180040e3       movt r0, 0x18
│       │   0x000f5028      5bf07ff5       dmb ish
│       │   0x000f502c      00008fe0       add r0, pc, r0
│       │   0x000f5030      005080e5       str r5, [r0]
│       │   ; CODE XREF from sub.objc_retain_fe0 (0xf5004)
│       ╰─> 0x000f5034      08408de5       str r4, [sp + local_8h]
│           0x000f5038      08008de2       add r0, sp, 8
│           0x000f503c      0c508de5       str r5, [sp + local_ch]
│           0x000f5040      641203e3       movw r1, 0x3264             ; 'd2'
│           0x000f5044      181040e3       movt r1, 0x18
│           0x000f5048      01109fe7       ldr r1, [0x000f5050]        ; [0xf5050:4]=0xe30a085c
│           0x000f504c      e6ad03eb       bl sym.imp.objc_msgSendSuper2
│           ; DATA XREF from sub.objc_retain_fe0 (0xf5048)
│           0x000f5050      5c080ae3       movw r0, 0xa85c
│           0x000f5054      0010a0e3       mov r1, 0
│           0x000f5058      0f0040e3       movt r0, 0xf
│           0x000f505c      30330de3       movw r3, 0xd330
│           0x000f5060      0f3040e3       movt r3, 0xf
│           0x000f5064      04108de5       str r1, [sp + local_4h]
│           0x000f5068      0510a0e3       mov r1, 5
│           0x000f506c      00008fe0       add r0, pc, r0              ; 0x1ef8d0 ; "iGoat" ; str.iGoat
│           0x000f5070      03308fe0       add r3, pc, r3              ; 0x1f23a8 ; "taoGi" ; str.taoGi
│           0x000f5074      00108de5       str r1, [sp]
│           0x000f5078      0510a0e3       mov r1, 5
│           0x000f507c      0020a0e3       mov r2, 0
│           0x000f5080      c50100eb       bl sub.SaveUser_79c
│           0x000f5084      0400a0e1       mov r0, r4
│           0x000f5088      e3ad03eb       bl sym.imp.objc_release
│           0x000f508c      08d047e2       sub sp, r7, 8
╰           0x000f5090      b080bde8       pop {r4, r5, r7, pc}        ; r13
```

Method summary:

方法概述：

```text
[0x000f4ff4]> pds
0x000f4ffc bl sym.imp.objc_retain
0x000f5018 bl sym.func.000d29a0
0x000f504c bl sym.imp.objc_msgSendSuper2
0x000f506c str.iGoat
0x000f5070 str.taoGi
0x000f5080 bl sub.SaveUser_79c
0x000f5088 bl sym.imp.objc_release
;-- method.iGoat_Swift.KeychainExerciseVC.loginActionWithSender::
0x000f50a8 bl sym.imp.objc_retain
0x000f50b0 bl sym.imp.objc_retain
0x000f50b8 bl sub.swift_unknownWeakLoadStrong_d5c
0x000f50c0 bl sym.imp.objc_release
0x000f50d0 b sym.imp.objc_release
```

Things to notice here:

* `func viewDidLoad()` turns into an objc_retain: `sub.objc_retain_fe0`
* We can see that even in the summary we can find the strings `iGoat` and `taoGi`.
* It calls a subroutine `sub.SaveUser_79c` using these strings.

这里需要注意的事项：

* `func viewDidLoad()` 转换为 objc_retain: `sub.objc_retain_fe0`
* 我们可以看到即使在摘要中也能找到字符串 `iGoat` 和 `taoGi`。
* 它使用这些字符串调用子例程 `sub.SaveUser_79c`。

### sub.SaveUser_79c

The subroutine `sub.SaveUser_79c` is located in `0x000f579c`:

子程序 `sub.SaveUser_79c` 位于 `0x000f579c`：

```asm
[0x000f4ff4]> s sub.SaveUser_79c
[0x000f579c]> pdf
╭ (fcn) sub.SaveUser_79c 516
│   sub.SaveUser_79c ();
│           ; var int local_0h @ sp+0x0
│           ; var int local_4h @ sp+0x4
│           ; var int local_8h @ sp+0x8
│           ; var int local_ch @ sp+0xc
│           ; var int local_10h @ sp+0x10
│           ; var int local_14h @ sp+0x14
│           ; var int local_18h @ sp+0x18
│           ; var int local_1ch @ sp+0x1c
│           ; var int local_20h @ sp+0x20
│           ; var int local_24h @ sp+0x24
│           ; var int local_28h @ sp+0x28
│           ; var int local_2ch @ sp+0x2c
│           ; var int local_30h @ sp+0x30
│           ; var int local_34h @ sp+0x34
│           ; var int local_48h @ sp+0x48
│           ; var int local_4ch @ sp+0x4c
│           ; CALL XREF from sub.objc_retain_fe0 (0xf5080)
│           0x000f579c      f0402de9       push {r4, r5, r6, r7, lr}
│           0x000f57a0      0c708de2       add r7, sp, 0xc
│           0x000f57a4      00052de9       push {r8, sl}
│           0x000f57a8      028b2ded       vpush {d8}
│           0x000f57ac      58d04de2       sub sp, sp, 0x58            ; 'X'
│           0x000f57b0      0340a0e1       mov r4, r3
│           0x000f57b4      a53b0ce3       movw r3, 0xcba5
│           0x000f57b8      0f3040e3       movt r3, 0xf
│           0x000f57bc      0c5097e5       ldr r5, [r7, 0xc]
│           0x000f57c0      03308fe0       add r3, pc, r3              ; 0x1f236d ; "SaveUser" ; str.SaveUser
│           0x000f57c4      2c308de5       str r3, [sp + local_2ch]
│           0x000f57c8      0830a0e3       mov r3, 8
│           0x000f57cc      0060a0e3       mov r6, 0
│           0x000f57d0      30308de5       str r3, [sp + local_30h]
│           0x000f57d4      38308de2       add r3, sp, 0x38
│           0x000f57d8      34608de5       str r6, [sp + local_34h]
│           0x000f57dc      470083e8       stm r3, {r0, r1, r2, r6}
│           0x000f57e0      0100a0e3       mov r0, 1
│           0x000f57e4      48608de5       str r6, [sp + local_48h]
│           0x000f57e8      4c608de5       str r6, [sp + local_4ch]
│           0x000f57ec      5000cde5       strb r0, [sp, 0x50]
│           0x000f57f0      0500a0e1       mov r0, r5
│           0x000f57f4      30ae03eb       bl sym.imp.swift_unknownRetain
│           0x000f57f8      081097e5       ldr r1, [r7, 8]
│           0x000f57fc      2c308de2       add r3, sp, 0x2c
│           0x000f5800      0400a0e1       mov r0, r4
│           0x000f5804      0520a0e1       mov r2, r5
│           0x000f5808      0080a0e3       mov r8, 0
│           0x000f580c      dea400eb       bl sub._b8c; sub._b8c(0x0, 0x4042f04f)
│           0x000f5810      000058e3       cmp r8, 0
│           0x000f5814      1cd04702       subeq sp, r7, 0x1c
│           0x000f5818      028bbd0c       vpopeq {d8}
│           0x000f581c      0005bd08       popeq {r8, sl}
│           0x000f5820      f080bd08       popeq {r4, r5, r6, r7, pc}  ; aav.0x000cf2c0
│           0x000f5824      2fe1ffeb       bl sym.func.000edce8
│           0x000f5828      3810a0e3       mov r1, 0x38                ; '8'
│           0x000f582c      0320a0e3       mov r2, 3
│           0x000f5830      0350a0e3       mov r5, 3
│           0x000f5834      99c2ffeb       bl sym.func.000e62a0; sym.func.000e62a0(0x0)
│           0x000f5838      0040a0e1       mov r4, r0
│           0x000f583c      000c0ce3       movw r0, 0xcc00             ; "xD"
│           0x000f5840      0f0040e3       movt r0, 0xf
│           0x000f5844      0610a0e3       mov r1, 6
│           0x000f5848      00008fe0       add r0, pc, r0              ; 0x1f2450 ; "Error updating keychain - " ; str.Error_updating_keychain
...
```

Method summary:

方法概述：

```asm
[0x000f579c]> pds
0x000f57c0 str.SaveUser
0x000f57f4 bl sym.imp.swift_unknownRetain
0x000f580c bl sub._b8c
0x000f5824 bl sym.func.000edce8
0x000f5834 bl sym.func.000e62a0
0x000f5848 str.Error_updating_keychain
0x000f5868 bl sym.func.000f0e34
```

Things to notice here:

* The XREF from viewDidLoad: ; CALL XREF from sub.objc_retain_fe0 (0xf5080).
* the string SaveUser
* 3 function calls: sym.func.000edce8 and sym.func.000e62a0 and sym.func.000f0e34
* the string Error updating keychain -

注意事项：

* 从viewDidLoad的XREF：; 从sub.objc_retain_fe0（0xf5080）调用XREF。
* 字符串 SaveUser
* 3个函数调用：sym.func.000edce8和sym.func.000e62a0和sym.func.000f0e34
* 字符串Error updating keychain -

So we can guess that it tries to update the Keychain here.

因此，我们可以猜测它在这里尝试更新Keychain。

Now that we see this string `Error updating keychain` - … Imagine we haven’t started by looking at the classes (ic) but by looking at the strings (`iz`), which is also a very common approach. How would we find our way here? Just by finding out where this string is being used. Yes, cross-references:

现在我们看到了这个字符串“Error updating keychain -”...假设我们没有从查看类（ic）开始，而是从查看字符串（iz）开始，这也是一种非常常见的方法。我们如何找到自己的路？只需找出该字符串被使用的位置即可。是的，交叉引用：

```
iz~+keychain
1530 0x001ee330 0x001f2330  37  38 (4.__TEXT.__cstring) ascii _TtC11iGoat_Swift18KeychainExerciseVC
1533 0x001ee380 0x001f2380  39  40 (4.__TEXT.__cstring) ascii Error reading password from keychain -
1535 0x001ee3b0 0x001f23b0 154 155 (4.__TEXT.__cstring) ascii /Users/swaroop.yermalkar/AWS/iGoat-Swift-master/iGoat-Swift/iGoat-Swift/Source/Exercises/InsecureLocalDataStorage/KeychainAnalyze/KeychainExerciseVC.swift
1536 0x001ee450 0x001f2450  26  27 (4.__TEXT.__cstring) ascii Error updating keychain -

...

axt @ 0x001f2450
sub.SaveUser_79c 0xf5848 [DATA] add r0, pc, r0
```

## Final Comments

We have only scratched the surface on reversing iOS Swift apps with radare2. We could at least find our way in and get to the methods we were interested in.

我们只是用radare2逆向了iOS Swift应用程序的表面。我们至少可以找到进入并访问我们感兴趣的方法。

In future articles we will learn more about how to obtain more useful information by using other r2 tooling and some combinations of tools (have I heard frida?).

在未来的文章中，我们将学习如何使用其他r2工具和一些工具组合（我听说过frida？）来获取更多有用信息。

> If you have comments, feedback or questions feel free to reach me on Twitter :)  
> 
> 如果您有评论、反馈或问题，请随时通过Twitter联系我 :)

[@grepharder](https://twitter.com/grepharder)

> 注：本文使用 ChatGPT 翻译，如有不当之处，欢迎指正！
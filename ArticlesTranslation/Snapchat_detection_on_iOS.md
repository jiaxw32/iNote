# Snapchat detection on iOS

> 原文链接：https://aeonlucid.com/Snapchat-detection-on-iOS/

Previously we took a look at [Snapchat’s root detection methods on Android][0]. This time we are taking a look at how they detect jailbreaks, tweaks and hooks on iOS.

之前我们研究了[Snapchat在Android上的root检测方法][0]。这次我们来看一下他们如何检测iOS上的越狱、插件和钩子。

All the research in this post is based on Snapchat 10.65.0.66 (832559634).

本文中所有的研究都基于Snapchat 10.65.0.66 (832559634)。

![](https://aeonlucid.com/images/snapchat/ios_login_message.png)

This is the message you see when you try to login with a detected tweak, although not all tweaks trigger this message. Two examples that trigger this message are Flex 3 and Wraith. Some just flag your account and will get you banned later in a ban wave if you are unlucky.

当您尝试使用检测到的tweak登录时，您会看到此消息，但并非所有tweak都会触发此消息。 触发此消息的两个示例是 [Flex 3][] 和 [Wraith][]。 有些只是标记您的帐户，并且如果不幸被禁止，则稍后将在禁令波中被禁止。

## Avoiding bans

So obviously the first thing we want to look at is, what has the community tried so far to stay hidden? If you google around a bit you will most likely end up with these result. For a few of them, I will list the most notable features.

* NoSub (or variants)
  * Disable Cydia Substrate / Substitute entirely for specific apps.
  * Only if you can find an updated version and don’t want to use tweaks on Snapchat.
* [UnSub][2]
  * Hooks and filters libc file system calls.
  * Spoofs the libc getenv to remove the DYLD_INSERT_LIBRARIES variable.
  * Spoofs _dyld_image_count and _dyld_get_image_name to hide tweak related dylibs.
* [Shadow][3]
  * Too much to list.. it hooks way too much.
  * Still misses lots of stuff for Snapchat specifically.


显然，我们首先要看的是社区为了保持隐秘性而尝试过什么？如果你在谷歌上搜索一下，最有可能得到以下结果。对于其中的一些，我将列出最值得注意的特点。

* NoSub（或其变体）
  * 针对特定应用程序完全禁用Cydia Substrate/Substitute。
  * 只有当您找到更新版本并且不想在Snapchat上使用调整时才能使用。
* UnSub
  * 挂钩和过滤libc文件系统调用。
  * 欺骗libc getenv以删除DYLD_INSERT_LIBRARIES变量。
  * 欺骗_dyld_image_count和_dyld_get_image_name以隐藏与调整相关的dylibs。
* Shadow
  * 太多了……它勾住了太多东西。
  * 对于Snapchat来说还是错过了很多东西。

Even [Snapchat themselves recommend NoSub][1]..

甚至Snapchat自己也推荐使用NoSub。

![](https://aeonlucid.com/images/snapchat/ios_snapchat_jailbroken_support.png)

But it seems that nobody knows what Snapchat is **exactly** doing to detect everything. Which is why I am writing this post. Only one that I have seen [publicly making efforts][4] to figure this out is the developer of Phantom, CokePokes.

但似乎没有人确切知道Snapchat是如何检测一切的。这就是我写这篇文章的原因。唯一一个公开努力解决这个问题的人是Phantom的开发者CokePokes。

## How are they doing it?

I will try my best to explain every check they do in Snapchat 10.65.0.66.

我会尽力解释Snapchat 10.65.0.66中的每个检查。

When you launch the app they create a new thread using [pthread_create][] that runs all the checks. At the end of these checks an integer is stored with flags of everything that was detected on the device. Some of these checks are then ran every 31 seconds.

当您启动应用程序时，它们使用pthread_create创建一个新线程来运行所有检查。在这些检查结束时，将存储一个整数，其中包含在设备上检测到的所有标志。其中一些检查每31秒运行一次。

All the code executed for these checks is obfuscated with [Snapchats in-house obfuscation tools][] and thus very annoying to look at using tools such as IDA.

执行这些检查的所有代码都是使用Snapchats内部混淆工具混淆的，因此使用IDA等工具非常麻烦。

### Code signature checks

One of the first things they do is checking and storing stuff from the code signature. This happens using the sys_csops(169) syscall, which is pretty much undocumented but is very similar to the code here.

他们做的第一件事之一是检查并存储代码签名中的内容。这是使用sys_csops(169)系统调用完成的，该调用几乎没有文档说明，但与此处的代码非常相似。

* [xnu/bsd/kern/kern_proc.c.html#csops][5]
* [xnu/bsd/kern/kern_proc.c.html#csops_internal][6]

They execute the following operations:

他们执行以下操作：

* CS_OPS_STATUS
* CS_OPS_CDHASH
* CS_OPS_ENTITLEMENTS_BLOB

The most important one of this is the CS_OPS_STATUS, this retrieves the current codesigning status of the process. A jailbroken device can respond with messy status flags. Such as:

其中最重要的是CS_OPS_STATUS，它检索进程的当前代码签名状态。越狱设备可能会返回混乱的状态标志，例如：

* CS_GET_TASK_ALLOW
* CS_INSTALLER
* CS_PLATFORM_BINARY
* CS_DEBUGGED (Process was debugged / is being debugged)
* Or missing CS_VALID.

A normal device would have these flags:

一个正常的设备应该有这些标志：

* CS_VALID
* CS_HARD
* CS_KILL
* CS_ENFORCEMENT
* CS_REQUIRE_LV
* CS_DYLD_PLATFORM
* CS_SIGNED

For all available flags and their descriptions, see [this page][7].

请查看此页面以获取所有可用标志及其描述。

The result of `CS_OPS_STATUS` and `CS_OPS_CDHASH` are stored and later sent to the Snapchat servers, encrypted.

`CS_OPS_STATUS` 和 `CS_OPS_CDHASH` 的结果将被存储并加密后发送到 Snapchat 服务器。

### Bundle check

This is a simple check but quite effective if not noticed by a tweak developer. Pseudo code looks like this.

这是一个简单的检查，但如果没有被调整开发人员注意到，它会非常有效。伪代码如下。

```c
x0 = CFBundleGetMainBundle()
x1 = CFBundleGetIdentifier(x0)
x2 = CFStringGetCStringPtr(x1)
strncmp("com.toyopagroup.picaboo", x2)
```

### Dyld check

Snapchat has two methods to iterate all loaded dylibs.

Snapchat有两种方法来迭代所有已加载的dylibs。

#### First attempt | 第一种尝试

One way is using [dyld_get_image_header][8] and [dladdr][9]. They iterate over dyld_get_image_header until it returns null and checks if it has seen everything with [dyld_image_count][10]. The dladdr method provides them with the path of the dylib. These are checked against a few unknown strings but removing everything substrate related from the dyld list fixes this check.

一种方法是使用dyld_get_image_header和dladdr。它们迭代dyld_get_image_header直到返回null，并使用dyld_image_count检查是否已经看到了所有内容。 dladdr方法为它们提供了dylib的路径。这些被检查与几个未知字符串相匹配，但从dyld列表中删除与substrate相关的所有内容可以修复此检查。

#### Second attempt | 第二种尝试

The other method they use is calling [task_info][] with flavor TASK_DYLD_INFO. This also gives them a list of all loaded dylibs and must be fixed separately from the first dyld check.

他们使用的另一种方法是调用带有flavor TASK_DYLD_INFO的task_info。这也给他们一个所有已加载的dylibs列表，必须单独从第一个dyld检查中进行修复。

### File system checks

There are a couple of file system checks, of which all use the sys_access(33) syscall.

有几个文件系统检查，其中所有的检查都使用 sys_access(33) 系统调用。

#### First list

* /Library/Application Support/PhLite/phlite.bundle/AuthAPI.pem
* /private/var/tmp/cydia.log
* /bin/bash
* /usr/sbin/sshd
* /usr/libexec/ssh-keysign
* /usr/libexec/sftp-server
* /etc/ssh/sshd_config
* /.installed_yaluX
* /Library/LaunchDaemons/dropbear.plist
* /usr/local/bin/dropbear
* /System/Library/Caches/com.apple.dyld/enable-dylibs-to-override-cache
* /.cydia_no_stash
* /var/log/jailbreakd-stdout.log
* /etc/motd
* /usr/lib/libsubstitute.dylib
* /var/tmp/slide.txt

#### Second list

* /private/var/containers/Bundle/Application/AD659AF8-68C3-4E4B-BF02-236E1F733005/Snapchat.app/Ghay
* /private/var/containers/Bundle/Application/AD659AF8-68C3-4E4B-BF02-236E1F733005/Snapchat.app/Snapchat.crc
* /private/var/containers/Bundle/Application/AD659AF8-68C3-4E4B-BF02-236E1F733005/Snapchat.app/embedded.mobileprovision

#### Last one (and expected to exist) | 最后一个（并且预计存在）

* /private/var/containers/Bundle/Application/AD659AF8-68C3-4E4B-BF02-236E1F733005/Snapchat.app/PlugIns

The last one makes it a bit harder to fix, since you can not simply replace the arm instructions with something that makes it always return false. Thus requiring an inline hook as replacement for the syscall so you gain full control over it.

最后一个问题让修复变得更加困难，因为你不能简单地用某些东西替换ARM指令，使其始终返回false。这就需要使用内联钩子来替换系统调用，以便完全控制它。

### Obj-C - Class checks

A lot of classes are checked from a lot of different tweaks. This is done using [objc_getClass][11].

许多类别会从不同的 tweak 中进行检查。这是通过使用 objc_getClass 实现的。

* SCOthmanPrefs
* SCOthmanSnapSaver
* SCOFiltersOthman
* SCSnapchPrefs
* SCSnapchLocation
* SCOFiltersSnapch
* PHSnapSaver
* PHRegisterViewController
* phlite
* dfnvrknsv
* PHSSaver
* PHMainSettingsVC
* SCPPrivacySettings
* SCPSettings
* SCPSavedMediaSettings
* SNAPCHAT_SCPSnapUsageSettings
* SNAPCHAT_SCPSegmentedController
* vSNAPCHAT_CZPickerView
* CTAdBase
* CTRequestModel
* CTBannerView
* CPAdManager
* MMNativeAdController
* TweakBoxStartupManager
* SNAPCHAT_GPHelper
* SCKsausaPrefs
* SCSCGoodSnapSaver
* SNAPCHAT_XXXXXXX_GPHelper
* SCOFiltersHelper
* _xxx
* PHSSaver
* SIGMAPOINT_GPHelper
* SCS SnapSaver
* SCW wSnapSaver
* CYJSObject
* P D
* R t
* AVCameraViewControlIer
* SCAppDeIegate
* FLEXManager
* oJXM
* fJWs
* yytp
* FLManager
* DecryptScriptAlertView
* DzAdsManager

### Obj-C - Method checks

They also check methods. This happens using [objc_getClass][11] and then [class_getInstanceMethod][12]. If any exists, you get flagged.

他们还会检查方法。这是通过使用objc_getClass，然后class_getInstanceMethod来完成的。如果存在任何一个方法，则会被标记。

* NSMutableString
  * a
  * b
  * c
* SCAppDelegate
  * MZ42SGH98C:
* SCOperaPageViewController
  * saveButtonPressed
* UIViewController
  * dzDidTapGalleryButton

### Obj-C - Method integrity checks

Next up is Snapchats own methods. For the classes listed below they first call [class_copyMethodList][13]. Then for every [Method][14] they check if the IMP pointer (address of the function) is within its own __text segment. This is how they detect whether a method has been hooked.

接下来是Snapchat自己的方法。对于下面列出的类，它们首先调用class_copyMethodList函数。然后对于每个方法，它们检查IMP指针（函数地址）是否在其自己的__text段内。这就是他们检测一个方法是否被hook的方式。

* SCAppDelegate
* MainViewController
* SCChatMainViewController
* SCChatViewControllerV3
* SCScreenshotDetector
* SCBaseMediaOperaPresenter
* SCOperaPageViewController
* SCLoginService
* SCAdsHoldoutExperimentContext
* SCExperimentManager
* SCCaptionDefaultTextView
* SCChatTypingHandler
* Story
* SCChatMessageV3
* SCOperaViewersLayer

Thanks to dzan for telling me to check the __text segment. :-)

感谢 dzan 提醒我检查 __text 段。:-)

### Symbol checks

They also check for a couple of symbols using [dlsym][14]. If the result is not null, you get flagged.

他们还使用dlsym检查了一些符号。如果结果不为空，你就会被标记。

* MSHookMessageEx
* MSHookFunction
* _Z17replaced_readlinkPKcPcm
* hooksArray
* _OBJC_METACLASS_$__xxx
* _OBJC_CLASS_$_PHSSaverV2
* plist
* flexBreakPoint
* convert_coordinates_from_device_to_interface
* OBJC_METACLASS_$_DzSnapHelper
* ChKey2

### Symbol hook checks

A few symbols are resolved using [dlsym][14] to check whether they have been hooked. They first resolve dlsym using dlsym.. yeah.. That result gets used for the dlsym of the symbols below. For every address returned, the first 4 bytes are checked for common hook related instructions.

一些符号使用dlsym进行解析，以检查它们是否被挂钩。它们首先使用dlsym来解析dlsym..是的..该结果用于下面符号的dlsym。对于返回的每个地址，都会检查前4个字节是否包含常见的挂钩相关指令。

* dlsym
* objc_getClass
* class_getInstanceMethod
* sel_registerName
* class_copyMethodList
* _dyld_image_count
* _dyld_get_image_header
* dladdr

### Environment variables

I need to be honest, this is a very annoying way how they check for injection because it is annoying to fix. Instead of using [getenv][] they use the [environ][] variable. Since it is a variable, you can not “hook” it.

我必须坦诚，这是一种非常烦人的检查注入方式，因为修复起来很麻烦。他们没有使用 getenv 而是使用了 environ 变量。由于它是一个变量，你无法“hook”它。

At least the following variables are detected.

至少以下变量会被检测到。

* DYLD_INSERT_LIBRARIES=/usr/lib/TweakInject.dylib
* _MSSafeMode=0

### Sandbox check

Probably not an issue for anyone.

可能对任何人都不是问题。

![](https://aeonlucid.com/images/snapchat/ios_sandbox.png)

### Fingerprinting

Not much detection done here but still relevant, using sys_sysctl(202) they request at least the following properties.

并没有太多的检测工作，但仍然相关。使用sys_sysctl(202)，他们至少请求以下属性。

* kern.version
* kern.osversion
* kern.proc.pid.<PID>
* hw.machine

### Other

The syscall sys_proc_info(33) is also called a couple of times, which could reveal stuff that is ptracing the process. They also use sys_open(5), [mmap][], sys_close(6) and sys_lstat64(340) on the Snapchat binary. Probably to check for modifications or generating a checksum.

syscall sys_proc_info(33)也被调用了几次，这可能会暴露出正在ptracing进程的东西。他们还在Snapchat二进制文件上使用sys_open(5)，mmap，sys_close(6)和sys_lstat64(340)。可能是为了检查修改或生成校验和。

## How all this stuff was found | 这些东西是如何被发现的

A lot of the work was done using a small iOS emulator build on top of [Unicorn][]. Using an emulator you can see everything they do. Building this has taught me a lot about the internals of the CoreFoundation library of iOS.

很多工作都是使用在Unicorn之上构建的小型iOS模拟器完成的。使用模拟器可以看到他们所做的一切。构建这个过程让我对iOS CoreFoundation库内部有了更深入的了解。

![](https://aeonlucid.com/images/snapchat/ios_emulator.png)

Later I implemented a counter for all of my discoveries in a tweak called [SnapHide][] while carefully keeping track of how my changes modified the detection flags and slowly getting rid of all of them. You can easily find fixes for checks mentioned in this blog post in the “Detections” directory.

后来，我在一个名为SnapHide的调整中实现了对所有发现的计数器，并仔细跟踪我的更改如何修改检测标志，并逐步摆脱它们。您可以在“Detections”目录中轻松找到本博客文章提到的检查修复方法。

You could alternatively trace the syscalls using any of the methods discussed in the WhoYouGonnaSyscall talk by [Hexploitable][]. Slides of the talk can be found [here][].

或者，您可以使用Hexploitable在WhoYouGonnaSyscall演讲中讨论过的任何方法跟踪系统调用。演讲幻灯片可在此处找到。

### A story on how I wasted hours on fixing syscalls

Let’s take sys_access(33) as an example. It’s implementation looks like [this][]. In short, when a file exists and permission is granted, return 0. Otherwise return -1. First thing I did was force both of the results in my emulator but I saw no changes happening to the detection flags.

让我们以 sys_access(33) 为例。它的实现看起来像这样。简而言之，当文件存在且授权时，返回0。否则返回-1。我做的第一件事是在我的模拟器中强制执行两个结果，但我没有看到检测标志发生任何变化。

Later when implementing a fix for this in the [SnapHide][] tweak, I was unable to have it fail. The arm instructions look like this:

后来，在 SnapHide 调整中实施修复时，我无法使其失败。ARM 指令如下：

```arm
MOV             X0, X27 ; path
MOV             X1, #0  ; mode
MOV             X16, #0x21
SVC             0x80    ; SYS_access
MOV             X0, #0xFFFFFFFFFFFFFFFF
CSEL            X0, X0, XZR, CS
MOV             X27, X0 ; Use result
```

In pseudo code:

伪代码实现：

```c
v23 = mac_syscall(SYS_access, a20, 0);
v24 = -1;
if ( !v20 )
  v24 = 0;
*(v21 + 496) = v24;
```

Coming from android I was very confused what happened here. Looking at the instructions, they seem to directly clear the result from the syscall. Looking at the pseudo code reveals a bit more information. Apparently what happens is, “A syscall return errno an sets the carry flag on error” from [here][15]. Setting and clearing the carry flag resulted in detection changes. This took me a few hours to figure out for some reason. Later I found out that I could simply remove the MOV & CSEL instruction. Which gave me 8 bytes more space for patching.

从安卓转过来，我对这里发生的事情感到非常困惑。看着指令，它们似乎直接清除了系统调用的结果。查看伪代码揭示了更多信息。显然，“一个系统调用返回errno并在出错时设置进位标志”，从这里开始检测变化就会产生设置和清除进位标志的效果。由于某种原因，我花费了几个小时才弄明白这一点。后来我发现可以简单地删除MOV&CSEL指令，为修补腾出8个字节空间。

Thanks to [@iGio90][] for telling me to check all registers for changes in lldb.

感谢 [@iGio90][] 告诉我要在lldb中检查所有寄存器是否有变化。

## I use Unsub and haven’t been banned (yet)

Awesome! That’s a good thing. However, keep in mind that some of the checks above are not countered by UnSub at this moment. Everything that has syscall mentioned for example is not countered and you will not be able to sign in if you have Flex 3 installed. UnSub does not prevent Cydia Substrate from loading, it [attempts to hide it][16]. Which also fails because Snapchat does not even use this call.

太棒了！这是一件好事。但请记住，目前UnSub无法对上述某些检查进行反制。例如，所有涉及syscall的内容都无法被反制，如果您安装了Flex 3，则将无法登录。UnSub不能阻止Cydia Substrate加载，它只是试图隐藏它。而Snapchat甚至不使用此调用，因此也会失败。

Written with the assumption [this is the UnSub][17] everybody uses.

假设这就是大家使用的UnSub。

## Conclusion

This was a very fun but also very annoying 2 weeks with a lot of headaches. I hope this brings some light into why some stuff gets people banned. If there are any issue’s with with tweak feel free to submit an issue on GitHub. If there’s something you’d like me to expand on, let me know!

这是两个星期非常有趣但也非常烦人，让我头痛不已。我希望这能解释为什么某些东西会导致人们被禁止。如果您在使用此修改时遇到任何问题，请随时在 GitHub 上提交问题。如果您想让我进一步扩展某些内容，请告诉我！

Written on October 3, 2019

写于 2019.10.3

[0]: https://aeonlucid.com/Snapchat-detection-on-Android/
[1]: https://help.snapchat.com/hc/en-us/articles/7012304532244
[2]: https://github.com/NepetaDev/UnSub/blob/master/Tweak/Tweak.xm
[3]: https://github.com/jjolano/shadow/tree/master
[4]: https://twitter.com/cokepokes/status/1023114963550797824
[5]: https://fergofrog.com/code/cbowser/xnu/bsd/kern/kern_proc.c.html#csops
[6]: https://fergofrog.com/code/cbowser/xnu/bsd/kern/kern_proc.c.html#csops_internal
[7]: https://fergofrog.com/code/cbowser/xnu/BUILD/obj/EXPORT_HDRS/osfmk/kern/cs_blobs.h.html#_M/CS_VALID
[8]: https://github.com/theos/sdks/blob/master/iPhoneOS14.5.sdk/usr/include/mach-o/dyld.h#L54
[9]: https://man7.org/linux/man-pages/man3/dladdr1.3.html
[10]: https://github.com/theos/sdks/blob/master/iPhoneOS14.5.sdk/usr/include/mach-o/dyld.h#L53
[11]: https://developer.apple.com/documentation/objectivec/1418952-objc_getclass?language=objc
[12]: https://developer.apple.com/documentation/objectivec/1418530-class_getinstancemethod?language=objc
[13]: https://developer.apple.com/documentation/objectivec/1418490-class_copymethodlist?language=objc
[14]: https://linux.die.net/man/3/dlsym
[Unicorn]: https://github.com/unicorn-engine/unicorn
[SnapHide]: https://github.com/AeonLucid/SnapHide
[Hexploitable]: https://twitter.com/hexploitable
[here]: https://github.com/radareorg/r2con2019/blob/master/talks/WhoYouGonnaSyscall/Hex-r2con2019-WhoYouGonnaSyscall.pdf
[this]: https://man7.org/linux/man-pages/man2/access.2.html
[15]: https://stackoverflow.com/questions/47834513/64-bit-syscall-documentation-for-macos-assembly
[@iGio90]: https://twitter.com/igio90
[16]: https://github.com/NepetaDev/UnSub/blob/9652045ff098d07ecf9c920c258fd20d0fe51d13/Tweak/Tweak.xm#L237
[17]: https://github.com/NepetaDev/UnSub
[Flex 3]: http://cydia.saurik.com/package/com.johncoates.flex3/
[Wraith]: https://www.reddit.com/r/jailbreak/comments/9baacc/release_wraith_snapchatphantom_replacement/
[pthread_create]: https://man7.org/linux/man-pages/man3/pthread_create.3.html
[Snapchats in-house obfuscation tools]: https://www.crunchbase.com/organization/strong-codes
[task_info]: https://developer.apple.com/documentation/kernel/1537934-task_info
[getenv]: 
http://man7.org/linux/man-pages/man3/getenv.3.html
[environ]: http://sourceware.org/git/?p=glibc.git;a=blob;f=posix/environ.c
[mmap]: http://man7.org/linux/man-pages/man2/mmap.2.html
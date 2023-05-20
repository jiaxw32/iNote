# Reverse Engineering Starling Bank (Part II): Jailbreak & Debugger Detection, Weaknesses & Mitigations

Starling Bank 逆向工程（第二部分）：越狱和调试器检测，弱点与改进措施 2020-08-02

> 原文地址：https://hot3eed.github.io/2020/08/02/starling_p2_detections_mitigations.html

## Three layers

There are three layers of protection applied before main starts doing its intended work. Frida detection, jailbreak detection, and debugger detection.

在主程序开始执行其预定工作之前，会应用三层保护：Frida检测、越狱检测和调试器检测。

## Frida listens

When Frida runs in [injected mode][1], there’s a daemon, frida-server, that listens for connections on port 27042 and exposes frida-core. And as mentioned in [the OWASP guide][2], you could detect Frida in this mode of operation using this port. Starling uses this method.

当Frida以[注入模式][1]运行时，会有一个守护进程frida-server，在端口27042上监听连接并公开frida-core。正如[OWASP指南][2]中提到的那样，您可以使用此端口检测Frida在此操作模式下的情况。Starling使用了这种方法。

First it gets all TCP interfaces using [getifaddrs][3] and checks for interfaces with the address family [AF_INET][4], which is for Internet connections.

首先，它使用[getifaddrs][3]获取所有TCP接口，并检查具有地址族[AF_INET][4]的接口，这是用于Internet连接的。

```c
ifa->ifa_addr->sa_family == AF_INET
```

After getting Internet interfaces, which in my experiments have been the lo0 (loopback/localhost) and en2 (USB ethernet), a **socket** is created, and bind() is called to try and bind that socket to the interface’s address at port 27024. All that does is basically check if that port is already open, in all Internet interfaces iteratively.

在获取了互联网接口（在我的实验中是lo0（环回/本地主机）和en2（USB以太网））之后，创建一个套接字，并调用bind()尝试将该套接字绑定到端口27024处的接口地址。这基本上只是迭代地检查所有互联网接口是否已经打开了该端口。

```c
int status = bind(sfd, addr, sizeof(addr));
```

If Frida is listening there, bind() will return an error [EADDRINUSE5][5]. But what if it’s another legit process that has nothing to do with Frida but for some reason chose to listen on that port? Frida uses the [D-Bus protocol][6], so Starling double checks that this is Frida by sending an [AUTH command][7], if it receives a [REJECTED][8] response, then this is D-Bus and this is most likely is Frida.

如果Frida正在监听，bind()将返回错误[EADDRINUSE][5]。但是如果另一个合法的进程选择在该端口上进行监听，而与Frida无关呢？ Frida使用D-Bus协议6，因此Starling通过发送AUTH命令7来再次检查这是否为Frida，如果收到REJECTED8响应，则这是D-Bus，并且很可能是Frida。

```c
char *cmd = "\0AUTH"; 				// null-beginning for some reason
write(sfd, cmd, sizeof(cmd));			// communicate with Frida

char reply[REPLYMAX];
recvfrom(sfd, reply, sizeof(reply));		// Frida replies
if (strncmp(reply, "REJECTED", 8) == 0) { 	// strncmp or something along those lines
	// This is defintely Frida, crash
}
```

## Jailbreak detection

access(), and sometimes stat64(), is a canonical method for checking for the existence of jailbreak artifacts (Cydia, SafeMode, themes, etc.). Starling takes it three steps further:

access()，有时候也会用到stat64()，是检查越狱工具（Cydia、SafeMode、主题等）存在的经典方法。Starling更进一步地进行了三个步骤：

First, before checking for those files using their absolute paths, .e.g "/Applications/Cydia.app", it creates a symlink from the root directory "/" to a file in tmp inside the binary’s sandbox, and uses that symlink to check for the existence of said artifacts, so it would check for the existence for "<sandbox>/tmp/<somefile>/Applications/Cydia.app" instead. Why? Porbably because most jailbreak detection bypass tweaks are expecting absolute addresses, so this bypasses the bypasses.

首先，在检查这些文件的绝对路径之前，例如“/Applications/Cydia.app”，它会在二进制沙盒内部的tmp文件夹中创建一个符号链接，并使用该符号链接来检查所述工件是否存在。因此，它将检查“<sandbox>/tmp/<somefile>/Applications/Cydia.app”的存在性。为什么？可能是因为大多数越狱检测绕过补丁都期望使用绝对地址，所以这可以规避这些绕过补丁。

Second, it checks for non-JB files/directories, e.g. /dev/null, /etc/hosts, and expects access() to return 0, or success. Otherwise, it’ll crash. This is probably to prevent you from trivially hooking access() to always return ENOENT (file doesn’t exist); because you expect it to only check for jailbreak artifacts.

其次，它会检查非JB文件/目录，例如/dev/null、/etc/hosts，并期望access()返回0或成功。否则，它将崩溃。这可能是为了防止您轻易地钩住access()以始终返回ENOENT（文件不存在）；因为您希望它仅检查越狱工件。

Third, it checks for a quite sizable amount of files. Most jailbreak detectors will check for maybe 10 files and that’s it. So all in all it’ll look something like this:

第三，它会检查相当大量的文件。大多数越狱检测器只会检查大约10个文件，就这样而已。所以总体来说，它看起来像这样：

```c
char slnk = "<sandbox>/tmp/<somefile>";	// replace <sandbox> with that of the app
symlink("/", slnk);
int status_lookup[];	// hardcoded, expected status for each file (JB or non-JB)
char artifacts[];	// hardcoded, but strings are obfuscated

for (int i = 0; i < LEN_ARTIFACTS; i++) {
	char artifactp[400];
	sprintf(artifactp, "%s%s", slnk, artifacts[i]);
	int status = access(artifactp, F_OK); 	// just check for its existence
	if (status != status_lookup[i]) {
		// File access isn't what's expected, crash 
	} 
}
```

## kill -0?

There’s a call to kill(getpid(), 0). Regarding the second argument, the man page for kill states:

有一个调用kill(getpid(), 0)。关于第二个参数，kill的man页面说明如下：

```
A value of 0, however, will cause error checking to be performed (with no signal being sent).  This can be used to check the validity of pid.
然而，值为0将导致执行错误检查（但不发送信号）。这可用于检查pid的有效性。
```

Hmm, so it checks if the process actually exists. My guess then is that this is for anti-emulation purposes; because a process wouldn’t normally exist in an emulated enviornment. If anyone has a better explanation, feel free to hit me up.

嗯，所以它检查进程是否真的存在。我猜这是为了反仿真目的；因为在模拟环境中通常不会存在进程。如果有更好的解释，请随时联系我。

## Debugger detection

After confirming that the device isn’t jailbroken using the methods above, the binary will check if a debugger is attached to it via the standard way, sysctl, even Apple has a [page][9] on it. It’s trivial to bypass it by just flipping the P_TRACED flag if it’s on in [info.kp_proc.p_flag][10]. The twist here is that it does this very same check not once, not twice, but thrice. You would think that is just redundant, but it’s not. Remember, with this binary, you can’t single-step your way out of it. The original code should look something like this:

确认设备未越狱后，二进制文件将通过标准方式sysctl检查是否连接了调试器，即使苹果公司也有相关页面9。如果info.kp_proc.p_flag10中的P_TRACED标志已开启，则轻松绕过此检查。这里的关键是它不止一次地进行了相同的检查，而是三次。你可能认为这只是多余的，但事实并非如此。请记住，在使用此二进制文件时，您无法单步跳出。原始代码应该类似于以下内容：

```c
bool is_debugged = amIBeingDebugged();
is_debugged |= amIBeingDebugged();
is_debugged |= amIBeingDebugged();
```

## Weaknesses & mitigations

The Starling team did a great job, kudos to them. But like everything else humans make, there’s room for improvement.

Starling团队做得很好，向他们致敬。但像人类制造的一切一样，还有改进的空间。

## Code signature

I was quite surprised when I was able to re-sign the binary myself, run it on a non-jailbroken device, and see what the execution trace for a normal device (save for the debugger) should look like, it saved me a lot of time actually because I was able to do confirm things quickly, e.g. [bind()][11] should return success. For an app that cares about its security, it’s not a good idea to let the binary run its critical parts when it’s been re-signed by a third-party. 
Mitigation: verify that the binary isn’t signed by a third-party.

当我能够重新签署二进制文件，运行它在非越狱设备上，并查看正常设备（除了调试器）的执行跟踪时，我感到相当惊讶。这样做实际上节省了我很多时间，因为我能够快速确认一些事情，例如bind()11应该返回成功。对于关心其安全性的应用程序来说，在第三方重新签署二进制文件后运行其关键部分并不是一个好主意。
缓解措施：验证二进制文件未被第三方签名。

## Better debugger detection

Although three sysctls are better than one, a non-standard debugger detection would be a good advantage to a binary like this. Although these are kind of trade secrets.

虽然三个sysctl比一个更好，但对于这样的二进制文件来说，非标准调试器检测将是一个很好的优势。虽然这些有点像商业机密。

## Code injection

Currently nothing stops someone from injecting a dylib that [hooks][12] ObjC/Swift methods in this binary and changes its behavior. That’s true even on a jailed device due to the lack of the signature check above. 
Mitigation: verify that no suspicious dylibs (dynamic libraries) are loaded. This could be done using dyld (dynamic linker) functions such as [dlsym()][13] and [_dyld_get_image_count()][14].

目前，没有任何阻止某人在此二进制文件中注入一个[钩子][12] ObjC/Swift方法并更改其行为的dylib。即使是在受监禁的设备上也是如此，因为缺乏上面提到的签名检查。
缓解措施：验证未加载可疑dylibs（动态库）。这可以使用dyld（动态链接器）函数，例如[dlsym()][13]和[_dyld_get_image_count()][14]来完成。

## Anti-tampering

After having reverse engineered the detections, which requires a good amount of skill, nothing stops someone from trivially patching all the checks, and re-packaging the binary, then use it even on a jailed device. 
Possible mitigation: an obfuscated checksum function that verifies the integrity of the checks.

在逆向工程检测后，需要一定的技能，但没有什么可以阻止某人轻松地修补所有检查并重新打包二进制文件，然后即使在受限设备上也可以使用它。
可能的缓解措施：一个混淆的校验和函数来验证检查的完整性。

## More obfuscation?

As long as it doesn’t come at a huge performance cost, more obfuscation techniques would help make breaking jailbreak/debugger detection an even harder task than it already is, and give Starling more advantage in the cat-and-mouse that is reverse engineering.

只要不会带来巨大的性能成本，更多的混淆技术将有助于使破解越狱/调试器检测比现在更加困难，并为Starling在逆向工程中的猫鼠游戏中提供更多优势。

[1]: https://frida.re/docs/modes/#injected
[2]: https://mobile-security.gitbook.io/mobile-security-testing-guide/ios-testing-guide/0x06j-testing-resiliency-against-reverse-engineering
[3]: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/getifaddrs.3.html
[4]: https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/sys/socket.h.auto.html
[5]: https://opensource.apple.com/source/xnu/xnu-201/bsd/sys/errno.h.auto.html
[6]: https://en.wikipedia.org/wiki/D-Bus
[7]: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-command-auth
[8]: https://dbus.freedesktop.org/doc/dbus-specification.html#auth-command-rejected
[9]: https://developer.apple.com/library/archive/qa/qa1361/_index.html
[10]: https://opensource.apple.com/source/xnu/xnu-6153.81.5/bsd/sys/proc.h.auto.html
[11]: https://hot3eed.github.io/2020/07/30/starling_p1_obfuscations.html
[12]: https://developer.apple.com/documentation/objectivec/1418769-method_exchangeimplementations?language=objc
[13]: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlsym.3.html
[14]: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dyld.3.html
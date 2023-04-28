# Automation in Reverse Engineering: String Decryption

> 原文链接： https://synthesis.to/2021/06/30/automating_string_decryption.html

Automation plays a crucial rule in reverse engineering, no matter whether we search for vulnerabilities in software, analyze malware or remove obfuscated layers from code. Once we manually identify repeating patterns, we try to automate the process as far as possible. For automation, it often doesn’t matter if you use [Binary Ninja](https://binary.ninja/), [IDA Pro](https://hex-rays.com/ida-pro/) or [Ghidra](https://ghidra-sre.org/), as long as you have the knowledge how to realize it in your tool of choice. As you will see, you don’t have to be an expert to automate tedious reverse engineering tasks; sometimes it just takes a few lines of code to improve your understanding a lot.

自动化在逆向工程中扮演着至关重要的角色，无论我们是在搜索软件漏洞、分析恶意软件还是移除代码中的混淆层。一旦我们手动识别出重复模式，就会尽可能地尝试自动化这个过程。对于自动化来说，使用Binary Ninja、IDA Pro或Ghidra并不重要，只要你知道如何在所选工具中实现它即可。正如您将看到的那样，您不必成为专家就可以自动执行繁琐的逆向工程任务；有时候只需要几行代码就可以大大提高您的理解能力。

Today, we take a closer look at this process and automate the decryption of strings for a malware sample from the [Mirai botnet](https://en.wikipedia.org/wiki/Mirai_(malware)). Mirai is a malware family that hijacks embedded systems such as IP cameras or home routers by scanning for devices that accept default login credentials. To impede analysis, Mirai samples store those credentials in an encoded form and decode them at runtime using a simple XOR with a constant. In the following, we first manually analyze the string obfuscation. Afterward, we use Binary Ninja’s high-level intermediate language (HLIL) API to get all string references and decrypt them.

今天，我们将更详细地了解这个过程，并自动解密Mirai僵尸网络恶意软件样本中的字符串。Mirai是一种恶意软件系列，通过扫描接受默认登录凭据设备来劫持嵌入式系统（例如IP摄像头或家庭路由器）。为了阻碍分析，在运行时使用简单XOR与常量对存储这些凭据进行编码和解码。接下来，我们首先手动分析字符串混淆情况。然后使用Binary Ninja 的高级中间语言（HLIL）API获取所有字符串引用并对其进行解密。

If you would like to try it on your own, you’ll find the code and the used [malware sample](https://www.virustotal.com/gui/file/c87e5db01d2c942fa6973f4578c9a72813b42f3daa8ba78f1ad035f756a55c78/detection) on [GitHub](https://github.com/mrphrazer/mirai_string_deobfuscation). To better understand Mirai, you can also have a look at its leaked [source code](https://github.com/jgamblin/Mirai-Source-Code).

如果您想亲身体验，请访问GitHub查看代码和使用的恶意软件样本。为了更好地理解Mirai，您还可以查看其泄露的源代码。

## Manual Analysis

In static malware analysis, one of the first things to do is to have a closer look at the identified strings, since they often reveal a lot of context. In this sample, however, we mostly see strings like PMMV, CFOKL, QWRRMPV and others. At first glance, they don’t make much sense. However, if we have a closer look at how they are used in the code, we notice something interesting: They are repeatedly used as function parameters for the function sub_10778. (The corresponding function calls can be found [here](https://github.com/jgamblin/Mirai-Source-Code/blob/master/mirai/bot/scanner.c#L123) in the leaked source code.)

在静态恶意软件分析中，首先要做的事情之一是仔细查看已识别的字符串，因为它们通常会揭示很多上下文信息。然而，在这个样本中，我们主要看到像PMMV、CFOKL、QWRRMPV等字符串。乍一看，它们没有太多意义。但是，如果我们更仔细地观察它们在代码中的使用方式，就会发现有趣的事情：它们被反复用作函数sub_10778的参数。（相应的函数调用可以在泄露出来的源代码中找到。）

```c
sub_10778("PMMV", &data_1616c, 0xa)
sub_10778("PMMV", "TKXZT", 9)
sub_10778("PMMV", "CFOKL", 8)
sub_10778("CFOKL", "CFOKL", 7)
sub_10778("PMMV", &data_16184, 6)
sub_10778("PMMV", "ZOJFKRA", 5)
sub_10778("PMMV", "FGDCWNV", 5)
sub_10778("PMMV", 0x1619c, 5)  {"HWCLVGAJ"}
sub_10778("PMMV", &data_161a8, 5)
sub_10778("PMMV", &data_161b0, 5)
sub_10778("QWRRMPV", "QWRRMPV", 5)
```

Based on this, we can assume that the passed strings are decoded and further processed in the called function. If we inspect the decompiled code of the function, we identify the following snippet that operates on the first function parameter arg1. For the second parameter arg2, we can find a similar snippet.

基于此，我们可以假设传递的字符串已被解码并在调用的函数中进一步处理。如果我们检查该函数的反编译代码，我们会发现以下片段操作第一个函数参数arg1。对于第二个参数arg2，我们可以找到类似的片段。

```c
uint32_t r0_3 = sub_12c90(arg1)
void* r0_5 = sub_14100(r0_3 + 1)
sub_12d0c(r0_5, arg1, r0_3 + 1)
if (r0_3 s> 0) {
    char* r2_3 = nullptr
    do {
        *(r2_3 + r0_5) = *(r2_3 + r0_5) ^ 0x22
        r2_3 = &r2_3[1]
    } while (r0_3 != r2_3)
}
```

The code first performs some function calls using arg1, goes into a loop and increments a counter until the condition r0_3 != r2_3 no longer holds. Within the loop, we notice an XOR operation *(r2_3 + r0_5) ^ 0x22, where *(r2_3 + r0_5) seems to be an array-like memory access that is xored with the constant 0x22. After performing a deeper analysis, we can clean up the code by assigning some reasonable variable and function names.

该代码首先使用arg1执行一些函数调用，然后进入一个循环并递增计数器，直到条件r0_3 != r2_3不再成立。在循环内部，我们注意到一个异或操作*(r2_3 + r0_5) ^ 0x22，其中*(r2_3 + r0_5)似乎是一种类似于数组的内存访问方式，并且与常量0x22进行了异或运算。经过深入分析后，我们可以通过为某些变量和函数命名来清理代码。

```c
uint32_t length = strlen(arg1)
void* ptr = malloc(length + 1)
strcpy(ptr, arg1, length + 1)
if (length s> 0) {
    char* index = nullptr
    do {
        *(index + ptr) = *(index + ptr) ^ 0x22
        index = &index[1]
    } while (length != index)
}
```

Now, we have a better understanding of what the code does: It first calculates the length of the provided string, allocates memory for a new string and copies the encrypted string into the allocated buffer. Afterward, it walks over the copied string and decrypts it bytewise by xoring each byte with 0x22. This is also in line with the [decryption routine](https://github.com/jgamblin/Mirai-Source-Code/blob/master/mirai/bot/scanner.c#L963) of the original source code.

现在，我们更好地理解了代码的作用：它首先计算提供字符串的长度，为新字符串分配内存并将加密后的字符串复制到分配的缓冲区中。然后，它遍历复制的字符串，并通过逐字节与0x22异或来解密它。这也符合原始源代码的解密例程。

In other words, strings are encoded using a bytewise XOR with the constant value 0x22. If we want to decode the string PMMV in Python, we can do this with the following one-liner.

换句话说，字符串使用常量值0x22进行逐字节异或编码。如果我们想在Python中解码字符串PMMV，则可以使用以下一行代码完成。

```python
>>> ''.join([chr(ord(c) ^ 0x22) for c in "PMMV"])
'root'
```

We walk over each byte of the string, get its corresponding ASCII value via ord, xor it with 0x22 and transform it back into a character using chr. In a final step, we join all characters into a single string.

我们遍历字符串的每个字节，通过ord获取其对应的ASCII值，使用xor运算符与0x22进行异或操作，并使用chr将其转换回字符。最后一步是将所有字符连接成一个单独的字符串。

After we manually analyzed how strings can be decrypted, we will now automate this with Binary Ninja.

在我们手动分析了如何解密字符串之后，现在我们将使用Binary Ninja自动化此过程。

## Automated Decryption

To automate the decryption, we first have to find a way to identify all encoded strings. In particular, we have to know where they start and where they end; in other words, we aim to identify all encrypted bytes. In the second step, we can decrypt each byte individually.

要自动解密，我们首先必须找到一种方法来识别所有编码字符串。特别是，我们必须知道它们从哪里开始和结束；换句话说，我们的目标是识别所有加密字节。在第二步中，我们可以逐个解密每个字节。

Beforehand, we noticed that the encoded strings are passed as the first two parameters to the function sub_10778. To obtain the encoded strings, we can exploit this characteristic by searching for all function calls and parse all passed parameters. Using Binary Ninja’s high-level intermediate language (HLIL) API, we can realize this within a few lines of code.

事先，我们注意到编码字符串作为前两个参数传递给函数sub_10778。为了获得编码字符串，我们可以利用这一特征通过搜索所有函数调用并解析所有传递的参数来实现。使用Binary Ninja的高级中间语言（HLIL）API，在几行代码内就可以实现这一点。

```python
# get function instance of target function
target_function = bv.get_function_at(0x10778)
# set of already decrypted bytes
already_decrypted = set()

# 1: walk over all callers
for caller_function in set(target_function.callers):
    
    # 2: walk over high-level IL instructions
    for instruction in caller_function.hlil.instructions:
    
        # 3: if IL instruction is a call
        #    and call goes to target function
        if (instruction.operation == HighLevelILOperation.HLIL_CALL and
            instruction.dest.constant == target_function.start):
                
            # 4: fetch pointer to encrypted strings
            p1 = instruction.params[0]
            p2 = instruction.params[1]
            
            # 5: decrypt strings
            decrypt(p1.value.value, already_decrypted)
            decrypt(p2.value.value, already_decrypted)
```

After fetching the function object of the targeted function sub_10778, we walk over all functions calling sub_10778. For each of these calling functions (referred to as callers), we need to identify the instruction that performs the call to sub_10778. In order to do this, we walk over the caller’s HLIL instructions; for each instruction, we then check if its operation is a call and if the call destination is the targeted function. If so, we access its first two parameters (the pointers to the encoded strings) and pass them to the decryption function. Since some strings—such as `PMMV`—are used as parameters multiple times, we ensure that we only decrypt them once. Therefore, we collect the addresses of all bytes that we already have decrypted in a set called `already_decrypted`.

获取目标函数sub_10778的函数对象后，我们遍历所有调用sub_10778的函数。对于每个调用函数（称为调用者），我们需要确定执行对sub_10778的调用的指令。为此，我们遍历调用者的HLIL指令；对于每条指令，我们检查其操作是否是一个调用，并且如果呼叫目标是所需的功能，则访问它的前两个参数（编码字符串的指针）并将它们传递给解密功能。由于某些字符串（例如PMMV）被多次用作参数，因此我们确保只解密一次。因此，我们将已经解密过得所有字节地址收集到一个名为already_decrypted 的集合中。

Up until now, we identified all parameters that flow into the decryption routine. The only thing left to do is to identify all encrypted bytes and decrypt them. Since each parameter is a pointer to a string, we can consider it as the string’s start address. Similarly, we can determine the string’s end by scanning for terminating null bytes.

到目前为止，我们已经确定了流入解密例程中的所有参数。唯一剩下要做的就是识别所有加密字节并进行解密。由于每个参数都是一个字符串指针，因此可以将其视为该字符串开始地址。类似地，通过扫描终止空字节来确定字符串结束位置.

```python
def decrypt(address, already_decrypted):
    # walk over string bytes until termination
    while True:
        # read a single byte from database
        encrypted_byte = bv.read(address, 1)

        # return if null byte or already decrypted
        if encrypted_byte == b'\x00' or address in already_decrypted:
            return

        # decrypt byte
        decrypted_byte = chr(int(encrypted_byte[0]) ^ 0x22)
        
        # write decrypted byte to database
        bv.write(address, decrypted_byte)

        # add to set of decrypted addresses
        already_decrypted.add(address)

        # increment address
        address += 1
```

Taking the string’s start address as input, we sequentially walk over the string until we reach a byte that terminates the string or that was already decrypted. For each byte, we then transform it into an integer, xor it with 0x22, encode it as a character and write it back to the database. Afterward, we add the current address to the set `already_decrypted` and increment the address.

以字符串的起始地址为输入，我们顺序遍历该字符串，直到找到终止该字符串或已经解密的字节。对于每个字节，我们将其转换为整数，与0x22异或，编码为字符并写回数据库。之后，我们将当前地址添加到已解密集合中，并增加地址。

Finally, we have all parts together: We walk over all function calls of the string decryption function, parse the parameters for each call and decrypt all the strings in Binary Ninja’s database. If we put everything into a Python script and execute it, the decompiled code from above contains all strings in plain text.

最后，我们将所有部分组合在一起：遍历字符串解密函数的所有函数调用，在每次调用中解析参数并解密Binary Ninja数据库中的所有字符串。如果我们把所有东西放入一个Python脚本并执行它，则上面反编译代码包含了所有明文字符串。

```c
sub_10778("root", "xc3511", 0xa)
sub_10778("root", "vizxv", 9)
sub_10778("root", "admin", 8)
sub_10778("admin", "admin", 7)
sub_10778("root", "888888", 6)
sub_10778("root", "xmhdipc", 5)
sub_10778("root", "default", 5)
sub_10778("root", 0x1619c, 5)  {"juantech"}
sub_10778("root", "123456", 5)
sub_10778("root", "54321", 5)
sub_10778("support", "support", 5)
```

As a result, the decompilation reveals much more context information. By googling [some of the strings](), we learn that the parameters are username/password tuples of default login credentials.

因此，反编译揭示了更多的上下文信息。通过搜索一些字符串，我们得知这些参数是默认登录凭据的用户名/密码元组。

## Setting the Scene

Automation allows us to spend less time with tedious and repetitive reverse engineering tasks. In this post, I tried to emphasize the thought process behind automation on the example of decrypting strings in malware. Starting with manual analysis, we first pinpointed interesting behavior: encrypted strings used as function parameters. Then, we put it into context by digging into the function, and learned that the strings are decrypted inside. By noticing a recurring pattern—that the function is called several times with different parameters—we developed an idea of how to automate the decryption. By using Binary Ninja’s decompiler API, we walked over all relevant function calls, parsed the parameters and decrypted the strings. In the end, 20 lines of code sufficed to improve the decompilation and achieve a much better understanding of the malware sample.

自动化使我们能够花更少的时间处理繁琐和重复的逆向工程任务。在本文中，我试图通过解密恶意软件中的字符串来强调自动化背后的思考过程。从手动分析开始，我们首先确定了有趣的行为：加密字符串用作函数参数。然后，我们通过深入挖掘函数将其放入上下文，并学习到这些字符串是在内部解密的。通过注意到一个经常出现的模式——该函数多次使用不同参数进行调用——我们想出了如何自动化解密的想法。通过使用Binary Ninja 的反编译器API，我们遍历了所有相关函数调用、解析了参数并对字符串进行了解密。最终，只需要20行代码就可以改进反编译并更好地理解恶意软件样本。

Even if you are just starting out, I encourage you to get familiar with the API that your tool of choice exposes, and to automate some of the tedious tasks you encounter during your day-to-day reversing. It is not only fun; reverse engineering also becomes so much easier.

即使您刚刚开始接触逆向工程，请尝试熟悉您所选择工具公开API，并自动化一些日常逆向过程中遇到的繁琐任务。这不仅很有趣；而且逆向工程也变得更加容易。

## Contact

For questions, feel free to reach out via Twitter @mr_phrazer, mail tim@blazytko.to or various other channels.

如有问题，请通过Twitter @mr_phrazer、电子邮件tim@blazytko.to或其他渠道随时联系。

> 注： 本文使用 ChatGPT 翻译，如有不当之处，欢迎指正！
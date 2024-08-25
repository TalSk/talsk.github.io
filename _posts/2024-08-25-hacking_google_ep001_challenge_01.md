---
layout: post
title:  "H4CK1NG G00GL3 - EP1C01"
subtitle: "Episode 001 - Challenge 01 - Brute-force Decryption"
date:   2024-08-25 16:05:34 +0300
tags: [CTF, reverse-engineering, research, hacking-google, cryptography]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
---

So I've passed the first episode (and got a token with my name in reward!). I watched the chapter's video (very well produced, by the way), and I expect some reverse engineering efforts. Anyway, let's dig in.

Clicking on the challenge downloads a file with a really long name `cec5317acaa111092eef6da3df8e260dccd69ce8b17aa445a26a7a6771f972301ac3ff20108cf86aa868da1463e486347114e0456ba5b5ca2a3a399f69391e76`.

As should be the norm for unknown files, running the `file` utility on them almost always helps.

```bash
tal@Tal:~$ file cec5317acaa111092eef6da3df8e260dccd69ce8b17aa445a26a7a6771f972301ac3ff20108cf86aa868da1463e486347114e0456ba5b5ca2a3a399f69391e76

cec5317acaa111092eef6da3df8e260dccd69ce8b17aa445a26a7a6771f972301ac3ff20108cf86aa868da1463e486347114e0456ba5b5ca2a3a399f69391e76: Zip archive data, at least v2.0 to extract, compression method=store
```

Alright. Let's open it. Within the zip is another tar-gzip file which I also decompressed (`tar -xvf challenge.tar.gz`) which resulted in two files, `flag` and `wannacry`. Running the `file` utility on them both yielded additional info:

```bash
tal@Tal:~$ file wannacry

wannacry: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=IGPSbKhPf45BQqlR84-9/XWC3eVS4fozNp9uK4nDp/_Styn3U-Z8S6ExnY6QOR/RTzNS5QnFmUHeSBeyHIu, with debug_info, not stripped
```

While the `flag` file wasn't detected as anything meaningful. Cool, so it's time to jump into the binary.

I opened it in IDA 8.3 (which is given as freeware with cloud-based decompiling - recommended!), and told IDA to freely use the debug information that was found, embedded into the file. It should help greatly since I'll have function names and whatnot.

IDA threw me into a `main_main` function. I happened to reverse a compiled Go program in the past, and it's not too much fun - IDA completely fails on understanding the structures of objects like the built-in string, and it messes up the decompiler. Also, even the disassembly can confuse IDA in some cases - the stack cookie check is notorious for making IDA unsuccessfully parse functions.

Either way, at the beginning of the function, there's a call to a `main_impossible`. Without reversing it, I noticed that if it returns a non-zero output, the code calls `println` to stdout. But what does it print? 

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:0000000000509498</span>    <span style="color: #66d9ef;">call</span>    <span style="color: #ae81ff;">main_impossible</span> <span style="color: #75715e;">; Call Procedure</span>
<span style="color: #66d9ef;">.text:0000000000509498</span>    
<span style="color: #66d9ef;">.text:000000000050949D</span>    <span style="color: #66d9ef;">nop</span>     <span style="color: #e6db74;">dword ptr [<span style="color: #a6e22e;">rax</span>]</span> <span style="color: #75715e;">; No Operation</span>
<span style="color: #66d9ef;">.text:00000000005094A0</span>    <span style="color: #66d9ef;">test</span>    <span style="color: #a6e22e;">al</span>, <span style="color: #a6e22e;">al</span>          <span style="color: #75715e;">; Logical Compare</span>
<span style="color: #66d9ef;">.text:00000000005094A2</span>    <span style="color: #66d9ef;">jz</span>      <span style="color: #e6db74;">short</span> <span style="color: #ae81ff;">loc_5094EE</span> <span style="color: #75715e;">; Jump if Zero (ZF=1)</span>
<span style="color: #66d9ef;">.text:00000000005094AA</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rax</span>, <span style="color: #ae81ff;">cs:main_site</span> <span style="color: #75715e;">; val</span>
...
<span style="color: #66d9ef;">.text:00000000005094B8</span>    <span style="color: #66d9ef;">call</span>    <span style="color: #ae81ff;">runtime_convTstring</span> <span style="color: #75715e;">; Call Procedure</span>
...
<span style="color: #66d9ef;">.text:00000000005094E9</span>    <span style="color: #66d9ef;">call</span>    <span style="color: #ae81ff;">fmt_Fprintln</span>    <span style="color: #75715e;">; Call Procedure</span>
</pre>


Looks like a string object named `main_site`, which points to offset `0x53A7A4` and of length 0x4F. The string at that address turned out to be `Keys are here:\nhttps://wannacry-keys-dot-gweb-h4ck1ng-g00gl3.uc.r.appspot.com/\n`.

Going to this URL, I was met with a list of 200 `.pem` files. Clicking on one of them results in a valid PEM-formatted private key, okay...

Back to the binray, after the call to `main_impossible` that prints the aforementioend URL, I noticed that the code accesses some global variables from the .bss section of the executable, like `os_Args`, `flag_CommandLine`, `main_keyFile` and `main_encryptedFile`. 

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:0000000000509534</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rdx</span>, <span style="color: #ae81ff;">cs:main_keyFile</span>
<span style="color: #66d9ef;">.text:000000000050953B</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rbx</span>, [<span style="color: #a6e22e;">rdx</span>+<span style="color: #e34f2b;">8</span>]
<span style="color: #66d9ef;">.text:000000000050953F</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rax</span>, [<span style="color: #a6e22e;">rdx</span>]
<span style="color: #66d9ef;">.text:0000000000509542</span>    <span style="color: #66d9ef;">test</span>    <span style="color: #a6e22e;">rbx</span>, <span style="color: #a6e22e;">rbx</span>        <span style="color: #75715e;">; Logical Compare</span>
<span style="color: #66d9ef;">.text:0000000000509545</span>    <span style="color: #66d9ef;">jz</span>      <span style="color: #ae81ff;">short loc_509555</span> <span style="color: #75715e;">; Jump if Zero (ZF=1)</span>
<span style="color: #66d9ef;">.text:0000000000509547</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rcx</span>, <span style="color: #ae81ff;">cs:main_encryptedFile</span>
<span style="color: #66d9ef;">.text:000000000050954E</span>    <span style="color: #66d9ef;">cmp</span>     <span style="color: #e6db74;">qword ptr [<span style="color: #a6e22e;">rcx</span>+<span style="color: #e34f2b;">8</span>]</span>, <span style="color: #e34f2b;">0</span> <span style="color: #75715e;">; Compare Two Operands</span>
<span style="color: #66d9ef;">.text:0000000000509553</span>    <span style="color: #66d9ef;">jnz</span>     <span style="color: #ae81ff;">short loc_50956C</span> <span style="color: #75715e;">; Jump if Not Zero (ZF=0)</span>
</pre>


I wanted to know where they're initialized and looked at their cross references. Looks like there are 3 init functions `os_init`, `flag_init` and `main_init` that initialize them and are probably called before `main_main`.
I looked at `main_init` specifically, finding that the objects `main_keyFile` and `main_encryptedFile` contain `name`, `usage` and `value` members behind the scenes. 

Looking at the initialization flow, `main_keyFile` is initalized with the name `"key_file"`, usage `"File name of the private key"` and an empty value, while `main_encryptedFile` is initialzied with the name `"encrypted_file"`, usage `"File name to decrypt"` and an empty value too.

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:00000000005096EC</span>    <span style="color: #66d9ef;">lea</span>     <span style="color: #a6e22e;">rbx</span>, <span style="color: #ae81ff;">aEncryptedFile</span> <span style="color: #75715e;">; name="encrypted_file"</span>
<span style="color: #66d9ef;">.text:00000000005096F3</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">ecx</span>, <span style="color: #e34f2b;">14</span>         <span style="color: #75715e;">; name_length=14</span>
<span style="color: #66d9ef;">.text:00000000005096F8</span>    <span style="color: #66d9ef;">xor</span>     <span style="color: #a6e22e;">edi</span>, <span style="color: #a6e22e;">edi</span>        <span style="color: #75715e;">; value=null</span>
<span style="color: #66d9ef;">.text:00000000005096FA</span>    <span style="color: #66d9ef;">xor</span>     <span style="color: #a6e22e;">esi</span>, <span style="color: #a6e22e;">esi</span>        <span style="color: #75715e;">; value_length=0</span>
<span style="color: #66d9ef;">.text:00000000005096FC</span>    <span style="color: #66d9ef;">lea</span>     <span style="color: #a6e22e;">r8</span>, <span style="color: #ae81ff;">aFileNameToDecr</span> <span style="color: #75715e;">; usage="File name to decrypt."</span>
<span style="color: #66d9ef;">.text:0000000000509703</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">r9d</span>, <span style="color: #e34f2b;">21</span>         <span style="color: #75715e;">; usage_length=21</span>
<span style="color: #66d9ef;">.text:0000000000509709</span>    <span style="color: #66d9ef;">call</span>    <span style="color: #ae81ff;">flag__ptr_FlagSet_String</span> <span style="color: #75715e;">; creates object, return in eax </span>
<span style="color: #66d9ef;">.text:0000000000509717</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #ae81ff;">cs:main_encryptedFile</span>, <span style="color: #a6e22e;">rax</span>
</pre>


Alright, now that I know that, back to `main_main` I go. As seen in the code above, I realized that the check on offset 8 of `main_encryptedFile` (and later also at the same offset of `main_keyFile`) verifies that its  value isn't empty. If any of them is, the code calls a function taking from the global variable `flag_Usage`. 

Seeing this it's enough for me to simply go and run the executable - since seems like it's designed for command-line usage.

```bash
tal@Tal:~$ chmod +x wannacry & ./wannacry

Usage of ./wannacry:
  -encrypted_file string
        File name to decrypt.
  -key_file string
        File name of the private key.
```

Ah, very nice, seems like the objects I looked at above are a special kind of objects used to take input from the command line. The value of the objects above are probably the string supplied by the user.

Skimming forwards in the `main_main` function, I noticed that there's a call to `main_readKey` using the `main_keyFile` object's value, and then a `os_ReadFile` call using the `main_encryptedFile` object's value. The output of these calls are saved into local variables `key` and `data` respectively. Shortly after, a call to `main_decrypt` is made with `key` and `data` being two paramteres passed into it.

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:00000000005095FE</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rbx</span>, [<span style="color: #a6e22e;">rsp</span>+<span style="color: #ae81ff;">data</span>] <span style="color: #75715e;">; data</span>                        
<span style="color: #66d9ef;">.text:0000000000509603</span>    <span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rdi</span>, [<span style="color: #a6e22e;">rsp</span>+<span style="color: #ae81ff;">key</span>]  <span style="color: #75715e;">; key</span>
<span style="color: #66d9ef;">.text:0000000000509608</span>    <span style="color: #66d9ef;">call</span>    <span style="color: #ae81ff;">main_decrypt</span>    <span style="color: #75715e;">; Call Procedure</span>
</pre>


Peeking at the function list, a lot of crypto-related functions stand out. Looks like a cryptographic library was compiled into this binary. The functions imported are mostly related to elliptic-curve cryptography, which `main_decrypt` probably utilizes.

At this point it's pretty clear the flag was encrypted using one version or another of ECDSA. I have those 200 keys given at the website. Well, it's not too many - I thought and decided to simply try them all.

```py
import requests

DOMAIN = 'https://wannacry-keys-dot-gweb-h4ck1ng-g00gl3.uc.r.appspot.com'
KEYS = ['01087458-4d66-4677-af0d-da2024cc2111.pem', '02bdbf0d-48c6-4fb5-b5d2-71be3f4f071f.pem', # ...
]

for key in KEYS:
    res = requests.get(DOMAIN + "/" + key)
    assert(res.status_code == 200)
    with open("keys/" + key, "wb") as f:
        f.write(res.content)
```

Grabbing a drink and a minute later, I had all the keys saved to the `keys` folder. Time to loop over all of them and run the `wannacry` binary on each, searching for an output that looks like a flag.

```bash
for key in keys/*; do 
	output=$(./wannacry -encrypted_file=flag -key_file="$key"); 
	if echo "$output" | grep -q "google"; then 
		echo "$output" > "decrypted_flag"; 
		break
	fi; 
done
```

And there's a `decrypted_flag` in the directory :)
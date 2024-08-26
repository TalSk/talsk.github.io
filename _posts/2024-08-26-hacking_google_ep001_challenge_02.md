---
layout: post
title:  "H4CK1NG G00GL3 - EP1C02"
subtitle: "Episode 001 - Challenge 02 - 10 Seconds to Killswitch"
date:   2024-08-26 15:05:34 +0300
tags: [CTF, RE, research, hacking-google, cryptography]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
---

Downloading the next challenge, I got a file with a long name again `a5eecbd1dc5ad07e38b062cdabfb3e63da36847e727fa666903f9dc1094e24160d68d0ed95378102ae20c7bca84f3638825c4433833b08886f918b7fa90fec56`.

The `file` utility claims that it's a `zip`. Unzipping and I have an executable named `wannacry`. Very similar to the previous challenge so far.

Opened it in IDA. This time, it's a much smaller binary - about 16 functions with debug info again leaking the functions' names.

I decided to run `strings` on the executable returns. It printed out a LOT of valid-looking strings, about a thousand valid single-word strings. Huh. Among them I spotted `https://wannacry-killswitch-dot-gweb-h4ck1ng-g00gl3.uc.r.appspot.com//` which is a slightly different appspot subdomain than the one I got in the previous challenge. 

Well, checking out `main` subroutine, it's basically empty and does nothing. I checked the entry point of the executable (`_start`) which seems to call `main`. When I ran the executable, indeed nothing happened. Odd.

Anyway, there's not many other functions to look through, so let's pick one. `print`, judging by the previous challenge, should be a good direction. 

It has no xrefs, and simply calls the function `correct_code`, prints the string in the `DOMAIN` global variable and then the return value of the `correct_code`. `DOMAIN`, unsurpriginly, points to the appspot domain I found.

Going into `correct_code`, I started to look at it from the end to simply see what it returns:

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:000000000002F7FD</span>	<span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">eax</span>, [<span style="color: #a6e22e;">rbp</span>+<span style="color: #ae81ff;">var_8</span>]
<span style="color: #66d9ef;">.text:000000000002F800</span>	<span style="color: #66d9ef;">cdqe</span>                    <span style="color: #75715e;">; EAX -> RAX (with sign)</span>
<span style="color: #66d9ef;">.text:000000000002F802</span>	<span style="color: #66d9ef;">lea</span>     <span style="color: #a6e22e;">rdx</span>, <span style="color: #e6db74;">ds:0[<span style="color: #a6e22e;">rax</span>*<span style="color: #e34f2b;">8</span>]</span> <span style="color: #75715e;">; Load Effective Address</span>
<span style="color: #66d9ef;">.text:000000000002F80A</span>	<span style="color: #66d9ef;">lea</span>     <span style="color: #a6e22e;">rax</span>, <span style="color: #ae81ff;">wordlist</span>   <span style="color: #75715e;">; Load Effective Address</span>
<span style="color: #66d9ef;">.text:000000000002F811</span>	<span style="color: #66d9ef;">mov</span>     <span style="color: #a6e22e;">rax</span>, [<span style="color: #a6e22e;">rdx</span>+<span style="color: #a6e22e;">rax</span>]
<span style="color: #66d9ef;">.text:000000000002F815</span>	<span style="color: #66d9ef;">leave</span>                   <span style="color: #75715e;">; High Level Procedure Exit</span>
<span style="color: #66d9ef;">.text:000000000002F816</span>	<span style="color: #66d9ef;">retn</span>                    <span style="color: #75715e;">; Return Near from Procedure</span>
</pre>


Seems like it uses whatever stored in `var_8` as an index to an array of quadwords pointers named `wordlist`. The `wordlist` seems to be an array of pointers to strings, the array seems to contain thousands of alphabetically ordered, different strings. Looks like it's the same ones `strings` found at the beginning!

So, I guess that one of the strings in the `wordlist` is the correct one. But what can I do with it? Let's try to append it to the domain - by testing a GET request to `https://wannacry-killswitch-dot-gweb-h4ck1ng-g00gl3.uc.r.appspot.com//zoom`, it responds with `Our princess is in another castle.`. Testing out a random string (not in the wordlist) appended to the domain returns the same result. Unfortunate, but I still guess that one of the words in `wordlist` is the right one.

So what chooses the index of the word from `wordlist`? The `var_8` local varible is initialized as 0 and changes during some loops that are being done before `correct_code` returns. Actually, it seems that exactly 5 iterations are taking place, judging by the `cmp` before the return block and the increment of `var_C` taking place right before looping back.

<pre style="background-color: #272822; color: #ffffff; padding: 10px; font-family: 'Courier New', monospace; border-radius: 5px;">
<span style="color: #66d9ef;">.text:000000000002F7F7</span>	<span style="color: #66d9ef;">cmp</span>     [<span style="color: #a6e22e;">rbp</span>+<span style="color: #ae81ff;">var_C</span>], <span style="color: #e34f2b;">4</span> <span style="color: #75715e;">; Compare Two Operands</span>
<span style="color: #66d9ef;">.text:000000000002F7FB</span>	<span style="color: #66d9ef;">jle</span>     <span style="color: #ae81ff;">short loc_2F7B3</span> <span style="color: #75715e;">; Jump if Less or Equal (ZF=1 | SF!=OF)</span>
</pre>

So what happens in the loop? First, the return value of the call to `totp` (which rings to me as the shorthand for one-time password) is taken and some manipulation is done over it. It's a bit of an odd piece of code - I wrote a short Python code that mimicks its behavior:

```py
# i - the loop index variable, 
# totp - the output of the totp() call, 
# index - the calculated index to take from the wordlist.
while i <= 4:
	# al is 16 bit, zero-extending it to eax just means we're taking these exact bits
	totp_copy = totp & 0xFFFF
	# seems like the code decides to take just 6 bits at the end.
	totp_copy = totp_copy & 0x3F
	# count number of bits turned on. Can be a value between 0 and 6.
	number_of_ones = count_ones(totp_copy) 
	if number_of_ones > 0:
		number_of_ones -= 1
	# deleting the bottom 6 bits from the totp variable
	totp = totp >> 6 

	index = 6 * index
	index += number_of_ones

	i += 1
```

This code uses the bits in the return value of `totp` to calculate a 5-digit base-6 number. 

In each iteration, it counts the number of turned on bits in the current 6-bit window of the totp, and treat them as the next digit in the number. Since the number of bits turned on in a 6-bit integer can be between 0 and 6, there's an extra possiblity (6 is an invalid value in base-6) - so the code subtracts 1 from the number of turned on bits, which in turn makes no turned on bits and exactly one turned on both map to 0.

Thus the maximum number the code can output is 55555 in base-6 which equals 7775 in base-10. A quick look over the size of `wordlist` discovers it's exactly 7775 words long. Not a coincidence here, huh?

So, given that `totp` returns a truly random value, I'd have to check all 7775 words.

At this point, I was in a bit of a hurry and didn't want to wait through the thousands of requests to the server. I decided to take a peek at the `totp` function in hopes of finding something.

Well, on first sight it looks just like I guessed - it calls `time_now` to get the time, then hashes the output using `sha1`, and finally calls a function named `extract31` with the hash and the last 4 bits of the hash as parameters.

This latter function has a pretty distinctive name which I vaguely remembered. Searching online and the first result is [HMAC-based one-time password](https://en.wikipedia.org/wiki/HMAC-based_one-time_password) which is very similar to the method taken here - hashing a secret value (in this case, the time) and then extracting a code from it, using the last 4 bits as an index for an extraction of exactly 31 bits from the hash (hence the name).

Abstractly looking, without going into the implementation of the `time_now`, `sha1` and `extract31` methods, I find it should be pretty hard to "break" this one-time code generation algorithm, as even a "somewhat" correct implementation of this function would likely generate every possible code with some probability (even if not entirely uniform, given that the secret is not truly random). 

However, given that I know nothing regarding the time the code I'm meaning to find was generated at, that makes breaking it even less likely.

Well, I guess it's time to iterate over 7000 words? But wait a second, could the entire exercise (and the reference to a "killswitch") mean that the webserver runs the same `totp` code in real-time and so the correct word changes every time the code changes? 

It could be that iterating through all words will still solve the challenge, but I might get a bit unlucky with the race condition and miss the right password between making requests.

So, I decided to just try to run the `print` function and check the word is returnes and the current time. 

To do that, I changed the extra uneeded code inside `main` to call `print` instead (simply "Patch program" in IDA then "Assemble" and writing `call print` does the trick, while not forgetting to patch the bytes afterwards with `nop`s).

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep01-C02-main.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Don't want to crash the program, right?</i></figcaption>
</figure>

I applied the patch and ran the binary - 

```bash
tal@Tal:~$ ./wannacry_patched

https://wannacry-killswitch-dot-gweb-h4ck1ng-g00gl3.uc.r.appspot.com//deflator
```

And I got a big `Turn it off!` icon. Nice, no need for bruteforce here :)

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep01-C02-turn-it-off.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>It's so bright in here!</i></figcaption>
</figure>
---
layout: post
title:  "H4CK1NG G00GL3 - EP2C01"
subtitle: "Episode 002 - Challenge 01 - Gaming Images"
date:   2024-09-12 12:05:34 +0300
tags: [CTF, research, hacking-google, steganography, cryptography]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep02-C01-challenge.png"
---

After beating Episode 1, I've been pretty pumped to see what comes next. The difficulty curve of this CTF so far is pretty unexpected. Some challenges I feel are straightforward, whereas others are quite difficult or simply have pretty obscure solutions.

Anyway, the next episode's video is all about threat analysis, following the attacker's steps in the network. Let's see what challenges are thrown my way.

The challenge file is, yet again, a zip folder, with a hashed name. Inside is a single image. Opening it, and the logo of the H4CK1NG G00GL3 CTF stares back at me.

It looks identifical to the one on the website, except that other one is embedded into the background of the desktop-like website.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep02-C01-challenge.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The real challenge image. Notice anything?</i></figcaption>
</figure>

This is a very small amount of content for a challenge, which makes me immediately jump to a conclusion - it must be steganography!

A very long word, [Steganography](https://en.wikipedia.org/wiki/Steganography) simply means hiding information within another object.

Very commonly, the target object is an image. Digitally, the most well known tactic is using the least significant bits of information within the pixels themselves to encode secret messages.

My guess is that the challenge explores this idea. Now, to easily discover the embedded message, the best case scenario is I would be able to get the original image, before the data has been added to it. Then, assuming the data is directly embedded into the image pixels, "substracting" both images' pixels from each other should reveal which pixels were changed and how.

I want back to the website and started inspecting elements. The HTML reveals that the page is built using `app-window` elements. I'm not familiar with these elements, but I'd guess they're some custom implementation allowing for this cool-looking embedded desktop of the website.

I thought it might prove difficult to extract the image background, but I spotted there's an `app-background` element with a `style:background-image` pointing to `assets/website.png`.

Browsing to `https://h4ck1ng.google/assets/website.png`, and luckily it seems to be just the part where it says "H4CK1NG G00GL3", just like in the challenge image. Downloading the images, I verified and their size matches exactly! They're both 1326 columns by 462 rows.

Writing a short Python code, using the `pillow` library, I loaded the images' pixels and printed out all the locations on which the pixels differ.

```py
from PIL import Image

# Load images
challenge_image = Image.open("ep02_c1_challenge.png")
challenge_image_pixels = challenge_image.load()
real_image = Image.open("ep02_c1_real.png")
real_image_pixel = real_image.load()

width, height = challenge_image.size
num_different_pixels = 0

# Compare pixels and print differences
for x in range(width):
    for y in range(height):
        if challenge_image_pixels[x, y] != real_image_pixel[x, y]:
            print(f"Pixel at ({x}, {y}) changed - from {real_image_pixel[x,y]} to {challenge_image_pixels[x,y]}")
            num_different_pixels += 1

print(num_different_pixels)
```

The code printed out that in total, 2,240 out of the 612,612 pixels were changed from the original image. That's promising!

Judging by the locations of the different pixels, it seems almost the entire first row (`y=0`) of the challenge image is different, and almost all the second row (`y=1`), up to pixel 1,161.

When I say almost all, that's because sometimes the different pixel location seem to "jump" to the next pixel. Odd.

I inspected a few of the pixel differences:
```
Pixel at (717, 0) changed - from (0, 0, 0, 0) to (1, 0, 0, 1) 
Pixel at (797, 1) changed - from (0, 0, 0, 0) to (1, 0, 0, 0) 
Pixel at (1322, 0) changed - from (0, 0, 0, 0) to (0, 1, 1, 0)
```

In those instances and all the cases I looked through, the original pixel was all 0s - so a black pixel, which is completely transparent (controlled by the fourth value of the tuple).

The changed pixel, however, is a very slightly modified version of the original. From these examples, I understood that the hidden data is embedded in the least significant bit of every byte of the RGBA values of the pixel (which correspond to the tuple quartets above). 

Changing the RGB values by 1 barely has a noticable effect on the pixel. Furthermore, the transparency value (as known as the "alpha" value) changing by 1, barely affects the transparency, as it ranges from 0% to 100% when the alpha byte reads 255, 1/255 is not even 1% change in transparency, and so the pixel really looks just like the original. (Indeed, zooming in on the first row of the challenge image, there's nothing out of the ordinary).

Following these conclusions, I decided to simply collect the pixel values of the changed bits, parse them as a bitstring and convert to bytes.

```py
from PIL import Image

# Load images
challenge_image = Image.open("ep02_c1_challenge.png")
challenge_image_pixels = challenge_image.load()
real_image = Image.open("ep02_c1_real_image.png")
real_image_pixel = real_image.load()

width, height = challenge_image.size
binary_array = []

# Compare pixels and print differences
for x in range(width):
    for y in range(height):
        if challenge_image_pixels[x, y] != real_image_pixel[x, y]:
            r1, g1, b1, a1 = challenge_image_pixels[x, y]
            binary_array.append(str(r1) + str(g1) + str(b1) + str(a1))

binary_string = ''.join(binary_array)
print(binary_string)
byte_array = bytearray(int(binary_string[i:i+8], 2) for i in range(0, len(binary_string), 8))
print(byte_array)
```

And...I got an exception?

`ValueError: invalid literal for int() with base 2: '16171716'`

Huh. The printed `binary_string` revealed an issue - in the middle of it there appeared an unexpected set of digits - `...001001101617171611101717163301101617173300101617163200111617173300101617163200111617171610011000...`

Okay, maybe my assumption that the original pixel are always blank was wrong. Adding a simple print only if the original pixel is not blank resulted in:

```
Pixel at (466, 1) changed - from (16, 17, 17, 16) to (16, 16, 16, 16)
Pixel at (467, 1) changed - from (17, 17, 16, 33) to (16, 16, 16, 32)
Pixel at (468, 1) changed - from (16, 17, 17, 33) to (16, 16, 16, 32)
Pixel at (469, 1) changed - from (16, 17, 16, 32) to (16, 16, 16, 32)
Pixel at (470, 1) changed - from (16, 17, 17, 33) to (16, 16, 16, 32)
Pixel at (471, 1) changed - from (16, 17, 16, 32) to (16, 16, 16, 32)
Pixel at (472, 1) changed - from (16, 17, 17, 16) to (16, 16, 16, 16)
```

Well, the second row must have bumped into part of the letters in the image. It's still clear the hidden message is hidden in the least significant bit - so the fix is pretty easy: when appending new bits, just take the least significant one by a binary AND with 1: `binary_array.append(str(r1 & 1) + str(g1 & 1) + str(b1 & 1) + str(a1 & 1))`.

I ran the code again, there was no exception this time, but the result is a complete garbage...

Oh - realization came - I'm iterating over the rows first before the columns. Since the different pixels were almost continously along the first row and up to about three-fourths of the second row, I should collect the bits in this order. The fix is simple yet again: change the order of the loops to first iterate over the height and then the width.

The script printed another output. 

```
'\xd9B\xd2\xd2\xd2\xd2\xd4$Tt\x94\xe2CERTIFICATE-----\xa4\xd4\x94\x94E\xa7\xa444\x16\xb3\x844d&
\xf4\xb5\x86\xe5\x86F\xe4\xe7V&\xc3\x86\xf6\xc4\xa6GcCAxJ9wksMA4t57\x14u4\x96#4E\x14T$%\x15T\x14
\xd4\x84\x17\x8aCzAJBgNVBAYTAkNIMQ8wDQYDVQQIDAZadXJu\x93&w\x84\xf7\xa4\x13T&t\xe5d$\x16\xf4\xd4
\xd6\xd6\x83dHBzOi8v\xa6\x14E&\xa6\x17\xa4gU\xa7\x93V\xe6##\x96\xe6$uWf3#\x976F\xd5Wd\xe5D\xe6
\xa6E\x84\x97\x85d\x86\xc6e\x16\xe6\xc6d\xd4t\x93\x15\x135g\x94\xd5\x85%\xa4\xd5$\xd7tU\x15\x94
JVQQDDAv\xe6##\x96\xe6$uWU\x93#\x97D\xd4#E\x84ED\x97\x94\xd4F\xb7\xa4\xd4DSD\xe5DWt\xe5f\xf5\x84
ED\xd7\x94\xd4F\xb7\x94\xe7\xa4SD\xe5DWt\xe5f\xf7zcDELMAkGA1UEBhMCQ6w\x84G\xa4\x14\xe4&t\xe5d$
\x16t\xd4&\xc71cmljaDE7MDkGA1UECgwyaHR64\x84\xd3jLy9oNGNrMW5nLmdvb2dsZS9zb2x2ZS81M2N1cjFUeV9Ce
V8wYjVDdXIxdFkxEzAR\xa4&t\xe5d$\x14\xd4\xd46\xd6Gf#&G5\xa53V\xa6##wggEiMA4t57\x14u4\x96#4E\x14T$
\x15\x15T\x14\x13D\x94$Gt\x17vvtT\xb4\x16\xf4\x94*AQDCX25BoQBBndrOiS6L11/RwWf6FNS+fUct7CLq9yMxU+x
J+yUde\xa6\x13r\xb7G&\xb7gvS\xa4\x95\x85vGT\xe4\x96"\xf5U7gD\xf6#\x84\x93\x85\x83\x84\x82\xf4\xd4
\x85d\xd47\x97BQisFMxHnZmv2D/QVRySIJt\xd6F\x16\x83\x87f\x12\xb4\xc4\xc3V\xfa7Dv4\xc4Cs7\x96\xe4uW
s\x87%s\x85e\x15W&\xc4tcV4\xa5%6vC5\xa5f$EV\xa5#34tCEF\xa6D\x946\x87\xa72\xf5t\xd5\xa4u57c/lk\xa7
54\xc4\xd6C&T5\x96&Gv\xf3Wz7KaYa7ta6#6vc55q4E/uJ3TUN26GkYOi/c7U\xa7&u\x17R\xb6\x85\x85#jonn2HhkBN
rloUlZaI5kJ2v3QRHt2UxnAhS7YVu\x13e\xa53F\x83\x84\xc5\x16cf\xd7f\xe5\xa2\xf5\xa7\x83s\x157\x95\xa6
\xd6\xb6\xbaAuvhSjU8bCeIyu43\x83%&$V\x93fd\x16t\xd4$\x14\x14WtE\x15\x94\xa4\xb6\xf5\xa4\x96\x87f4
\xe4\x15\x14Td%\x14\x14FvtT$\x14&\xa3\x15IHB\xa64\xb4\xa6w\x84U\x86\xf3d\x15B\xb3\x84\xf4\xd5\x95
tfC&\xd7GF\x84\xd3$\x876\x96\xf6Wd\xe7f\xd7sAQjjlU&e\x934S\x94Dct\x83C\x95\x86\x16v\xe4\xf4\xe35
\x94\xdadDvN4IwmHSRKIemdEyc/D2+Dr/Ky5FSU6NymUiUGUGV+aDGXIFV/NOaq6#\x94\x156$&\x8a78TLN2+/Val933tH
WQuqmws3v4XknYTcU"\xb6v\x87\x17#\x97#\x94\x13dVW7DF\xd7\x13\x14\x84$\xf7V\x17\xa5t\xa6ZDBUBHenbSW
6EV\xe4e\x95\xa63\x87\xa7T54\xc5\xa7D\x94\xa7f\xc4\x17\'\x94\xa7&\xd64euG&\x96EV\xd7E\x86\xa4\xd3T
\xc7\x96\x835LFAFVH6wl\xa7\xa3sVEvisfE9aw4zfotBsV6zvgOL1yu\x975\x83#KJ6zIJycRBkWgmOzQxKCZ5fxfKCFT
\xa3\x86\xd7#\x93\x94\xd7V\xa79EBzT\x13\xda-----END$4U%D\x94d\x944\x15DR\xd2\xd2\xd2\xd2\xda'
```

At first glance, it looked like garbage again. But wait, it clearly says `CERTIFICATE-----` up there. And also `-----END` close to the actual end of the string. Both of these strings are pretty revealing - this is clearly a format of a certificate, most likely X.509, which is a [very widely used public key certificate format](https://en.wikipedia.org/wiki/X.509).

Assuming that this is what I'm looking at here, I noticed another interesting piece - sometimes the junk-looking array of hexadecimal bytes changes to a valid base-64 string of a continous printable characters, but then it changes back...

I feel like I'm missing something obvious here. The beginning of the certificate should also start with five `-` characters. The repeating `\xd2` bytes striked me as odd. What is the hexadecimal value of `-`? 

`0x2d`, answered Python. Hmm...So those repeating bytes seem to be sorta..flipped, every nibble (the name for 4 bits of a byte), it seems. Hang on, what's the hexadecimal value of the letter `B` that appears just before them? `0x42`. Okay, so the first nibble was stolen by this `B`, the whole thing seems to be shifted by a nibble. 

My eyes were drawn to just after the `CERTIFICATE-----`. This piece looks correct, but what comes after? Usually, an X.509 certificate has a line-feed ("enter") just after it, and then again every 64 characters.

But wait, I see that immedaitely after `CERTIFICATE----`, there's a `\xa4` character, and "0xA" is indeed the hexadecimal value of a line-feed. So...what happened to the leading 0 of this byte?

And then (finally) *it hit me* - **there are absolutely no nibbles within the entire string which are 0**. 

*Another hit* - a nibble is made of 4 bits which is exactly a pixel's contibution of bits - thus a nibble entirely made of 0s happens when the challenge image contains a completely blank pixel. Since most of the pixels in first two rows of the original image are blank, my code didn't detect these as "different" and skipped them. This also explains the skipped pixels in the continous region I noticed earlier. 

Ohhhh. I'm dumb.

Anyway, let's complete this - I know approximately that the hidden data is embedded continously from the beginning up to the 1st row, 1161st column. Let's simply collect all bits up to that point:

```py
for y in range(height):
    for x in range(width):
        r1, g1, b1, a1 = challenge_image_pixels[x, y]
        if y == 0 or (y == 1 and x <= 1161):
            binary_array.append(str(r1 & 1) + str(g1 & 1) + str(b1 & 1) + str(a1 & 1))

binary_string = ''.join(binary_array)
byte_array = bytearray(int(binary_string[i:i+8], 2) for i in range(0, len(binary_string), 8))
print(byte_array)
```

And I got the certificate!

```
-----BEGIN CERTIFICATE-----
MIIDZzCCAk8CFBoKXnXdnNubl8olJdv40AxJ9wksMA0GCSqGSIb3DQEBBQUAMHAx
CzAJBgNVBAYTAkNIMQ8wDQYDVQQIDAZadXJpY2gxOzA5BgNVBAoMMmh0dHBzOi8v
aDRjazFuZy5nb29nbGUvc29sdmUvNTNjdXIxVHlfQnlfMGI1Q3VyMXRZMRMwEQYD
VQQDDApnb29nbGUuY29tMB4XDTIyMDkzMDE4NTEwNVoXDTMyMDkyNzE4NTEwNVow
cDELMAkGA1UEBhMCQ0gxDzANBgNVBAgMBlp1cmljaDE7MDkGA1UECgwyaHR0cHM6
Ly9oNGNrMW5nLmdvb2dsZS9zb2x2ZS81M2N1cjFUeV9CeV8wYjVDdXIxdFkxEzAR
BgNVBAMMCmdvb2dsZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQDCX25BoQBBndrOiS6L11/RwWf6FNS+fUct7CLq9yMxU+xJ+yPVFZa7+trkvwe0
IXWduNIb/USvtOb8I8X8H/MHVMCypBQisFMxHnZmv2D/QVRySIJpMdah8va+LL5o
7Dv0LD73ynGUw8rW8VQUrlGF5cJRSgd3ZVbDUjR33GD4TjdIChzs/WMZGSP7c/lk
sSLMd2eCYbdwo5pz7KaYa7ta0b3gf055q4E/uJ00TUN26GkYOi/c7PZrgQu+hXR6
onn2HhkBNrloUlZaI5kJ2v3QRHt2UxnAhS7YVpQ6ZS4h8LQf6mvnZ/Zx71SyZmkk
AuvhSjU8bCeIypSC82RbEi6fAgMBAAEwDQYJKoZIhvcNAQEFBQADggEBABj1PIHB
cKJgxEXo6AT+8OMYWFd2mtthM2HsioevNvmpsAQjjlPRfY3E9DF7H49XagnON3YM
dDvN4IwmHSRKIemdEyc/D2+Dr/Ky5FSU6NymUiUGUGV+aDGXIFV/NOaq0b9ASbBh
78TLN2+/Val933tHWQpPqmpw30v4XknYPF5R+ghqr9r9A0dVPstDmq1HBOuazWJe
DBUBHenbSW6EPnFYZc8zuCSLZtIJvlAryJrmcFWTridUmtXjM5Lyh05LFAFVH6wl
z0sVEvisfE9aw4zfotBsV6zvgOL1ypYsX20KJ6zIJycRBkWgmOzQxKCZ5fxfKCFT
8mr99Mujp9EBzPA=
-----END CERTIFICATE-----
```

But what's next? The certificate embeds few interesting details about the public key it contains - like who signed it. Possibly some interesting data is hidden within. 

I used a [public website that decodes X.509 certificates](https://certificatedecoder.dev/), and found that indeed, the name of the Organization that signed the certificate is very interesting, and maybe  rhymes with, hmmm, "brag". :)

See you in the next challenge!
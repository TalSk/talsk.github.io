---
title: "H4CK1NG G00GL3 - EP5C01"
date: 2024-11-20 09:05:34 +0300
categories: ["CTF"]
tags: ["CTF", "RE", "research", "hacking-google", "tamagotchi", "binary-analysis", "bmp"]
image: "/assets/images/Hacking-Google/Hacking-Google-Cover.png"
---

It's episode 5, baby! This is the last one on this CTF, and what a road it has been so far!

But, there are still (at least) 3 challenges left.

First, as I learned the hard way previously, you have to watch this episode's video. This time, we're covering a very cool team in Google - Project Zero! This team is in charge of making the internet a safer place, by allowing some of the most talented vulnerability researchers in the world to catch zero days and fix them before bad actors can.

Nothing stood out in the video. There was a cute little Chrome-is-offline game with the Project Zero team catching bugs and interesting interviews with the team members.

The caption before the episode link did give a small hint:

> I hope no one is typing any sensitive URLs in here

Indeed for a short frame at 5:32, we can see someone browsing to the following URL: `https://h4ck1ng.google/solve/XfYOR3L9GMM`, which looks like a flag, but doesn't do anything when unlocked (like happened before with these links). I guess it was only relevant during the actual CTF.

Anyway, onwards to the challenge. On this one, I got a simple binary file. Tried running the `binwalk` and `file` utilities on it to identify what it contains, which yielded nothing useful.

What's the hint for this challenge?

> Hint: I wonder if those toys from the 90's are still alive.

Hmm...One of the Project Zero researchers had a thing with Tamagotchis, which this hint pretty directly alludes to.

Well, maybe the binary is a Tamagotchi ROM? I suppose it's esoteric enough so it won't be easily identified by the above tools.

Let's try. I found some open-source tools which load ROMs, one called [tamatool](https://github.com/jcrona/tamatool) in particular looked promising. However, it didn't work.

The challenge comes with a short flavor text:

> Piece together the images to get a clearer picture.

Well, maybe the file contains *images* of a Tamagotchi screen? Perhaps, but I couldn't find a file format that starts with the initial bytes of the binary (`30 1F`), nor a common format used for Tamagotchi images.

Alright, what the hell - let's simply treat the file as a BMP (Bitmap file format - the most simple form of image format). I had to add the simple BMP header, which required guessing the width, which I arbitrarily put and got this image:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-initial.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Initial BMP image result</i></figcaption>
</figure>

It doesn't really *look* like anything, but you can clearly see some pattern emerge on the diagonals! This can be a sign of some file format structure. But, they said *"piece together the images"*, plural. So maybe it's a set of images with high similarity to each other?

Also, at this point, I realize that if that's images of Tamagotchis, back then the screen was probably only monochrome. So, I changed the header as needed and guessed some reasonable power-of-2 width (32-bit).

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-tamagotchi.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A monochrome simple BMP of the binary</i></figcaption>
</figure>

Okay! That's definitely...*something*. I cut and pasted manually where it seems one image ends and the next begins, but it didn't really add up - seems like the images are broken and not cannot be properly aligned. 

This is probably a sign of a wrong ratio of width and height. Also, it could be that each image begins with some extra bytes as a header.

Let's do some maths: the total number of bytes in the binary - `0xBB0` (2992 in decimal). What are the factors of this? `2^4,11,17`. Doesn't look too promising as 32 isn't there and could be the cause of the misalignment issue.

I manually tested different widths (based on the factors) but it did not yield any better results.

While playing around trying to stitch together the images, I wondered how could I discover exactly where to cut. I realized that if I can find repeating sequences, it's just a matter of looking at the difference between their start indices., which would tell me the size of each image. 

I already realized that the repeating sequences are **large**, so instead of finding them manually, I coded something to find them out automatically:

```py
import numpy as np
from collections import defaultdict

file_path = 'challenge.bin'
with open(file_path, 'rb') as file:
    data = file.read()

# Convert the binary data to a byte-wise array
byte_array = np.frombuffer(data, dtype=np.uint8)

def find_largest_repeating_byte_pattern(byte_array):
    pattern_count = defaultdict(int)
    
    # Try different sequence lengths, starting from a sensible large size, and going down
    for pattern_len in range(len(byte_array) // 20, 1, -1):
        print(pattern_len)
        for i in range(len(byte_array) - pattern_len + 1):
            pattern = tuple(byte_array[i:i + pattern_len])
            pattern_count[pattern] += 1
            
            if pattern_count[pattern] > 4:
                return pattern

largest_pattern = find_largest_repeating_byte_pattern(byte_array)

# Convert the largest pattern to a hex
largest_pattern_hex = ' '.join(map(lambda x: format(x, '02x'), largest_pattern))
print(f"Largest repeating pattern (in hex): {largest_pattern_hex}")
print(f"Pattern length: {len(largest_pattern)} bytes")
```

Since I don't know what's the right size for the sequence, and that they might differ just slightly, the code iterates over the possible pattern length until it finds at least 4 such patterns (judging by the image above, there were at least 4 images in the sequence with this weird robot clearly visible).

My first guess (of the starting pattern length) was almost spot on - the code starts looking for patterns of length 149 bytes and upon reaching 140, it finds a sequence repeating at least 4 times.

The exact sequence it finds repeats 8 times. So maybe we have 8 images? 

The first sequence starts at offset `0xFA`, so assuming that the images have the same format and start at the beginning of the file, I subtracted the offsets between two consecutive sequences to find the image size which was 0x176, or 374 in decimal.

2992 / 374 is exactly 8! (`374` having factors of `2`, `11` and `17`, with `2^3` remaining)

Knowing the correct size, I wrote a new piece of code that splits the images, parses them, and stitches them together.

```py
import numpy as np
from PIL import Image

file_path = 'challenge.bin'
with open(file_path, 'rb') as file:
    data = file.read()

image_size = 374
guessed_width = 32
# Split the data into images based on the correct image size
images = [data[image_size*i:image_size*i+image_size] for i in range(8)]

# Store images in a list for later concatenation
image_list = []
for i, image in enumerate(images):
    height = len(image) * 8 // guessed_width  # Times 8 to adjust for the number of pixels

    # Load the current image into a bit-array as monochrome (black and white)
    pixels = np.unpackbits(np.frombuffer(image, dtype=np.uint8))
    # The multiplication should exactly match the image side, but let's truncate before reshaping the array
    pixels = pixels[:guessed_width * height].reshape((height, guessed_width))
    
    # Convert to an image
    img = Image.fromarray((pixels * 255).astype(np.uint8))
    image_list.append(img)

# Prepare the concatenated image
total_width = sum(img.width for img in image_list)
max_height = max(img.height for img in image_list)
concatenated_image = Image.new('L', (total_width, max_height))

# Paste each image next to each other horizontally
current_x = 0
for img in image_list:
    concatenated_image.paste(img, (current_x, 0))
    current_x += img.width

concatenated_image.save(r'tamagotchi_concatenated_image_' + str(guessed_width) + '.bmp')
```

Which resulted in...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-stitch.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The first iteration of the stitched image</i></figcaption>
</figure>

Wow! I'm definitely on to something. Hang on, does it say "Goog" up there? Could be the start of the flag, maybe?

Excitement aside, things are still definitely wrong. Since I didn't have any smart ideas, I decided to simply try guessing different widths, taking multiples of 32.

```py
import numpy as np
from PIL import Image

file_path = 'challenge.bin'
with open(file_path, 'rb') as file:
    data = file.read()

image_size = 374
# Split the data into images based on the correct image size
images = [data[image_size*i:image_size*i+image_size] for i in range(8)]

for guessed_width in [32*i for i in range(1, 9)]:
    # Store images in a list for later concatenation
    image_list = []
    for i, image in enumerate(images):
        height = len(image) * 8 // guessed_width  # Times 8 to adjust for the number of pixels

        # Load the current image into a bit-array as monochrome (black and white)
        pixels = np.unpackbits(np.frombuffer(image, dtype=np.uint8))
        # The multiplication should exactly match the image side, but let's truncate before reshaping the array
        pixels = pixels[:guessed_width * height].reshape((height, guessed_width))
        
        # Convert to an image
        img = Image.fromarray((pixels * 255).astype(np.uint8))
        image_list.append(img)

    # Prepare the concatenated image
    total_width = sum(img.width for img in image_list)
    max_height = max(img.height for img in image_list)
    concatenated_image = Image.new('L', (total_width, max_height))

    # Paste each image next to each other horizontally
    current_x = 0
    for img in image_list:
        concatenated_image.paste(img, (current_x, 0))
        current_x += img.width

    concatenated_image.save(r'tamagotchi_concatenated_image_' + str(guessed_width) + '.bmp')
```

I went over the images, 32 is what I had before, and 64 looks a bit better but still messaged up, but on looking at 96...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-done-almost.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>An almost-perfect creation</i></figcaption>
</figure>

Bingo! 96 is it! There's the flag on the right side too.

I tried extracting the flag and noticed something odd, there were too many slashes in the path part of it.

So while I probably could deduce it, I was not content - something's still broken. Let's fix it up!

But how? Upon closer inspection, I noticed there is an extra space between what seems to be adjacent pixels (take a closer look at the robots). That's pretty odd.

Could it be the images are not exactly in single-bit monochrome, but instead 2 bits per pixel? So we should have 2 shades of gray between white and black. 

Let's fix the code (the correct width should be `96/2=48`):

```py
import numpy as np
from PIL import Image

file_path = 'challenge.bin'
with open(file_path, 'rb') as file:
    data = file.read()

image_size = 374
# Split the data into images based on the correct image size
images = [data[image_size*i:image_size*i+image_size] for i in range(8)]

for guessed_width in [96//2]:
    # Store images in a list for later concatenation
    image_list = []
    for i, image in enumerate(images):
        height = len(image) * 4 // guessed_width  # Times 4 to adjust for the number of pixels

        # Unpack the binary data, but now interpret each group of 2 bits as a grayscale pixel
        bits = np.unpackbits(np.frombuffer(image, dtype=np.uint8))
        # Reshape the bits into 2-bit pairs, then interpret those pairs as grayscale values (0-3)
        pixels = bits.reshape(-1, 2)[:, 0] * 2 + bits.reshape(-1, 2)[:, 1]  
        pixels = pixels[:guessed_width * height].reshape((height, guessed_width))
        
        # Convert to an image. Multiply by 85 to scale from 0-3 to 0-255
        img = Image.fromarray((pixels * 85).astype(np.uint8))
        image_list.append(img)

    # Prepare the concatenated image
    total_width = sum(img.width for img in image_list)
    max_height = max(img.height for img in image_list)
    concatenated_image = Image.new('L', (total_width, max_height))

    # Paste each image next to each other horizontally
    current_x = 0
    for img in image_list:
        concatenated_image.paste(img, (current_x, 0))
        current_x += img.width

    concatenated_image.save(r'tamagotchi_concatenated_image_' + str(guessed_width) + '.bmp')
```

Resulting in this pretty image:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto; width:200%;" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-done-almost-3.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>An almost-almost-perfect creation</i></figcaption>
</figure>

But something is still isn't right - why is the line between the lovely Tamagotchis isn't straight all the way? 

I inspected a single image closely and noticed that the line deviated down for exactly 8 pixels at what seems to be the beginning of the stitch. Also, there are a bunch of white pixels at the top left of each image. Maybe there's an 8-pixel header?

At that point, I wasted about 30 minutes of my time trying to get rid of the header unsuccessfully, to the point I wanted to rip my hair out.

My forgetfulness is going to be my demise - I forgot that every pixel is 2 bits! So if I want to remove what looks to be a 8 pixel header in the image, I actually need to remove 16 bits!

Fixing this annoying issue (by simply adding a `image = image[2:]` at the beginning of the loop), and...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto; width:200%;" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C1-done.bmp" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A (finally) perfect creation!</i></figcaption>
</figure>

Perfection :)

(As it turns out, I - the reason for the repeating slashes is that the flag URL is slightly repeating. My guess is this image sequence is some sort of Tamagotchi animation strip, where written text like the URL glides along the screen so it makes sense to leave some characters in every frame to get the animation looking smooth).
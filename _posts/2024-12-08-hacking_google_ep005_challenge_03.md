---
layout: post
title:  "H4CK1NG G00GL3 - EP5C03"
subtitle: "Episode 005 - Challenge 03 - The Final Challenge"
date:   2024-12-09 10:05:34 +0300
tags: [CTF, RE, research, hacking-google, morse]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep05-C3-hacking-google.png"
---

I'm on the final challenge of the CTF! And what a wild ride it has been. 

But, before celebration begins, there's still one puzzle left to solve.

In this challenge, I got...Nothing? No link, no files to download, just a flavor text and a hint:

> Look back at all the episodes and piece together a secret message.

> Hint: This code isn't data but it could have prevented Aurora. Introductions are important. 

Okay. The first thought was that I need to somehow combine things from previous challenges. Maybe the flags? But it's so uncommon to see such a thing in CTFs...

They do specifically mention "episodes" though. Could it be a reference to their respective videos? Something hidden in them?

I opened the [video of Episode 0](https://www.youtube.com/watch?v=przDcQe6n5o). But what am I supposed to look for? I looked at the description and the comments, but there's nothing interesting going on there.

Also, I previously watched carefully the episode videos to find hidden flags, and didn't notice anything out of the ordinary. 

What now? The hint mentions introductions. Let's watch the different Googlers being introduced. 

The first introduction happens at `3:11` on the first video. The name of the interviewee appears slowly out of made up characherts which I thought at first could be some kind of cipher or a key to a cipher, but watching the characters across two introductions there were too many inconsistencies.

While poking around in the video around the introductions parts I noticed something: right after the recurring episode intro section, before the big screen flashes with "HACKING GOOGLE", you can faintly hear a bunch of fast occuring beeps. 

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep05-C3-hacking-google.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Do you hear that?</i></figcaption>
</figure>

...Is that morse? I slowed down the video drastically (x0.25) and listened. It's definitely *sounds* like a morse code - only two types of beeps, long and short, coming in bursts of three to five.

I quickly went over to the [video of Episode 1](https://www.youtube.com/watch?v=N7N4EC20-cM) - it had a different set of beeps, which probably means the theory that these bunch of beeps is a relevant morse code!

Time to collect all the data across the episodes' videos (dot represents a short beep, and dash a long beep):

- [Episode 0](https://www.youtube.com/watch?v=przDcQe6n5o) (2:52): --. .-.-.- -.-.
- [Episode 1](https://www.youtube.com/watch?v=N7N4EC20-cM) (2:18): --- -..-. ....
- [Episode 2](https://www.youtube.com/watch?v=QZ0cpBocl3c) (1:31): --- -..-. ....
- [Episode 3](https://www.youtube.com/watch?v=TusQWn2TQxQ) (2:14): ... .- ..-. . -
- [Episode 4](https://www.youtube.com/watch?v=IoXiXlCNoXg) (3:21): -.-- -..-. ....
- [Episode 5](https://www.youtube.com/watch?v=My_13FXODdU) (2:23): -.. ...- - .-- .-

Something's immediately suspicious - the code for episodes 1 and 2 is the same. 

Well, let's try converting to ASCII. This results in the following string:

1. G.C
2. O/H
3. O/H
4. SAFET
5. Y/H
5. DVTWA

Or, combined, `G.CO/HO/HSAFETY/HDVTWA`

The beginning, `g.co` is immediately recognizable to me - it's Google's internal link shortening domain. But something is definitely broken in the repeating `O/H` strings.

I tried to solve this using Google Dorking - searching for `site:g.co inurl:safety` results in a few URLs like `g.co/safety/cyber` and `g.co/safety/passkey`. But my hope that I'll find something that usually comes before the `SAFETY/` part didn't come true. If anything else, it seemed that the `SAFETY/` directory appears right after `g.co`...Odd.


After a further while of searching and finding nothing, I decided that the correct version would be `G.CO/H???SAFETY/HDVTWA` and started writing something that bruteforces the missing 3 letters. 

But I realized that's a process I'm not supposed to do, and so this part of the puzzle must be an error.

So before diving into bruteforcing, I made a quick search through the CTF's Discord, and found that indeed, this was an error on the designer's part, and the correct episode 2 code should have been `ACKTO` (meaning my assumption there are only 3 characters missing was wrong, anyway).

On visiting the correct URL, the browser is redirected to the final flag of the challenge, unlocking the final trophy and the CTF is over!

<hr>

With the final challenge done, I feel like some final words are in order:

This CTF sat (amongst many others) gathering dust in my `TODO` bookmark folder for a *long* time. 

Somewhen back in August of this year, I made a decision to write more for my blog.

The main goal was avoiding having the unachievable mental load of posting "perfect" content, which I felt really held me back from posting regularly.

But posting imperfect blogs about big projects I worked on is not something I want to do.

The brilliant solution? Start posting about a CTF! Inherently, it consists of small, short challenges, which are technical but do not rely too much on precise explanations.

This pushed me into picking the "H4CK1NG G00GL3" CTF, and in hindsight and with all honesty - I enjoyed every second of it.

The CTF itself was amazing. It explores vastly different topics in cybersecurity - forensics, signal anaylsis, web vulnerabilities, reversing, cryptography and stegnography were all featured in one or more challenges.

But beyond that, the challenges were each on a subject interesting enough to write about, while short enough to fit in a post taking a few minutes to read.

And that's what really mattered: in a span of a few months, I posted **15** times on the blog, each post accumulating more views than any of those that came before. I feel much more much confident in writing and releasing content as soon as it's done, without needing several verification iterations. 

So, to finish this off - thanks to the creators of the H4CK1NG G00GL3 CTF, the blog writers I relied on for many of the challenges, and finally to you, the readers who made it thus far. Thank you, and see you in the next post!
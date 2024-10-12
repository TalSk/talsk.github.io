---
layout: post
title:  "H4CK1NG G00GL3 - EP4C02"
subtitle: "Episode 004 - Challenge 02 - Custom Crypto Carelessness"
date:   2024-10-12 11:05:34 +0300
tags: [CTF, research, hacking-google, cryptography]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep04-C2-flag.png"
---

So as described in the previous challenge, I actually solved this one beforehand, and it's pretty short and sweet.

Clicking on the challenge link, it downloads a compressed folder containing an implmentation of the server running at `vrp-website-web.h4ck.ctfcompetition.com`, however it doesn't include the `/import` and `/export` endpoints.

It does contain the rest of the pages, however, as well as the login functionality. The hint of this challenge also directs to this functionality as it pushes me to `Try logging in as tin`.

Before checking out the source code, now that I have a valid username, I went to the login page and played with it a little - testing out SQLi tricks, trying to bruteforce common passwords, and using the password reset functionality on `tin`.

When this didn't work, I decided to finally check out the source code. 

The website is a NodeJS app, served from `app.js`. At the beginning of it, I saw `setUserFromCookies` is used as a middleware to `/` which caught my attention. Maybe I can forge a valid cookie?

```js
// middlewares.js

// ...

async function setUserFromCookies (req, res, next) {
  const { token } = req.cookies
  if (!token) return next()

  try {
    const { username } = jwt.verify(token, secret)
    if (!username) throw new Error('invalid user')
    
    const user = await getUserByUsername(username)
    if (!user) throw new Error('invalid user')
    
    req.user = user
  } catch (err) {
    // It is fine to send us invalid tokens... No user object will be injected in this case.
  }

  return next()
}

// ...
```

Hm, looks like the code is aware of what I was trying to do. In any case, the cookie is a JWT. I looked at how the secret is generated at `constants.js`:

```js
// the secret is used to sign cookies
const secret = crypto.randomBytes(16).toString('hex')
```

Welp, that is random and I won't be able to guess this. There are also no other instances of using `secret` in the entire code, so no chance of leakage.

I went back to the main file and looked at the `/login` endpoint. It uses `getUserByUsernameAndPassword` to implement the login functionality.

```js
// services/users.js

// ...

async function getUserByUsernameAndPassword (username, password) {
  const user = await getUserByUsername(username)
  if (!user) return undefined

  const hashedPassword = crypto.createHash('sha1').update(password).digest('base64')
  if (!safeEqual(user.hashedPassword, hashedPassword)) return undefined
  
  return user
}

// ...
```

So the server takes password parameter I send, hashes it using SHA1 and then base64 encodes it. The usage of `safeEqual` instead of a simple equality is pretty suspicious. Let's take a look at it:

```js
// util/safe-equal.js

// ...

function safeEqual(a, b) {
    let match = true;

    if (a.length !== b.length) {
        match = false;
    }

    const l = a.length;
    for (let i = 0; i < l; i++) {
        match &&= a.indexOf(i) === b.indexOf(i);
    }

    return match;
}

// ...
```

Well, something indeed smells fishy in here: besides checking that the lengths of the two strings are equal, the function iterates over the first string using the variable `i` to hold the current index. Within, the variable `match` is set based on result of `a.indexOf(i) === b.indexOf(i);`. 

Now, I expected to see equality between the characters at position `i` of `a` and `b`, but function `indexOf` does something completely different - it returns the first index at which the string contains the value `i`. 

Throughout the loop, `i` will hold only numeric values, so the function doesn't check equality at all, but instead just that the first instance of every integer from `0` to the length of the base64-encoded hashed password (which is `28`) is the same in both strings.

Well, that should be exploitable! At the beginning of `services/users.js`, I can see the hashed passwords of both `tin` (the user I'm supposed to break into) and `don`, which is a second user that also has an `isAdmin: true` flag.

```js
const users = [
  { username: 'don', hashedPassword: 'i4tUa+RTGgv+jRtyUWBXbP1i/mg=', isAdmin: true },
  { username: 'tin', hashedPassword: 'XtBEoWAkAF/UKax1SDdIHeCJbtE=' }
]
```

For `tin`, there's just a single `1` at index `15`, and for `don`, there's `4` at index `1` and `1` at index `22`.

While looking at the file, I noticed the `resetPasswordByUsername` function:

```js
async function resetPasswordByUsername (username) {
  const user = await getUserByUsername(username)
  if (!user) return false

  // we don't allow admins to reset passwords
  if (!!user.isAdmin) return false

  const password = crypto.randomBytes(8).toString('hex')
  const hashedPassword = crypto.createHash('sha1').update(password).digest('base64')
  
  user.hashedPassword = hashedPassword
  return true
}
```

Looks like the reset functionality only works for `tin` (not being an admin). It generates a new random password, hashes it, and overrides the old hash. 

Since I reset its password, I shouldn't be able to log into `tin`. I wonder if this ever resets to the original...

So, I should try to log into `don`, instad. I need to write some code that finds a valid password based on the hash. Would it be possible, though? Let's go through some short theory.

First, the goal: find a string such that the only numbers in its base64-encoded-SHA1-hash are `4` and `1`. Moreover, their first appearance in the base64-encoded string is at indices `1` and `22` respectively.

If I assume that SHA1 of a random string is uniformly distributed across all possible 40-byte strings, then when the bas64 encoding converts each consecutive 6 bits in the hash to some symbol out of the valid 64, it must also be uniformly distributed. 

What symbols are included in base64? The letters `a-z` and their capitals `A-Z`, the numbers `0-9`, and two unique symbols, usually `+` and `/`

So for each uniformly distributed symbol, there's a high chance it's not a number - `(64-10)/64` which is approximately 85%. 

I want this to happen for all indices besides `1` and `22` (so `26` times out of the `28`-character long string), while these two specific indices happen to be exactly a single option (the number `4` for index `1` and the number `1` for index `22`). 

This happens with probably `(54/64)**26 * (1/64)**2`, which is approximately `3/1000000`. 

While this is *not a very high probably*, it still means that if I take a random string and check if it happens to work, I have a good chance to a hit about every million tries. 

Randomizing a string, calculating SHA1 and base-64 encoding it one million times should take just about a second for my computer using Python, so that's totally feasible!

(Note: the theory I presented above bounds the probably of finding a good string from below. This is because I ignored cases where the indices after `1` contain the number `4` and the indices after `22` contain the number `1` which still make the string work. It complicates the calculations so I decided to ignore it. However, my final code catches this cases well)

Anyway, enough theory - let's write the script:

```py
import hashlib
import base64
import random
import string

def generate_random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def check_sha1_conditions():
    while True:
        random_string = generate_random_string()
        sha1_hash = hashlib.sha1(random_string.encode()).digest()
        sha1_base64 = base64.b64encode(sha1_hash).decode()

        if sha1_base64.find('4') == 1 and sha1_base64.find('1') == 22 and all(d not in sha1_base64 for d in '02356789'):
            print(f"Password: {random_string}, SHA1 Base64: {sha1_base64}")
            break

check_sha1_conditions()

```

The main check simply uses `find` on the string, which is exactly the analog of `indexOf` from Javascript. So, I'm verifying that the first indices of `1` and `4` in the base64-encoded string are as expected, and that the other numbers do not appear in the encoded string.

I ran the script and it finished almost immediately, printing `Password: XdWd3TuSPU, SHA1 Base64: I4VXCXsZyiocAr+WxyXG+b1uelo=`

Let's try the password! I input the username `don` and the password from above, the website successfully logged me in and presented the flag at the top!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep04-C2-flag.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A warm welcome</i></figcaption>
</figure>
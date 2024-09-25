---
layout: post
title:  "H4CK1NG G00GL3 - EP3C01"
subtitle: "Episode 003 - Challenge 01 - Feelin' Right At Home"
date:   2024-09-25 15:06:34 +0300
tags: [CTF, RE, research, hacking-google, rfc6749, oauth2]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep03-C1-flow.png"
---

Welcome to Episode 3!

The first challenge has a `socat` command again, to a different domain - `multivision.h4ck.ctfcompetition.com`.

This time, the challenge hint says:

> Find the key, and put RFC 6749 to use. 

So I don't know *many* RFC numbers, but this one I could identify even if I was woken up in the middle of the night - this is OAuth 2.0! As CTF challenges go, this is very surprising. Feels like playing on home turf.

I ran the `socat` command. The server replied with:

```
== proof-of-work: disabled ==
Password:
```

I tried some random passwords, all resulted in the server replying with `failed authentication :(` and closing the connection.

Hmm. When starting this CTF I was thought that since it happened 2 years ago, some of the challenges might be broken. Could that be the case here? The hint mentioned I have to find a key though, and this is indeed some custom implemenation of a login process...What did I miss?

I looked around and didn't find anything promising. At one point I decided to watch the intro video to episode 3, which I kind of forgot to in my rush to continue.

However when I went to the video link the in the `Intro` tab, I noticed a line that says: `Blink and you'll miss it (9:29). Blink and you'll miss it again (15:09).`. Huh, is this unique to episode 3?

I went over to previous episodes. The first two don't mention anything related to the video in their intros, but episdoe 2 has a message in similar vein - `Listen between 7:15 and 7:45.`

Out of curiousity, I opened episode 2's intro video and listened as requested. There wasn't really anything out of the ordinary, in the above timeframe - it shows an email and later some Twitter conversation, but they seem to be referencing real instances of the North Korean attempt to social engineer Google's security researchers.

That's odd. I'm not sure that they would hide important info in the videos, but I tried looking at Episode 3's video according to the hint.

At `9:29` a black window flashses on the screen (on cue with the interviewee) and shows another `socat` command, now pointing at `34.79.13.26` instead of a domain name. Trying to access it yields the same authentication process I bumped into. I ran `nslookup` on the domain to see if it points to this IP address, but I got a different one. 

This new IP could be another challenge, or it could be that the load balancer was doing its job and giving me a different IP address based on my location in the world.

At `15:09`, you see someone typing on a keyboard and a swiss knife next to it. On it, in big white letters `WhoPutMyPasswordH3r3`. Could it be the password I need? 

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C1-pass.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A very secure password in a very secure place</i></figcaption>
</figure>

I tried logging in with it and, yes - it worked! I managed to log in using both the domain and the IP address so I guess they're pointing to the same challenge. Also, on login, the shell prints out a flag that seem to do nothing when I submit it.

```
== proof-of-work: disabled ==
Password:
WhoPutMyPasswordH3r3
*** Congratulations! ***
*** https://h4ck1ng.google/solve/1_w0nd3r_wh47_53cr3t5_l13_h3r3 ***
developer@googlequanta.com:/home/developer
```

Odd. Anyway, I have a shell session. Let's see what files are available:

```
developer@googlequanta.com:/home/developer$ ls -la
total 40
drwxr-xr-x 3 developer developer 4096 Oct  2  2022 .
drwxr-xr-x 3 nobody    nogroup   4096 Oct  2  2022 ..
-rw-r--r-- 1 nobody    nogroup    171 Oct  2  2022 .bash_history
-rw-r--r-- 1 developer developer  220 Feb 25  2020 .bash_logout
-rw-r--r-- 1 developer developer 3803 Oct  2  2022 .bashrc
drwxrwxr-x 3 developer developer 4096 Oct  2  2022 .config
-rw-r--r-- 1 developer developer  807 Feb 25  2020 .profile
-rwxrwxrwx 1 nobody    nogroup    812 Oct  2  2022 backup.py
-rwxrwxrwx 1 nobody    nogroup    282 Oct  2  2022 login.sh
-rwxrwxrwx 1 nobody    nogroup    336 Oct  2  2022 todo.txt
```

`login.sh` is a very short bash script doing exactly what I saw so far - validating the password on login, printing the flag and then providing shell access.

`todo.txt` seems like a bunch of hints regarding the challenge, I'll explore those later.

```
Today
[x] Added backup-tool@project-multivision.iam.gserviceaccount.com with viewer-access to super sensitive design doc
[x] Tried activating service account with gcloud, but didn't give me a documents.readonly scope
[x] Cleaned up service account key from disk before signing off

Tomorrow
[] Finish writing Google Drive backup script
```

`backup.py` contains a bit of interesting Python code - it tries to use the [`documents.get` Google Docs API](https://developers.google.com/docs/api/reference/rest/v1/documents/get) and retrive a specific Google Docs file using its identifier. The code is missing the `get_token` function.

```py
"""
[WIP]
Regularly backup sensitive Google Drive files to disk
"""

import json
import requests
from time import sleep

doc_id = "1Z7CQDJhCj1G5ehvM3zB3FyxsCfdvierd1fs0UBlzFFM"

def get_file(token, file_id):
    resp = requests.get(
        f'https://docs.googleapis.com/v1/documents/{file_id}',
        headers={'Authorization': f'Bearer {token}'},
    )
    file_content = ""
    if resp.status_code != 200:
        print(f"Yikes!\n{resp.text}")
    else:
        file_content = json.loads(resp.text)['body']
    return file_content

def get_token():
    # TODO: I know it'll work with a 'documents.readonly' scope...
    # ...just need to get the access token
    pass

# Backup file every hour
while True:
    with open('backup.txt', 'a') as f:
        f.write(get_file(get_token(), doc_id))
    sleep(3600)
```

Right, I think I have everything I need - the flag is probably in this "sensitive" Google Docs file. Using the hints from both the Python and the `todo.txt` file, I had the following insights

1. There is a Google service account named `backup-tool@project-multivision.iam.gserviceaccount.com`.
2. The developer has given the service account viewer access rights to the target file.
3. The API to access the file accepts OAuth access tokens granted with one scope out of several options. The developer hints at asking for `documents.readonly` specifically.
4. The developer had created a key for the service account, saved it locally and used `gcloud` to try and get an access key themselves, then deleted the key.

Well, now I verified this is *really* my home turf! Let me share some knowledge I'm planning to use:

To use a Google service account, you need credentials for it. These usually come as a json file containing some metadata about the service account along with its private key.

With a credential, I can do several things, but the main thing is to [access Google APIs using an OAuth access token](https://developers.google.com/identity/protocols/oauth2/service-account#httprest_1). Receiving one in exchange for a credential is a two-step process:

First, use the service account private key to sign a [JWT (JSON Web Token)](https://jwt.io/introduction), containing the scopes you want for the current session. By signing the JWT, I basically prove to Google I'm the rightful holder of the service account permissions (and hence why the key is an extremely powerful secret).

Second, exchange the signed JWT with a temporary access token. This is done using a modified "Client Credentials" grant type (at least this is how I view it. At its core, the "Client Credentials" flow happens when no user is involved - the client directly speaks to the authorization server, which is exactly the case here). Following IETF's RFC, Google define new grant type for their value as `urn:ietf:params:oauth:grant-type:jwt-bearer`.

Once the process completes, the server replies with an access token, which can be used in the Authorization header (after a `Bearer: ` prefix), granting access to anything the service account is authorized to (bounded by the requested scopes).

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C1-flow.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The flow, as provided by Google</i></figcaption>
</figure>

But this whole explanation started with "Once I have a credential", which I don't. Well, that's when the hint about the developer using the service account key with `gcloud` comes in!

The command line utility `gcloud` eases integration with Google Cloud Platform (GCP) APIs. Interestingly, it allows authenticating once using service account credentials, whereas after you can safely delete the local credentials, as the utility saves a copy to its application data directory. 

While this adds some obscurity which might lead to security issues, it is very common for these kind of tools. `gcloud` in particular allows you to manage all authenticated seesions using `gcloud auth` and specifically `gcloud auth revoke` to delete those that are not required anymore.

Assuming that the lovely developer didn't do so, the file resides somewhere on the system. With a bit of luck, the shell session I have has access to it. 

A quick Google search reveals that, on Linux, `gcloud` stores local app data in a `.config` directory at the home directory. And, in fact, I did see one when I executed `ls` previously!

Searching through it quickly for `.json` files reveals something interesting:

```bash
developer@googlequanta.com:/home/developer$ find .config/ | grep ".json"
.config/gcloud/legacy_credentials/backup-tool@project-multivision.iam.gserviceaccount.com/adc.json
```

(Later I found out that today, service account keys are saved in a local SQLite database instead, but looks like the challenge made it easier for me using an old version so the key is saved as `.json` at the `legacy_credentials` path)

Just to verify, however, let's see the file's contents:

```json
{
  "client_email": "backup-tool@project-multivision.iam.gserviceaccount.com",
  "client_id": "105494657484877589161",
  "private_key": "-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----\n",
  "private_key_id": "722d66d6da8d6d5356d73d04d9366a76c7ada494",
  "token_uri": "https://oauth2.googleapis.com/token",
  "type": "service_account"
```

Bingo! The file contains a private key to the mentioned service account email!

Now all that's left is to go through the OAuth 2 flow and access the file.

I copied the Python script locally and started filling the missing token retrieval functionality. 

Now, for learning OAuth 2 flows, I highly (highly!) recommend constructing and sending requests by hand. This is the only good way to really understand some of the more confusing points about OAuth.

But, once you're familiar (and not actively trying to find exploits), just use one of the many libraries that implement these flows for you.

For the special service account flow I need, Google has some handy libraries, which I used in my script.

I also added a few functions to extract the actual text from the returned documents, as simply writing the result to file won't work - the returned document is a complicated dictionary containing all sort of data about how the document file looks like. 

Here's the final result:

```py
from google.oauth2 import service_account
import google.auth.transport.requests

import json
import requests
from time import sleep

doc_id = "1Z7CQDJhCj1G5ehvM3zB3FyxsCfdvierd1fs0UBlzFFM"

def extract_text_from_element(element):
    text_run = element.get('textRun')
    if text_run:
        return text_run.get('content', '')
    return ''

def extract_text_from_paragraph(paragraph):
    elements = paragraph.get('elements', [])
    paragraph_text = ''.join([extract_text_from_element(element) for element in elements])
    return paragraph_text

def extract_text_from_body(body):
    text = ''
    for content in body.get('content', []):
        paragraph = content.get('paragraph')
        if paragraph:
            text += extract_text_from_paragraph(paragraph)
    return text

def get_file(token, file_id):
    resp = requests.get(
        f'https://docs.googleapis.com/v1/documents/{file_id}',
        headers={'Authorization': f'Bearer {token}'},
    )
    if resp.status_code != 200:
        print(f"Yikes!\n{resp.text}")
        return None

    document = json.loads(resp.text)
    body = document.get('body', {})
    file_content = extract_text_from_body(body)
    
    return file_content

def get_token():
    # Path to your service account key file
    KEY_FILE_PATH = "creds.json"

    # OAuth 2.0 scope
    SCOPES = ["https://www.googleapis.com/auth/documents.readonly"]

    # Create a credentials object from the service account key
    credentials = service_account.Credentials.from_service_account_file(KEY_FILE_PATH, scopes=SCOPES)

    # Request an OAuth 2.0 token
    auth_request = google.auth.transport.requests.Request()
    credentials.refresh(auth_request)

    # Print the access token
    print(f"OAuth 2.0 Token: {credentials.token}")
    return credentials.token

with open('backup.txt', 'a') as f:
    f.write(get_file(get_token(), doc_id))
```

And the script writes out a file containing some very secretive (and hilarious) features that the Google Glass 2.0 is planned to come with (does having a flag in the middle of your face count?)

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C1-glasses_2.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Top secret plans of the Google Glass 2.0</i></figcaption>
</figure>
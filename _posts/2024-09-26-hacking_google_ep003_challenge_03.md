---
layout: post
title:  "H4CK1NG G00GL3 - EP3C03"
subtitle: "Episode 003 - Challenge 03 - Android Corgis"
date:   2024-10-03 10:05:34 +0300
tags: [CTF, research, hacking-google, reverse-engineering, android, jadx, qrcode]
readtime: true
cover-img: ["/assets/images/Hacking-Google/Hacking-Google-Cover.png"]
thumbnail-img: "/assets/images/Hacking-Google/Hacking-Google-Thumbnail.png"
share-img: "/assets/images/Hacking-Google/Hacking-Google-Ep03-C3-corgi.png"
---

Aaaand we're back to zipped challenges. This time, it's an image and an apk file.

The image is a...QR code?

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C3-qr.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Pretty QR Code</i></figcaption>
</figure>

It's one of the cooler-looking ones - QR codes are rubost enough that even a large amount of noise won't affect their usability. Anyway, I scanned it with my phone and landed on this website:

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C3-corgi.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Surprising Corgi Pixel-art</i></figcaption>
</figure>

A corgi!

Very cute webpage indeed. Is there anything on it? Searching for links and inspecting the source I found nothing interesting. However, the URL is also interesting, I guess, since it was embedded in the QR:

`https://corgis-web.h4ck.ctfcompetition.com/aHR0cHM6Ly9jb3JnaXMtd2ViLmg0Y2suY3RmY29tcGV0aXRpb24uY29tL2NvcmdpP0RPQ0lEPWZsYWcmX21hYz1kZWQwOWZmMTUyOGYyOTgwMGIxZTczM2U2MjA4ZWEzNjI2NjZiOWVlYjVmNDBjMjY0ZmM1ZmIxOWRhYTM2OTM5`

The URL's path has a base-64 in it. Huh, let's decode it:
```js
>> atob("aHR0cHM6Ly9jb3JnaXMtd2ViLmg0Y2suY3RmY29tcGV0aXRpb24uY29tL2NvcmdpP0RPQ0lEPWZsYWcmX21hYz1kZWQwOWZmMTUyOGYyOTgwMGIxZTczM2U2MjA4ZWEzNjI2NjZiOWVlYjVmNDBjMjY0ZmM1ZmIxOWRhYTM2OTM5")
// https://corgis-web.h4ck.ctfcompetition.com/corgi?DOCID=flag&_mac=ded09ff1528f29800b1e733e6208ea362666b9eeb5f40c264fc5fb19daa36939
```

It's...another URL? It points to the same domain as the original, but to a `/corgi` path and with some paramters. The first (`DOCID`) is `flag` which is obviously interesting, and `_mac` which looks like some hash.

Browsing directly to this second URL, I get an unauthorized error.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Hacking-Google/Hacking-Google-Ep03-C3-unauthorized.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A Stop Sign, HTTP Mode</i></figcaption>
</figure>

With this direction at a dead end, I went back to the apk file. An "apk" file type actually embeds a whole Android app - it contains everything that the Android system needs in order to run a specific app. So it's enough to have the file in order to install its app on any Android system.

Just recently I happened to wipe the dust off my Android skills by coming back to the [time I built a Pokemon scanner for Pokemon go](https://talsk.github.io/2024/04/06/Hacking-Pokemon-Go.html), but I'm not too eager to run apps on my phone, and whipping up an emulator without a setup is cumbersome.

Luckily, the common case with Android apps in challenges (compared to "real" apps), is that they're quite short, usually unobfuscated, and sometime contain debug information. This makes them especially easy to reverse engineer only statically.

So I loaded up my favorite Android decompiler - [jadx](https://github.com/skylot/jadx) and opened the apk file.

Decompiled Android apps can be a bit confusing to navigate: the Java classes contained in the apk are split into directories based on their namespace. Since many libraries are included in the compiled version of the app, the directory tree is huge. However, one must include the app's source code and it should have a distinct namespace. It's `google.h4ck1ng.secretcorgis` this time around.

However, if you ever happen to have a case where it's not as clear, a good starting point is the `AndroidManifest.xml` file in the special `Resources` directory. It contains metadata the system needs to know regarding how to handle the app - the permissions it needs, what intents it listens to, startup parameters, cache, files, and more.

If the app runs in the foreground, it also declares the class that should be loaded as the main activity to display to the user. In this case,

```xml
<activity android:theme="@style/Theme.SecretCorgis" android:name="google.h4ck1ng.secretcorgis.MainActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>

```

And we have a direct reference to the class that contains the main activity - `google.h4ck1ng.secretcorgis.MainActivity`. 

At that point I browsed to the `google.h4ck1ng.secretcorgis` directory and started to look around at the classes. Mainly trying to understand what the app is doing and what should be the interesting areas to look at.

Activities in are usually not too interesting, as they mainly deal with setting up the UI and responding to user events. The bulk of interesting logic usually takes place behind the scenes in another class. This is also the case here.

The classes I found to contain real code handle reading QR codes or making HTTP requests. 

I'm guessing right now that the app lets you scan a QR code (like the one that was provided to me), and provide you with the Corgi "embedded" in it. I wasn't sure whether the website I landed on (the direct link in the QR code) is the Corgi itself, or it's something to do with the link encoded within the base64.

Anyway, I decided to start at the `NetworkKt` class. The name itself isn't too interesting, but it has some header names which caught my eye, as well as a very interesting function - `makeSecretRequest`.

```java
/* NetworkKt class */
public final class NetworkKt {
    private static final String DOC_ID_HEADER = "X-Document-ID";
    private static final String HMAC_SIG_HEADER = "X-Auth-MAC";
    private static final String NONCE_HEADER = "X-Request-Nonce";
    private static final String SUBSCRIBER_HEADER = "X-User-Subscribed";
    private static final String TIMESTAMP_HEADER = "X-Timestamp";

    public static final Object makeSecretRequest(CorgiRequest corgiRequest, Continuation<? super String> continuation) {
        Log.d(TAG, Intrinsics.stringPlus("Making request for ", corgiRequest));
        OkHttpClient okHttpClient = new OkHttpClient();
        Request.Builder url = new Request.Builder().url(corgiRequest.getCorgiServer());
        url.addHeader(DOC_ID_HEADER, corgiRequest.getCorgiId());
        url.addHeader(NONCE_HEADER, corgiRequest.getNonce());
        url.addHeader(TIMESTAMP_HEADER, corgiRequest.getTimestamp());
        url.addHeader(HMAC_SIG_HEADER, corgiRequest.getSignature());
        if (corgiRequest.isSubscriber()) {
            url.addHeader(SUBSCRIBER_HEADER, "true");
        }
        return BuildersKt.withContext(Dispatchers.getIO(), new NetworkKt$makeSecretRequest$2(okHttpClient, url.build(), null), continuation);
    }
```

The function receives a `CorgiRequest` object as a parameter, and prepares an HTTP request that will be set to the return value of `corgiRequest.getCorgiServer()` with the `"X-Document-ID", "X-Auth-MAC", "X-Request-Nonce", "X-User-Subscribed", "X-Timestamp"` headers taking values using member functions of the `CorgiRequest` object.

The function returns a `NetworkKt$makeSecretRequest$2` instance with the HTTP object. I wanted to see what happens when the request is actually sent, and found that ends up calling `NetworkKt.makeRequest`, which simply returns the body of the server's response.

Okay. So what are all these details taken from `CorgiRequest`?

```java
/* CorgiRequest class */
public final String getCorgiServer() {
    return this.corgiServer;
}

public final String getCorgiId() {
    return this.corgiId;
}

public final boolean isSubscriber() {
    return this.isSubscriber;
}

public final String getTimestamp() {
    return String.valueOf(new Date().getTime() / 1000);
}

public final String getNonce() {
    return (String) this.nonce$delegate.getValue();
}

public final String getSignature() {
    return (String) this.signature$delegate.getValue();
}
```

So the `getCorgiServer`, `getCorgiId`, and `isSubscriber` function are simple getters to private members of the class and `getTimestamp` retruns the current timestamp in seconds.

`getNonce` and `getSignature` use a delegate to calculate the value instead. These are actually defined during `CorgiRequest` constructor:

```java
/* CorgiRequest class */
this.nonce$delegate = // ...
  public final String invoke() {
      MessageDigest messageDigest = MessageDigest.getInstance("sha-256");
      messageDigest.update(Random.Default.nextBytes(32));
      byte[] digest = messageDigest.digest();
      Intrinsics.checkNotNullExpressionValue(digest, "getInstance(\"sha-256\").a…s(32))\n        }.digest()");
      return ByteArraysKt.toHexString(digest);
  }
this.signature$delegate = // ...
  public final String invoke() {
      String generateSignature;
      generateSignature = NetworkKt.generateSignature(CorgiRequest.this);
      return generateSignature;
  }

```

So the `getNonce` generate 32 random bytes and returns a SHA256 hexdigest. `getSignature`, however, uses another function by `NetworkKt`:

```java
/* NetworkKt class */
public static final String generateSignature(CorgiRequest corgiRequest) {
    String sb;
    if (corgiRequest.isSubscriber()) {
        StringBuilder sb2 = new StringBuilder();
        String upperCase = DOC_ID_HEADER.toUpperCase(Locale.ROOT);
        StringBuilder append = sb2.append(upperCase).append('=').append(corgiRequest.getCorgiId()).append(',');
        String upperCase2 = NONCE_HEADER.toUpperCase(Locale.ROOT);
        StringBuilder append2 = append.append(upperCase2).append('=').append(corgiRequest.getNonce()).append(',');
        String upperCase3 = TIMESTAMP_HEADER.toUpperCase(Locale.ROOT);
        StringBuilder append3 = append2.append(upperCase3).append('=').append(corgiRequest.getTimestamp()).append(',');
        String upperCase4 = SUBSCRIBER_HEADER.toUpperCase(Locale.ROOT);
        sb = append3.append(upperCase4).append('=').append(corgiRequest.isSubscriber()).toString();
    } else {
        StringBuilder sb3 = new StringBuilder();
        String upperCase5 = DOC_ID_HEADER.toUpperCase(Locale.ROOT);
        StringBuilder append4 = sb3.append(upperCase5).append('=').append(corgiRequest.getCorgiId()).append(',');
        String upperCase6 = NONCE_HEADER.toUpperCase(Locale.ROOT);
        StringBuilder append5 = append4.append(upperCase6).append('=').append(corgiRequest.getNonce()).append(',');
        String upperCase7 = TIMESTAMP_HEADER.toUpperCase(Locale.ROOT);
        sb = append5.append(upperCase7).append('=').append(corgiRequest.getTimestamp()).toString();
    }
    return sign(sb);
}
```

(Some uninteresting code is removed from snippets for brevity).

The function creates a string and calls `sign` on it. The string is composed of all headers I've seen before. For each one, after the header name comes `=` and the value it takes. The character `,` separates between headers.

What strikes me as odd is that it seems the signature (that accompanies the request as another header, may I remind you) is generated based on *new* calls to `getNonce` and `getTimestamp`. Maybe it's a quirk of how this "delegate" feature is used, but the timestamp is definitely generated again. Maybe it's unlikely a whole second passes between the two calls, though.

Anyway, as I saw, the string is passed to `sign`:

```java
/* NetworkKt class */
public static final String sign(String message) {
    byte[] decode = Base64.decode(CorgiNetwork.Companion.getSharedSecret(), 0);
    Mac mac = Mac.getInstance("HmacSHA256");
    mac.init(new SecretKeySpec(decode, "HmacSHA256"));
    Charset UTF_8 = StandardCharsets.UTF_8;
    byte[] bytes = message.getBytes(UTF_8);
    byte[] doFinal = mac.doFinal(bytes);
    return ByteArraysKt.toHexString(doFinal);
}
```

Simple enough - this computes [HMAC](https://en.wikipedia.org/wiki/HMAC) using SHA256 as the hashing function. But HMAC requires a secret value, which this code seems get by base64-decoding `CorgiNetwork.Companion.getSharedSecret()`.

The implemenation of this function is a simple `CorgiNetwork` class

```java
/* CorgiNetwork class */
public final String getSharedSecret() {
    return CorgiNetwork.sharedSecret;
}

// ...

public CorgiNetwork(Context context) {
    String string = context.getString(R.string.hmac_shared_secret);
    sharedSecret = string;
}
```

Right, so this `R` thing tells me that secret is taken from the apk resources:

Like I mentioned earlier, jadx provides a special `Resources` directory. Besides the `AndroidManifest.xml`, it contains all other resources used by the app - images, layouts and strings. Strings in particular can be a good starting point when reversing large Android apps.

I always felt the resources are confusiongly arranged - you have to browse to the `Resources/resources.arsc/res` subdirectory to view them, then choose one out of the many `values-{locale}` directories. However usually I look for the one without a locale, simply named `values` as it usually contains values which are needed for every version.

For this app, the directory exists. Within I opened `strings.xml` and amongst the strings is the one I wanted:

```xml
<!-- ... -->
<string name="dropdown_menu">Dropdown menu</string>
<string name="hmac_shared_secret">uBvB5rPgH0U+yPhzPq9y2i4f1396t/2dCpo3gd7l1+0=</string>
<string name="in_progress">In progress</string>
<!-- ... -->
```

Lucky, the HMAC secret is easily accessible! This means I can generate signatures at will without having to run the app.

Okay, so I now know how the request is constructed and how it's signed, but I'm missing the important pieces - the URL the request is sent to (the return value of `getCorgiServer()`) and the members of `CorgiRequest` used for the signature headers.

I need to either see who initializes `CorgiRequest`, or who calls `makeSecretRequest`. I opted to go for the latter in case there are many instantiations of `CorgiRequest`.

Searching x-refs is easy enough in jadx - simply pressing 'x' on the function's name.

The first find is `invokeSuspended`, a function of `MainActivityViewModel$requestCorgi$1`. This is part of an activity view model. It passes its own `this.$corgiRequest` as the parameter I'm after. The member's value is initialized with a parmeter passed to the constructor - so I need to find who initializes this activity view.

Before going down that road, I looked at the end of this `invokeSuspended` function

```java
/* MainActivityViewModel$requestCorgi$1 class */
public final Object invokeSuspend(Object obj) {
  // ...
  Object makeSecretRequest = NetworkKt.makeSecretRequest(this.$corgiRequest, this);
  obj = makeSecretRequest;
  // ...
  JSONObject jSONObject = new JSONObject((String) obj);
  NetworkState.Idle idle = NetworkState.Idle.INSTANCE;
  String string = jSONObject.getString("title");
  Intrinsics.checkNotNullExpressionValue(string, "json.getString(\"title\")");
  String string2 = jSONObject.getString("text");
  Intrinsics.checkNotNullExpressionValue(string2, "json.getString(\"text\")");
  String string3 = jSONObject.getString(ImagesContract.URL);
  Intrinsics.checkNotNullExpressionValue(string3, "json.getString(\"url\")");
  uiState = new UiState(idle, new SecureCorgi(string, string2, string3), false, 4, null);
  mainActivityViewModel2.setUiState(uiState);
  return Unit.INSTANCE;
}
```

This reveals that the HTTP response's value is actually a JSON containing a few fields: title, text and a URL. All three are displayed in the app a `SecureCorgi` element.

Anyway, back at finding who initializes the class - there's just one case - the function `requestCorgi` in `MainActivityViewModel`, which is very short and simply passes along the `CorgiRequest` object it receives as an argument.

I took another x-ref step - this finally landed me at the place that creates the `CorgiRequest`! It's yet another `invokeSuspend` function, but in `MainActivityViewModel$scanQrCode$1` this time.

My immediate guess is that this activity view allows the app user to scan a QR code (like the one I was given), then it creates a `CorgiRequest` object and sends it all the way through the flow I just went through.

```java
/* MainActivityViewModel$scanQrCode$1 class */
public final Object invokeSuspend(Object obj) {
  // ...
  corgiRequest = QrCodesKt.readCorgiCode(str);
  if (corgiRequest != null) {
      this.this$0.requestCorgi(corgiRequest);
  }
```

I verified this by looking at `QrCodesKt.readCorgiCode`, hoping the view uses an external library to parse QR code so I won't have to sift through too much code.

```java
/* QrCodesKt class */
public final class QrCodesKt {
    private static final String CORGI_ID_PARAM_NAME = "DOCID";

    public static final CorgiRequest readCorgiCode(String corgiCode) {
        String str;
        boolean isSubscribed;
        Uri parse = Uri.parse(corgiCode);
        if (Intrinsics.areEqual(parse.getScheme(), "https") || Intrinsics.areEqual(parse.getScheme(), "http")) {
            String authority = parse.getAuthority();
            if (authority != null && StringsKt.contains$default((CharSequence) authority, (CharSequence) BuildConfig.CORGI_AUTHORITY, false, 2, (Object) null)) {
                String path = parse.getPath();
                boolean startsWith$default = path != null ? StringsKt.startsWith$default(path, "/debug/", false, 2, (Object) null) : false;
                try {
                    byte[] decoded = Base64.decode(parse.getLastPathSegment(), 8);
                    Charset UTF_8 = StandardCharsets.UTF_8;
                    str = new String(decoded, UTF_8);
                } catch (Exception unused) {
                    str = null;
                }
                Uri corgiDataUri = Uri.parse(str);
                if (verifyLink(corgiDataUri)) {
                    String str2 = corgiDataUri.getScheme() + "://" + corgiDataUri.getAuthority() + corgiDataUri.getPath();
                    String queryParameter = corgiDataUri.getQueryParameter(CORGI_ID_PARAM_NAME);
                    if (queryParameter == null) {
                        return null;
                    }
                    if (startsWith$default) {
                        isSubscribed = Intrinsics.areEqual(parse.getFragment(), "force_subscribed");
                    } else {
                        isSubscribed = SubscriptionKt.isSubscribed();
                    }
                    return new CorgiRequest(str2, queryParameter, isSubscribed);
                }
                return null;
            }
            return null;
        }
        return null;
    }
    // ...
```

Okay, so from the `Uri parse = Uri.parse(corgiCode);` line, I discern the input string `corgiCode` is not some raw QR code but actually a URL. Most likely it's the one embedded in the QR code.

The function continues to verify that the URL scheme is HTTP(/S), and that the authority (basically the domain) contains `corgis-web`.

It then extracts the last segment of the URL path. Assuming it's the same format as the one I scanned - it will be the long base64-encoded path. This assumption is further strengthed since the function base64-decodes the segment, and parses it as a URL, matching what I saw earlier.

Then the function calls `verifyLink`, but before looking at it, I can see how the function constructs the `CorgiRequest` object:

* The `corgiServer` is simply the entire URL encoded with the path segment (excluding the parameters).
* The `corgiId` is taken as the value of the `DOCID` parameter
* `isSubscribed` is set to true if the path of the original URL starts with `/debug/`, or based on the output of `SubscriptionKt.isSubscribed()`.

So in the case of the URL I scanned myself:

```
corgiServer = https://corgis-web.h4ck.ctfcompetition.com/corgi
corgiId = flag
isSubscribed = SubscriptionKt.isSubscribed()
```

I took a very quick look into `SubscriptionKt.isSubscribed()`. It's a simple getter to a class member whose value is set at the `Subscripton.loadSubscription` function. This in turn is based on the [SharedPreferences](https://developer.android.com/training/data-storage/shared-preferences) of the app.

Deciding not to put too much attention to it, I went to look at `verifyLink`.

```java
/* QrCodesKt class */
public static final boolean verifyLink(Uri uri) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        Set<String> queryParameterNames = uri.getQueryParameterNames();
        Set<String> set = queryParameterNames;
        ArrayList arrayList = new ArrayList(CollectionsKt.collectionSizeOrDefault(set, 10));
        for (String str : set) {
            arrayList.add(URLDecoder.decode(str, StandardCharsets.UTF_8.name()));
        }
        ArrayList arrayList2 = new ArrayList();
        for (Object obj : arrayList) {
            String name = (String) obj;
            if (!StringsKt.startsWith$default(name, "_", false, 2, (Object) null)) {
                arrayList2.add(obj);
            }
        }
        for (String name2 : CollectionsKt.sorted(arrayList2)) {
            LinkedHashMap linkedHashMap2 = linkedHashMap;
            String queryParameter = uri.getQueryParameter(name2);
            if (queryParameter == null) {
                queryParameter = "";
            }
            linkedHashMap2.put(name2, queryParameter);
        }
        LinkedHashMap linkedHashMap3 = linkedHashMap;
        return Intrinsics.areEqual(uri.getQueryParameter("_mac"), generateSignature(linkedHashMap3));
    }
```

This function takes a URL as input, and checks the value of the `_mac` parameter in the URL against the return value of `generateSignature` called with a `Map` of the parameters in the URL, excluding those that start with `_`. In the case of the URL I have, it would be just the `DOCID` parameter.

```java
/* QrCodesKt class */
    public static final String generateSignature(Map<String, String> values) {
        ArrayList arrayList = new ArrayList();
        for (String str : CollectionsKt.sorted(values.keySet())) {
            StringBuilder sb = new StringBuilder();
            String upperCase = str.toUpperCase(Locale.GERMAN);
            arrayList.add(sb.append(upperCase).append('=').append((Object) values.get(str)).toString());
        }
        return NetworkKt.sign(CollectionsKt.joinToString$default(arrayList, ",", null, null, 0, null, null, 62, null));
    }
```

Okay, so `generateSignature` simply calls the `NetworkKt.sign` I've already looked at. It prepares the input by concatenating the input `Map` using `=` between a key and its values and `,` between keys. Exactly in the same form I saw being done with the headers.

For the URL I have, this will return a signature of the string `"DOCID=flag"`.

At that point I feel I have a pretty good picture of what's going on in this app:

1. A user scans a QR code
2. The app verifies that the QR code embeds a URL that contains a properly signed internal "Corgi" URL.
3. If verified, a signed request is being sent to the internal URL, fetching the corgi securely.

There's also this whole additional options of being "subscribed". 

I guess that since the above functionality would have been easily accessible was I to install the app, this challenge solution isn't install the app → scan the QR code → win, and the expectation is that I bypass my way into being a subscriber. 

I saw this can be achieved using the app by controlling the shared preferences or creating a new valid URL with a `/debug/` in the path.

However, since I took the longer route here, I reversed the entire signing process. Since I also have the private key - I can simply send the request myself with whatever parameter my heart desires.

Let's do it:

```py
import requests
import time
import base64
import hmac
import hashlib
import os

from urllib.parse import urlparse, parse_qs

SHARED_HMAC_KEY = b"uBvB5rPgH0U+yPhzPq9y2i4f1396t/2dCpo3gd7l1+0="
QR_URL = "https://corgis-web.h4ck.ctfcompetition.com/aHR0cHM6Ly9jb3JnaXMtd2ViLmg0Y2suY3RmY29tcGV0aXRpb24uY29tL2NvcmdpP0RPQ0lEPWZsYWcmX21hYz1kZWQwOWZmMTUyOGYyOTgwMGIxZTczM2U2MjA4ZWEzNjI2NjZiOWVlYjVmNDBjMjY0ZmM1ZmIxOWRhYTM2OTM5"

def main():
    # I'm verifying the url like they do - 
    # It's useful since it proves the HMAC key I found is valid
    parsed = urlparse(QR_URL)
    assert('http' in parsed.scheme or 'https' in parsed.scheme)
    assert('corgis-web' in parsed.hostname)
    last_path = parsed.path.split("/")[-1]
    corgi_data_uri = base64.b64decode(last_path)
    parsed_corgi_data_uri = urlparse(corgi_data_uri)
    parameters = parse_qs(parsed_corgi_data_uri.query)
    _mac = parameters[b'_mac'][0]
    docid = parameters[b'DOCID'][0]
    # Asserting the verification of the _mac parameter.
    assert(_mac.decode('utf-8') == sign(b"DOCID=" + docid))

    # Creating a "CorgiRequest object"
    corgi_server = parsed_corgi_data_uri.scheme + b"://" + parsed_corgi_data_uri.hostname + b"/" + parsed_corgi_data_uri.path
    corgi_id = docid.decode('utf-8')
    timestamp = str(int(time.time()))
    nonce = get_nonce()
    is_subscribed = "false" # Or "true" for the flag!
    response = requests.get(
        url=corgi_server,
        headers={
            'X-Document-ID': corgi_id,
            'X-Request-Nonce': nonce,
            'X-Timestamp': timestamp,
            'X-Auth-MAC': sign(f"X-DOCUMENT-ID={corgi_id},X-REQUEST-NONCE={nonce},X-TIMESTAMP={timestamp},X-USER-SUBSCRIBED={is_subscribed}".encode()),
            'X-User-Subscribed': is_subscribed
        }
    )
    assert(response.status_code == 200)
    # Should be a JSON object
    print(response.json())

def sign(message: bytes) -> str:
    hmac_obj = hmac.new(base64.b64decode(SHARED_HMAC_KEY), message, hashlib.sha256)
    return hmac_obj.hexdigest()

def get_nonce() -> str:
    hash_obj = hashlib.sha256(os.urandom(32))
    return hash_obj.hexdigest()

if __name__ == '__main__':
    main()
```

Indeed, the `_mac` assertion passes, proving that the HMAC key I found is correct. The response returned from the signed request is no longer the unauthorized error I got earlier, but a JSON object as expected!

```json
{
    "subscriberOnly": true,
    "text": "Secret message",
    "title": "Secret flag data",
    "url": "Subscribers Only"
}
```

As I guess, the endpoint requires the signed request to have `isSubscribed` equals `True`. Luckily, I can just change the parameter in my Python script to have server reply with the flag!
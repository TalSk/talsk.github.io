---
layout: post
title:  "Cryptography Recast As Simple!"
subtitle: 'Does "Assymettric Encrpytion" Make You Shiver? Click here!'
date:   2023-07-16 18:05:34 +0300
tags: [RE, gaming, android, pokemon-go]
readtime: true
cover-img: ["/assets/images/Magic-Behind-Encryption/Cover.png"]
thumbnail-img: "/assets/images/Magic-Behind-Encryption/Thumbnail.png"
share-img: "/assets/images/Magic-Behind-Encryption/Share.png"
---

# Intro

This post is an adapatation of one of my live presentations, which is my attempt to explain Cryptography in an intuitive way, aimed at crowed of software engineering in all levels, without any kind of familiarilty with Cryptography expected.

## Why Me?

What's makes me a candidate to explain cryptography concepts? Well, nothing, and this is exactly the point - cryptography is *easy* and *simple*, so *even I* can explain it to a wide audience.

But still, as a developer, when you look at cryptographic libraries, they seem complex and difficult to understand, and in general they are treated to the extreme of encapsulation - don't understand what the library or functions does, just use it as is.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Cryptography-Simple/How-Did-We-Get-Here.png" title="How did we get here?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A commonly seen cryptographc library documentation</i></figcaption>
</figure>

My perspective is unique only because the circumstances for me happened to be in reverse - I first learnt about cryptography while programming software, and only afterwards saw it academically:

When I was started the final year of my Bachelor's, I was required to pick elective classes. None really interested me or fit my exam period schedule (I'll leave you to guess which one I was more interested to satisfy). 

I remember hanging with my friend and he suddendly pointed at a class named *Modern Cryptography* and said "why don't you pick this one? You like theoretical stuff and it also fits your schedule". I shrugged and signed up to it.

I came across cryptography concept and libraries when I programmed in the past, and knew that the subject is hard so unsuprisingly, I kept cursing that decision during the semester which was one of the hardest I went through, and *Modern Cryptography* was one of classess to blame for that (have yet to forgive my friend for this). However, I remember sitting in one of the later lessons of the sesemster. The professor was explaining some new concept and a realization dawned on me:

Behind all the crazy math-stuff, cryptography at its core solves *intuitive* questions* in *intuitive* ways. Maths is just a (sometimes complex) tool that helps us achieve this.

## The Feelings of Cryptography

Now it's your turn to participate. When I say "Cryptography", "Encryption", "Keys", "Decryption", "Certificates", what comes do your mind? What's the feelings and connotations these words are attached to for you?

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Cryptography-Simple/Homomorphic-Diagram.png" title="What a lovely diagram">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Diagram of one of the many tools of cryptography</i></figcaption>
</figure>

Most often than not, the answers I hear to these questions tend to be on the negative side, mostly consisting of:
- *Confusion* when trying to work with cryptographic functions and concepts.
- *Fear* of making mistakes that will resut in broken security.
- *Anger* at libraries having bad documentation.
- *Detachment* born of years being told "don't roll your own cryptography!"

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Cryptography-Simple/Dont-Roll-Your-Own.png" title="Sure thing, but do you promise to document your library well?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A warning almost every developer bumped into</i></figcaption>
</figure>

Is there another wildly used area of software progamming that garners such feelings? I think the anomaly of cryptography is unique, and thus overcoming these feelings and understanding cryptography is even more important.

In any case, I hope this short intro was convincing enough to read the rest of this short post. Let's begin!


# The Goal Of Cryptography

Intuitivly, we want cryptography to allow two parties to communicate with each other secretly on public channel. But what does this intuitive goal mean?

// Show image of dog and cat wishing to communicate while many other animals listen

1. The sender wants to assert secrecy.
  Only the recipient will be able to read the message.
2. The recipient wants to verify validity.
  No one will be able to change the message.

## Achieving the Goal, Step 1

The two goals we set for ourselves seems difficult - especially when communicating publicly.
Let's imagine a scenario trying to achieve the goals:

> There's a big house party which both the sender and the recipient attend. In the beginning of the evening, they had the chance to meet and greet each other. During this greeting, the sender had given a key to the recipient
> Later, at the party, the sender wants to send a cryptographically-secured message to the recipient. But the house is very large and the recipient is all the way on the other side of it. 
> The sender will then write their message on a piece on paper, fold it and put it in a box and use a key, identicial to the one they gave the recipient earlier, to lock it.
>The sender will then pass the box to the crowed, asking it to be delivered to the recipient. This might take a while (depending on how drunk the partygoers already are), but eventually the box will reach the recipient. 
>The recipient will use the key to open the box, and read the message.

// Image of a house party

Did we manage to do it? Let's see:

1. Since the box and the keys were brought by the sender, they can be sure that no one but the recipient (to which they gave the key personally) is able to open the box and read the message.
2. Since the recipient knows only they and the sender hold the key, no one who had the box during transfer could have changed the piece of paper inside of it - thus it was written by the sender.

(Note that we're assuming that both the sender and the recipient are truthful and follow exactly the method we described, and that the box eventually reaches the recipient. Other than that, we didn't have to assume anything about the partygoers, what the house looks like, what kind if beer was brought for it and who won beerpong)

Great! We successfully managed to implement cryptography! And on the first try as well.

But, this scenario isn't akin to what happens on the internet - here we're dealing with binary data being sent around, there's no physical boxes or locks. So what do we do?

## Achieving the Goal, Step 2

Let's deal with the new scenario: the sender and recipient now communicate through *the internet*, and the sender has some secret string they wish to send to the recipient.

To make our lives easier for now, we'll still assume the pair met up in the past and exchanged a key. This time, it will be a long string. In fact, let's imagine this key is an infinite string, and only the pair knows it. 

Given that, our cryptography implementation will be as follows:

> The sender will take their message (known as the plaintext) and the key and apply a function to combine them.
> The combined value (known as the cipher) will be sent over the internet by the sender.
> The recipient will take the cipher and the key and apply a function to combine them.
> The combined value will be the sender's message.

So does this implemenation achieve our goals? Well, the success seems to entirely depend on the *function*s mentioned. It seems a bit magical that by picking the right ones, nobody will being able to read the original message, as well as not being able to change it.

Are there such magical functions, you ask? Well, in 1882 we discovered that they exist. And not only that, we're going to use the *same funciton*, and not only ***that***, the functoin is...addition[^1].

// Image of this symmetric approach

While this sounds crazy on first sight, it [provably works](https://en.wikipedia.org/wiki/One-time_pad), and we achieve both goals with this approach. 

However, one big thing that decreases the crazienss, is the fact that we assumed our communicating parties shared an infinitely long string as the key, which isn't something we can rely on in real life.

## Achieving the Goal, Step 3

In our yet new scenario, our parties share a finite key, which in fact can be quite small compared to the message the sender wishes to pass.

So what do we do? Just duplicate it! Turns out, we can use the same implementation as before, only with the key continously duplicated to cover the entire message. 

Under this restriction addition as our designated function breaks down and doesn't work. However, smart people have come up with other ideas for this function, which does work, and is called Rijndael (or more commonly, [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)). 

// Image of the symmetric approach using duplicated key and AES

Well, after we lost the "infinity" of the key, by saying that AES works, it comes with a small caveat - we still achieve the two goals we set for ourselves, but AES only promises that the amount of work someone needs to do in order to break either one of the goals grows with the length of the key we use - the larger, the better. 

Also, as far as we currently know, this work grows exponentially[^2] with the key size, so even keys whose length sound plausible to humans (like a 32-character string), require billions of years for modern computers to break.

## Symmteric Key Cryptography

Using the same key and function on both ends of the cryptographic process has earned the name "symmertic" for cryptographic implemenatation such as AES, and so they are known as "symmetric-key algorithms".


So...that's it? Are we done? 

Mostly - we've successfully achieve the goal we set out to do, and this lets us communicate securily over insecure channels such as the interent. This is huge!

So why mostly? Because we still rely on the assumption that the parties had met before hand and agreed on a shared, secret key. 

Well, personally I never met the CEO of either Google nor Amazon, so how can I buy stuff on Amazon using my credit card, or share very sensitive details 


# Footnotes


[^1]: Well, not *exactly* addition, but close enough - it's the kind of addition you don't "remember a 1" for, called [modular addition](https://en.wikipedia.org/wiki/Modular_arithmetic), and in our case simply addition modulo 2.

[^2]: As of today (2024), many known attacks on AES involve using side-channel info, or relying on a misconfiguration of the cipher. Without these, most attacks only achieve marginal improvement over bruteforcing the key.





















































When I say "Encryption", what are things that come up to your mind? What does it make you feel?

* Confusing
* Convoluted
* Maths
* Symmetric
* Asymmetric
* RSA
* SSL/TLS
* Keys
* Secrets
* KMS/Key generation services

So I'm here to (hopefully once and for all) get some things straight that will help you think encrpytion is simple and easy!

On the side, I'm going to keep a record of all important notions I'm mentioning
[Add "Encryption" - The process of "hiding" a piece of private data]

First, what are our goals when talking about secure encryption?

1. Confidentiality: Being able to send encrypted plaintext over an exposed channel safely, and only the target is able to decrypt.
[Add "decryption" - The process of "unhiding" a piece of encrypted private data]
[Add "plaintext" - Private data in need of encryption]
2. Integrity: Altering the ciphertext won't produce valid plaintext
[Add "ciphertext" - An encrypted plaintext]

Alright, now it's time to present the main player of today's game: Symmetric Encryption
[Physical simulation. Give two keys and a lock, have one person write something down and pass it around the table]

We got what we wanted: nobody was able to open or change the secret message. Success!

But notice that we:
1. Needed to exchange the keys in the first place
2. The keys are an exact replica of one another

We'll deal with how to make it happen later, but first, assuming that we have this setup. What happens when we're dealing with bits over the internet? We'll use (sort of) maths instead. Specifically, playing with the bits so they don't make sense unless you have the key.
[Add "Key" - Shared secret information allowing encryption and decryption]

In fact, what if I told you we already have the idea of the perfect encryption?!

Well, if the keys are simply the length of the to-be plaintext we'll take the plaintext and XOR every bit with the respective bit of the key.
XOR is a nice binary function which is "the opposite of itself". So, applying the XOR with the same key again will produce the original plaintext.

This system is proven to be theoretically secure. However, exchanging  
---
title: "Tal's DEF CON 32 Solo Watch Party"
date: 2024-11-13 11:05:34 +0300
categories: ["Blog"]
tags: ["research", "DEFCON", "DEFCON-32"]
image: "/assets/images/DEFCON-32-Solo-Watch-Party/DEFCON-32-Solo-Watch-Party-cover.webp"
---

# Intro(spective)

In the past two weeks, right after DEFCON uploaded the videos for this year's talks, I decided to not procrastinate as I usually do. Instead, I sat down, watched the talks, and made a short summary of each. I believed (and still strongly do) that it's a sure way to embed the unique ideas and techniques presented into my head.

Well, writing things is something I've always done—the hard part for me is posting them online. So, I decided this time I'll tackle this by posting the summaries over LinkedIn and other networks.

Easier said than done. Limiting the amount of time between consecutive posts was the key here — the pressure made it so I wasn't able to endelssly pass my text through various LLM models. 

At the end, almost all posts are basically the first iteration with a simple grammar and spell-checker applied. At some point, I even built up enough courage to tag the amazing researchers! 

So all in all, I think I can crown this experiment a success. I'm happy I did it and can't wait for next year's talks, because even if I don't attend, I'll have my summaries to look forward to!

Thanks go yet again to the amazing presenters and to everyone who has been diligently reading these posts and approaching to me about them :)

All the posts were uploaded to social media, as said, and are also given here, in order of appearance. Enjoy!

## -1- OH-MY-DC: Abusing OIDC all the way to your cloud - Aviad Hahami

[Talk link](https://www.youtube.com/watch?v=asd33hSRJKU) 

This talk covers potential vulnerabilities due to misconfigurations when using OIDC to facilitate authorization of pipelines to access cloud resources.

It begins by reviewing what OIDC is, how it works, and how it’s currently used to enable this functionality. This is a short section that does an excellent job of explaining this traditionally "scary" subject, which is usually tied to the complexity of OAuth (which isn’t really required to understand OIDC).

The talk explores 3 types of issues beyond the trivial "no-config" case (how Aviad puts it) where the door is basically open.

 1. The first is a case of relying on unsafe claims. These are added by each OIDC provider to the JWT and can be used to define certain behavior in your CI, but should not be relied on for authorization as they can be easily faked. In some cases, even the `sub` claim can be customized, leading to this issue! (Aviad published an [open-source tool](https://github.com/PaloAltoNetworks/github-oidc-utils) to check for this issue in GH Actions)

 2. The second is interesting to me—showing how the `repo:some_org/*` format, which I thought to be mostly safe, could still be exploited! If the organization is open to PPE (poisoned pipeline execution) vulnerabilities, which could happen if just a single repo in the organization has an action configured to run on pull requests with `id-token:write` permission, then this format is exploitable. An attacker can run with the permissions of the vulnerable repo, receiving an identity token from GitHub with the `sub` claim in the format `repo:some_org/some_repo`, which matches the lax format, allowing access to cloud resources.
 This issue isn't theoretical — Aviad disclosed that Microsoft’s Azure organization was vulnerable to this issue due to a low-privilege action.

 3. The final issue was pretty surprising. It turns out CircleCI projects that allow PRs from forks were basically enabling access to any cloud resource trusting an OIDC token from that CircleCI project.

This is due to two oversights on CircleCI’s side: first, any workflow changes on forks trigger a pipeline, allowing arbitrary code to run on projects with the setting enabled. Second, every CircleCI machine is given an OIDC token. The result? For those organizations, it’s easy to steal OIDC tokens from CircleCI and access any resource protected behind CircleCI OIDC claims.

Overall takeaway: This was an awesome talk, and I learned a lot about advanced methods to exploit OIDC misconfigurations.


## -2- Joe and Bruno's Guide to Hacking Time: Regenerating Passwords from RoboForm's Password Generator

[Talk Link](https://www.youtube.com/watch?v=N2eKCAzM2kw)

When Joe started talking about RoboForm and cracking password generators, something clicked — I remembered watching a Youtube video about abusing random number generation to unlock a bitcoin wallet worth millions...

Turns out, it was [Joe and Bruno’s video](https://www.youtube.com/watch?v=o5IySpAkThg)! It’s incredibly well-edited, and you should definitely watch it right after the DEFCON talk (though it spoils the ending a little 😉)

The talk dives into pseudo-random number generators (PRNGs) — software that takes an initial seed to generate a sequence of random numbers. If the generator doesn’t use real randomness (like lava lamps, for example), knowing the initial seed lets you predict all the numbers it will generate, including passwords.

RoboForm, a well-known password generator, used to rely on the current time as its seed — specifically a Unix timestamp in seconds. Unfortunately, this means that the number of passwords that can possibly be generated given a time frame is relatively small. This means that if you know roughly when a password was generated and its options (like length, capitals, symbols), you could easily brute-force all possible passwords in that timeframe.

Joe and Bruno exploited this exact idea! They knew (from the wallet’s owner) when the password was generated and the generation options. They reverse-engineered the RoboForm app, found a way to iteratively change the system time, and hooked into the code to regenerate the password as if it was created back then.

They managed to generate around 1,000 passwords per second, and within hours, they cracked open the wallet!

## -3- Behind Enemy Lines: Going Undercover to Breach the LockBit Ransomware Operation - Jon DiMaggio

[Talk Link](https://www.youtube.com/watch?v=dLOUzF6_Y54)

In a captivating talk by Jon DiMaggio, he details the process of infiltrating and "befriending" the one and only LockBit, a famous hashtag#ransomware criminal.

It goes all the way from the process of going undercover, diving deep into the rabbit hole of hacking forums, building rapport and getting to know how things work, to a full-on, day-by-day conversation with LockBit. This eventually ends right around the time the LockBit ransomware attacked a children’s hospital; law enforcement got involved and took the LockBit website down.

After it came back up, Jon decided it was time to use all the information he had managed to collect to do a big reveal—and essentially full-on dox LockBit.

This is not a classic, cool vulnerability disclosure coupled with excellent research kind of talk, but a unique behind-the-scenes look at how these hashtag#cybercriminals operate and think. One of the reasons hashtag#DEFCON content is so amazing—props!

## -4- Kicking in the Door to the Cloud: Exploiting Cloud Provider Vulnerabilities for Initial Access - Nick Frichette

[Talk Link](https://www.youtube.com/watch?v=oAriLYN-5HA)

Nick is a security researcher I've been following for a while, so his talk was a must-watch, and he didn't let me down! In an excellent, flowing, and engaging talk, he covers two vulnerabilities discovered by the DataDog security team in AWS.

What's special about them is that, as opposed to many other vulnerabilities, they provide initial access to an AWS account — something which is notoriously "boring" (more often than not an exposed access key on some public repo belonging to some overprivileged user...). In addition, they're actually vulnerabilities in AWS services themselves!

The first one abuses the way service roles are defined in AWS — their trust policy simply allows the AWS service to assume them, no further conditions needed. The idea is that the service would properly validate who can use which role based on the configuration and the user permission to call `PassRole`. 

Since this protection obviously shouldn't work cross-account (in my account I'm an admin and can freely `PassRole`, but would this allow me to use a service role in another account?), the operation is then always blocked by AWS. Nick and his team found a clever way to bypass this in AWS AppSync service. They found that the service is case-insensitive in its parameters, unlike in other services, while the `PassRole` restriction only works on a case-sensitive version of the role ARN parameter. Funny!

The second vulnerability has to do with `AssumeRoleWithWebIdentity`, the very long name AWS uses for OIDC-based `AssumeRole`. The AWS Cognito service is infamous for its roles — being public-facing, it's easy to accidentally allow public access to more resources than intended. 

However, these roles usually contain a condition on an identifier that is not always public. Turns out, the AWS Amplify service went a step further and created default Cognito roles without any restricting conditions, essentially opening them to the public! Nick found thousands of vulnerable roles through a simple GitHub search. This research is the reason you can no longer assume a Cognito role using an identity pool from another account. I didn't know that! That's cool.

Nick completes the talk by providing a good recommendation that would future-proof your roles — even against vulnerabilities yet to be discovered — AWS condition keys! These are a set of conditions you can place on your AWS roles that would only allow your own account or organization to assume them. So if your roles are internal-facing, there's absolutely no good reason not to use the conditions and protect yourself.


## -5- Breaching AWS Accounts Through Shadow Resources

[Talk Link](https://www.youtube.com/watch?v=m9QVfYVJ7R8)

The trio, Yakir Kadkoda, Ofek Itach and Michael Katchinskiy, reveal a unique technique that has uncovered vulnerabilities in six (!) different AWS services. 

A bit of background: S3, one of the oldest AWS services, is a bit different — the names of buckets (the main type of resource) are globally unique, meaning that if someone has claimed the bucket 'test', nobody else can pick the same name, even under a different AWS account.

This allows for a bucket-name-squatting issue — predicting the name of a yet-to-be-used bucket, creating it, and making users accidentally pull files from this attacker-controlled bucket.

In this talk, the trio uncovers a crazy extension of this attack: predicting the names of (semi-)automatically created buckets.
AWS Services utilize S3 by creating buckets to be used behind the scenes. They normally create those buckets, but how do they behave if it exists?

Turns out they mostly continue as usual, pushing the files into the bucket anyway and pulling them out at a later time. 
If an attacker can predict the names of these buckets, they can create them in advance, and on usage — replace the file before it's pulled back out.

In case this file is used to create AWS resources, like in their first example of CloudFormation — this leads to arbitrary access to the victim's AWS account. 
The only remaining hurdle is the bucket names: can they actually be predicted in advance? (6/9)

The group discovered that Glue, EMR, SageMaker, and CodeStar AWS services use the AWS account ID as a source of "randomness" for the bucket name.

Unfortunately, AWS account IDs are not considered secrets (hot take, I know), so as long as you know your victim's account ID, you could attack them on use of any of these services. 

Other services, like CloudFormation, use a random hash making it harder for attackers. However, they are fixed per account. The researcher's show that ARNs of these buckets can be easy found in public repos

A very cool technique that I'm sure we'll see again in the future! 


## -6- Taming the Beast: Inside the Llama 3 Red Team Process - Maya Pavlova, Ivan Evtimov, Joanna Bitton, Aaron Grattafiori
[Talk Link](https://www.youtube.com/watch?v=UQaNjwLhAmo)

We meet the team at Meta in charge of red-teaming the Llama - Meta's AI model. This is an extremely very interesting talk, diving deep into their processes and methodologies when they're researching how to break the guardrails around the model.

First, they go over the techniques:
* Roleplaying - asking the model to portray a character, either one which is benign, or one which makes sense to talk with on a violating topic.
* Hypotheticals - ensuring the model that the discussion is purely theoretical or used for training.
* Suppress Refusals - since upon detection of violating topics the model will start by apologizing that it cannot discuss it, command it to never use such words or apologize.
* Output Formatting - requesting the output to be within a certain format, like JSON or a table.
* Disclaimer - asking the model to add a disclaimer before its response, like a trigger warning.
* Splitting - split violating words into sub-tokens and ask questions on their concatenation. Paired with requesting the model to keep using the sub-tokens.
* Multi-lingual - switching between languages in the prompt.

All these methods are aimed to coax the model into including violating content in its response — by softening the inclusion of problematic content or making the model guardrails miss the violating content altogether.

Then, they talk about automation — a critical component when it comes to LLM pentesting. The amount of text and the large matrix of techniques makes it near impossible to test by hand. This is amplified when stepping into the area of multi-turn attacks (having a conversation instead of a question-answer).

To do this, they created a matrix combining the different risks, personas, and techniques, and the automation mix-and-matches between them to test for attack scenarios. What's cool is that they use an LLM for the automation of conversing with the model.

I think what's most interesting to me is how different their task is from "classic" red teaming, and the ingenuity they have to constantly practice to reveal further techniques. Since they deal with LLMs, however, they are usually very elegantly explainable and garner an "ah-ha!" moment, at least from me.


## -7- Outlook Unleashing RCE Chaos: CVE-2024-30103 & CVE-2024-38021 - Michael Gorelik, Arnold Osipov
[Talk Link](https://www.youtube.com/watch?v=TeVGbAkhyzg)

Sometimes, a vendor releases a patch fixing a vulnerability you are working on. Disappointing, isn't it?
In this talk, Michael Gorelik and Arnold Osipov show how they turned two patches for Outlook issues back into vulnerabilities!

First, the focus is Outlook custom forms — a feature allowing creation of tailored messages in emails.
Under the hood, forms are COM objects, defining a new form type means creating a config file for it, with a value copied to the registry specifying the COM server handler for it.

So, what if we make the key point at some DLL that we control? That's immediately RCE! To block this, Outlook uses a denylist that filters out registry keys allowing RCE like `inprocserver32`, `localserver`, etc.

A vulnerability from earlier this year found the denylist matching fails if you specify an absolute path rather than a relative path (so a `\CLSID\...\inprocserver32=` is a-okay!). This allows hijacking any COM object in the registry. Luckily, this vulnerability has been patched. But, remember the premise of the talk?

The patch disallowed starting the path with a backslash. So what did Michael and Arnold do? Add a backslash at the end! This works because `RegCreateKeyExA` deletes the last backslash in the path. However, this happens *after* the denylist check, which passes and so we have a vulnerability!

Second, the talk looks at Outlook Moniker objects—those are "smart links" in Outlook, allowing you to send emails embedding special links like Ca lender invites, Excel files, etc.

Being simple pointers, it is possible for malicious actors to send emails with references to remote files, potentially leaking NTLM credentials if the user clicks them. Fortunately, Outlook blocks these links. 
*Unfortunately*, earlier this year it was found that if you add an exclamation mark (!) at the end of the link, Outlook blocking won't work. 

The reason is a bit complicated, but in short—the link is being treated as a special kind of Moniker, triggering a different flow composed of a few functions, which are vulnerable to remote file access.

This vulnerability was patched by installing a hook on a certain vulnerable function at the end of the flow. The hook checks if a certain flag is set, and if so, blocks the call. The flag is set at the beginning of a function earlier in the flow. So only when the two functions are chained, the call is blocked.

Notice the issue? If another Moniker flow eventually reaches the vulnerable function without passing through the first one, the flag isn't set and the patch won't work! 
Indeed, the researchers discovered such a flow—a link within an image tag instead of a hyperlink

While a bit convoluted for someone who hasn't touched COM objects for at least a decade, this is still an eye-opening talk on the possibility of finding vulnerabilities in patches.

## -8- Why are you still using my server for your internet access - Thomas Boejstrup Johansen
[Talk Link](https://www.youtube.com/watch?v=uwsykPWa5Lc)

Ah, WPAD — now that's a name I haven't heard in a long time.

Short for "Web Proxy Auto-Discovery", WPAD is a protocol for machines on local networks to get their proxy configuration. Invented by Netscape in 1996, this protocol has been deprecated for a LONG time — in 1999, today marking its 25th anniversary.

WPAD is pretty simple — it uses the network name of the user's machine to search for a `wpad.dat` file, going from more specific to broad. For example, if the network name is `pc.team.dep.org.com`, a WPAD implementation will try to fetch `wpad.team.dep.org[.]com/wpad.dat`, `wpad.dep.org.com/wpad.dat` and `wpad.org.com/wpad.dat` in order as long as the last one wasn't found.

`wpad.dat` is a Proxy Auto-Config (PAC) file - a JavaScript file running in a limited environment. It implements a function that takes a URL and decides on the proxy server for the request (or DIRECT, for no proxy).

So why is this interesting? It happens that many implementations do an additional step, stripping the domain all the way to `wpad.com/wpad.dat`. 
This is on the public internet! Thus this implementation takes a PAC file from a stranger and uses it as the device's proxy configuration.

Luckily, notable WPAD TLDs — `com`, `org`, and `net` — are protected and cannot be registered. However, others are fair game!
In his excellent talk, Thomas reveals that he was able to register `wpad.dk` (the TLD for Denmark) alongside a few more.

He set up a simple PAC file directing all traffic back to `p.wpad.dk`, with interesting information like the domain, private and public IP addresses of the client. The proxy always responds with an error message, while Thomas was able to record details about the access.

Here's the stats: 90K requests a day, totaling a whopping 1.1 billion (!!) requests in a year. They span the entire world but mostly from Europe.

The HTTP GET requests were made to many file extensions, like thousands of credentials and over half a million executables. About 200k URLs also included credentials in parameters! Interestingly, the server has received POST requests too, with their entire body!

The clients' User-Agents show how the WPAD issue is not solely a Microsoft problem but spans almost every possible client in existence — Linux, Mac, and many distinct applications are affected.

During his research, Thomas also looked at `wpad.dat` files on other TLDs, finding some suspiciously malicious — one redirecting unencrypted requests through their proxy, and another one stealing ad requests, possibly for revenue theft!

The talk is great, containing hilarious tidbits about the research and the feedback form on the proxy. These vulnerabilities display both the ingenuity of researchers and the difficulty of fully deprecating a problematic service once it's deeply ingrained in systems.


## -9- QuickShell: Sharing is Caring About an RCE Attack Chain on Quick Share - Or Yair, Shmuel Cohen
[Talk Link](https://www.youtube.com/watch?v=wT9gyOeN6zY)

In this talk, Or and Shmuel take us through a wild adventure that ends up in an RCE attack chain on Quick Share.

Recently, Android’s Quick Share (analogous to Apple’s AirDrop) was released as a tool to Windows machines, marking an easier target for vulnerability research.

And indeed, the researchers found some - few by fuzzing (sending random data following the Quick Share protocol hoping for a crash) and the rest manually. Here are 4 of them:

1. A reproducible way to crash Quick Share.
2. A way to force Quick Share into an endless loop by inserting a null byte before the file extension, making Quick Share continuously try to append an increasing number to the file name while unknowingly checking that the same file exists.
3. A bypass on the file accept prompt — by simply skipping the protocol and sending the raw file transfer packet.
4. Forcing the client to connect to an attacker-controlled WiFi access point for 30 seconds through a bandwidth upgrade. This allows the attacker to MitM client traffic.

While interesting vulnerabilities (specifically 3 and 4), none seem to pose a huge risk to Quick Share clients, right?

Well— through an absolutely genius chaining of these primitives, the researchers were able to convert them into a full RCE!

First, they combined 4 and 1— by crashing Quick Share after the client connects to the attacker’s WiFi AP, it persisted forever and was not terminated. Luckily, Quick Share is scheduled to restart every 15 minutes, making the crash only temporary.

Using MitM, an attacker can see metadata of the client's encrypted TLS sessions to detect when the victim is downloading an executable installation file, like VSCode or Spotify — the ClientHello reveals the domain the victim browses to, and the size of the TCP session reveals when a file of a certain size was downloaded.

Why is this useful? Well, primitive 3 enables creation of files in the machine’s “Downloads” folder, the same one Chrome uses for its own downloads. Using the above, an attacker detects when an executable is downloaded and quickly writes a file with the expected name in the folder, while Chrome uses a temporary file during download, causing an unsuspecting victim to run malicious executable!

Where does the last primitive come into play? Turns out that when Chrome finished downloading the file, it actually *overwrote* the file created by Quick Share. By utilizing primitive 2, Quick Share continuously opens the malicious file, which caused Chrome to give up on overwriting it, while it did delete the temporary file and reported that the download was successful!

This is an absolutely crazy chaining of primitives to achieve this very nice RCE attack flow on victims. Showing how even those that are not deemed not critical to fix might pose a huge risk on victims. Props to the researchers!


## -10- Grand Theft Actions: Abusing Self-Hosted GitHub Runners at Scale - Adnan Khan, John Stawinski
[Talk Link](https://www.youtube.com/watch?v=5P7KatZBr_I)

GitHub Actions is a CI/CD tool that lets you run code (workflows) in response to events. Being code and all—it needs something to run on. 
The default option is GitHub runners - an ephemeral VM. Another option, more commonly used for large repos, is self-hosted runners— bringing your own machine to run workflows on.

Self-hosted runners are a security nightmare. Clearly shown throughout this talk, the main issue is that they’re persistent, so any vulnerability in self-hosted workflows is amplified.

Jumping ahead, the talk presents many attack techniques against self-hosted runners, nicely concluded by John [in this diagram](https://github.com/jstawinski/Github-Actions-Attack-Diagram).

The research found vulnerabilities in dozens of high profile orgs, but the talk itself focuses on PyTorch. So what’s the recipe for hacking into self-hosted runners?

First: become a contributor. The default config only blocks first-time contributors from running workflows, so after the first approved PR— it's a free game.
Find a simple grammar mistake and fix it in a quickly accepted PR, becoming a contributor in the process. From then on, you can run workflows on the self-hosted runner using PRs from your fork.

Then, gain persistence: since the machine might be protected, the researchers take a safe approach and deploy another self-hosted runner agent that connects to a private repo. Neat!

Next, steal `GITHUB_TOKEN`— a secret allowing access to GitHub for the workflow. However, in fork PRs these have read only access. But, workflows share the self-hosted runner, so after gaining persistence access they simply stole a `GITHUB_TOKEN` from another workflow from the base repo.

With such a token, there are many options for supply chain attack, like changing release assets!

But it wasn’t enough for Adnan and John— they wanted to steal real secrets from workflows. These would most likely escalate their privilege into the PyTorch organization.

It only takes compromising one workflow using these secrets. But, the already-compromised workflow did not use them, and the stronger `GITHUB_TOKEN` cannot modify the workflows directory.

The solution is simple— they found a workflow depending on a Python code from outside the workflow directory. Now, all that's needed is use `GITHUB_TOKEN` to create a branch, add a payload to the Python code that dumps the secrets to logs, trigger the workflow with the token, and retrieve the secrets.

The stolen secrets contained a GitHub personal access token with wide access to PyTorch’s private repos, as well as an AWS access key with highly privileged access to PyTorch’s AWS account.

And, just like that, becoming a contributor with a simple PR led to full compromise of PyTorch’s GitHub and AWS, which could have led to catastrophic consequences had it not been for this research. Amazing work!


## -11- SQL Injection Isn't Dead: Smuggling Queries at the Protocol Level - Paul Gerste 
[Talk Link](https://www.youtube.com/watch?v=Tfg1B8u1yvE)

SQL injection attacks exploit vulnerabilities in web applications that fail to properly sanitize user input, allowing attackers to inject malicious SQL code into database queries.

In the past, they were as prevalent as can be when it comes to web app vulnerabilities, but recent advances in web servers' default configurations and protection mechanisms have made them harder to exploit. This is evident by their ranking in the well-known OWASP Top 10 project.

However, in this talk, Paul shows an exciting new avenue for these vulnerabilities — attacking the underlying protocol!

When it comes to databases today like PostgreSQL, MySQL, Redis and MongoDB, servers communicate with them over the wire using a binary protocol. This binary protocol is TLV-based: first, the type of message, then its length, and finally, the value. So your SQL query is actually embedded within such a "packet".

While these binary protocols are commonplace in web servers' communication with peripherals, Paul focused on databases, and specifically how the length field of a message is handled by libraries when it receives a very large message, namely, more than the size that could fit in a 32-bit field.

He discovered that prominent open-source packages handling connecting and querying PostgreSQL and MongoDB, upon receiving a message longer than 2^32 bytes, calculate the length of the message correctly while truncating it to 32-bit before writing the length field.

This means that a message just over 2^32 bytes arrives at the database prepended with a length field which is very small, leaving the rest of the message to be accidentally parsed as packets! This gives a theoretical attack full control over queries.

While data exfiltration is almost not possible (the application usually returns the result of the first query), attackers can simply add a new user with high privileges to the database and use it to steal data.

On discovery, Paul wasn't satisfied with the vulnerability's exploitability — a potential attacker wouldn't know exactly the server's query and where the malicious payload is embedded, they have to send multiple 2GB queries, making the exploit very long and noisy. Through some nice tricks, borrowed from the world of shellcodes, he managed to reduce the attack process to at most 2 tries!

This research avenue still has a lot of possibilities open — Paul only scratched the surface. Binary protocols are used extensively for communication with many other applications like logging, storage, queues and caches. Even for databases — just a subset were inspected.

An enlightening talk, showing how productive it can be to take techniques used in one area of vulnerability research (in this case HTTP desync attacks by James Kettle) and applying it to a completely different domain.


## -12- Secrets and Shadows: Leveraging Big Data for Vulnerability Discovery at Scale - Bill Demirkapi
[Talk Link](https://www.youtube.com/watch?v=-KXgcWuv-Ug)

In an engaging and flowing talk, Bill presents a mind-opening new approach for discovering organizations that are susceptible to security issues. Instead of the traditionally found manually, he does so by leveraging access to big data or large-scale search.

The talk explores two such issues: dangling DNS issues in cloud providers, and exposed long-lived credentials.

Dangling DNS vulnerabilities happens when a domain is associated with a temporary IP address assigned to a cloud compute instance, such as EC2. If the compute resource goes down, the IP is released and other cloud users can "catch" it by spinning up their own compute resource, hijacking the domain in the process.

This can allow an attacker to steal session tokens and cookies, execute malicious scripts on users, and deny service.

Traditionally, an attack would target a specific domain and try to capture its associated IP address. However, Bill utilized a different approach — continuously reallocate cloud resources to enumerate massive amount of IPs!

Using a service that maps IP addresses back to domains, Bill spun up a lot of machines, allocating IP addresses, and catching their associated domains in the process! In total, 54K unique second-level-domains were captured!

An issue here was a limitation on the number of machines and IP addresses the cloud tenant was able to acquire. Using some neat tricks, Bill was able to bypass these restrictions in both AWS and GCP.

Going back to exposed long-lived credentials, a classic issue at this point, where many online services allow creation of such credentials that too often end up in public places through committed code, environment variables, and files.

There have been multiple researchers utilizing big data search to find such exposed credentials through public code searching utilities. However, nowadays many code platforms block these credentials on commit, so this method is not as useful.

So what's the new idea here? Utilize search engines on other kind of data to find those secrets! Namely, Bill used websites like VirusTotal that index many files and executables, while also supporting YARA rules to quickly search through them all.

Bill created rules to detect known static credential types based on prefixes, and found 16,652 *validated* credentials ranging from OpenAI API keys to AWS and GCP keys, and also Stripe secrets.

A unique case of how researching known issues from a different perspective can yield amazing results.


## -13- Splitting the Email Atom: Exploiting Parsers to Bypass Access Controls - Gareth Heyes
[Talk Link](https://www.youtube.com/watch?v=JERBqoTllaE)

Understanding email addresses is hard. Why? While the first emails were sent in the '70s, to this day it's a wildly popular way to communicate. The form of how email addresses look has been continuously appended throughout the years.

This means that today, valid addresses are defined according to half a dozen different RFCs. Usually, that doesn't bother the average programmer, as servers implementing SMTP (most common email protocol today) will parse the address properly and route it to the correct destination.

The problem arises with the (relatively recent) rise of Single Sign-On (SSO). With this technology, you can sign into Website A using your account on Website B (you've probably seen a "Sign in with Google/Apple/Microsoft 365/..." option in the past).

In many cases, sites like Website A need to understand what organization the user belongs to — so they are correctly attached to and can access their organization.

The solution to this? Extract the domain part of the email address! This makes sense as it's a strong indicator for the user's organization.

However, now we might have a problem: there are two separate systems parsing the email address — the SMTP protocol (routing the address according to specifications), and a developer parsing the domain out of the email (probably with a copy-pasted regex and code).

Discrepancies between the two could easily lead to cases where a new email address is associated with a victim organization while being routed to an attacker-controlled domain — and this is what Gareth exploited. In the talk, he covered three discrepancies:

1. Unicode overflows: Adding a Unicode character to the email address whose least significant byte is a valid ASCII character you'd like to smuggle. Some implementations truncate the original Unicode byte, leading to validation bypasses.

2. Encoded-word: An interesting feature of email addresses, allowing inclusion of parts that are encoded with some charset. This feature even allows Base64 and UTF-7!.

3. Punycode: An algorithm for DNS to support domain names with special characters (even emojis). It switches and inserts characters at specific positions — a sure way to confuse parsers.

Using these three techniques along with some other niche features of email addresses, Gareth was able to access private GitLab Enterprise servers, Zendesk organizations, bypass cloud GitHub email verification, domain-protected Cloudflare instances, and even steal CSRF tokens from Joomla by embedding an XSS in registered users' email addresses!

To tie it up, Gareth focuses on methodology. It's not simple bypassing parsers you can't see, using so many different combinations of potentially vulnerable features. 

The methodology is great in general for all research; I recommend watching the talk and taking away from it.

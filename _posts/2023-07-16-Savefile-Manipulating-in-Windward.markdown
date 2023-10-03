---
layout: post
title:  "Savefile Manipulating in Windward Game"
subtitle: "Get 1 million gold quick scheme"
date:   2023-09-28 18:05:34 +0300
tags: [RE, dotnet, patching, gaming]
readtime: true
cover-img: ["/assets/images/Windward-Savefile/Windward-Savefile-Test-Rich - Copy.png"]
thumbnail-img: "/assets/images/Windward-Savefile/Windward-Savefile-Windward.png"
share-img: "/assets/images/Windward-Savefile/Windward-Savefile-Windward.png"
---

### Preface

Hey, this is the first official post in my new blog!

I've been itching for a while now to share the tech adventures I do in my free time.
The itch came after I realized how much I enjoy telling friends about these endeavors, and they seem happy listening to them (or at least they pretend well :)). So while the idea of writing publicly is a bit nerve-wracking, it's time to take the plunge and give it a shot. So, without further ado, let's embark on this journey!

## Intro

To get this started, this relatively short post takes a dive into the realm of reverse engineering, but with a unique twist – it's all about having fun with friends!

This year marks the 10th anniversary of our annual LAN party. What began as a casual suggestion a decade ago - "Hey, let's spend the weekend at my place and play some games together" - has evolved into a gathering of around 20 people. I spend the entire year preparing for it: collecting game options, selecting the final list of games, ensuring they run smoothly on the latest Windows version, and distributing them – all securely locked with a password, of course, to preserve the surprises!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-LP1-Terraria.png" title="Do you think we killed the Eye of Cthulhu?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Terraria in the 1st LAN party</i></figcaption>
</figure>

Typically, we avoid replaying games, always seeking new experiences. Admittedly, it's getting challenging to find fresh ones. However, in honor of our party's tenth anniversary, we've decided to revisit the classics – the games we enjoyed most in previous years.

The process of eliminating games was tough, there were just so many good ones! In the end, only nine remained, and among them was the infamous, highly controversial, and incredibly addictive pirate-themed game [Windward](http://www.tasharen.com/presskit/sheet.php?p=windward), which had taken our third-year party by storm.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Windward.png" title="Windward, probably the best game ever invented">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Windward Game</i></figcaption>
</figure>

## Chapter 1 - The Challenge

The last time we embarked on a Windward adventure, it was a wild journey, particularly when someone stumbled upon the option to rename towns for a fee, leading us to discover the city of "Bitches and Hoes."

But not all was smooth sailing,
1. It was impossible to play on a map that allowed us to sail the seas freely without being completely destroyed by high-level pirates.
2. The early game was burdened with extensive, solo-trading and questing expeditions across distant locations.

So, this time around, I was determined to enhance our experience by tackling these problems head-on.

Upon launching the latest version of Windward (`v.2017-06-17.0`), and generating a new world, I immediately noticed a significant change in the map generation system. It now allowed the ability to create amazing maps, such as this one designed for a co-op mission against low-level pirates, 

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Coop-World.png" title="Taking on these pirates head-on, yarr!">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Co-op Windward Map</i></figcaption>
</figure>

Or another, where two teams face off with no pirates to intrude,

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Team-Vs-Team-World.png" title="Let's go Reds!">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Team vs. Team Windward Map</i></figcaption>
</figure>

This resolved our first challenge. To surmount the second hurdle, however, I had to resort to the unthinkable: manipulating the game's savefile to gain a head start!

My goal was modest - provide everyone with a few initial levels and some extra resources, accelerating the game's pace. Thus, we venture into the realm of savefile editing.

## Chapter 2 - All the Paths Lead to Reverse Engineering

In life, one of the most valuable lessons is this: why work hard if you can just Google it? Indeed, back in 2014, a kind soul posed the question ["Is it possible to cheat and give yourself money"](https://steamcommunity.com/app/326410/discussions/0/626329186961056107/) on the Windward forums. 

Fortunately, a helpful contributor in the comments revealed a straightforward method for giving yourself money: adjust the value the comes after the resource name which is simply plaintext. Also, he hinted the value is in little-endian.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Hacker-Origins.png" title="Hacker: Origins, the true story">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A helpful individual</i></figcaption>
</figure>

I wasted no time and located the savefile, which the game automatically stores at `Documents\Windward\Players\{playerName}.player` on my Windows system. With eager anticipation, I opened it in a hex editor.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Not-Plaintext.png" title="Never feared random hex until now">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>My amazing savefile</i></figcaption>
</figure>

Alas, it was not plaintext.

As it turned out, in 2015, the game's developer made a change, rendering the savefile no longer easily accessible in plaintext. While we could revert to an older game version, that would mean sacrificing the new world editor, bringing back problem #1.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Brb-RE.png" title="They never came back :(">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>brb, reverse engineering</i></figcaption>
</figure>

So it appears that I needed to get my hands dirty.  I scheduled a meeting with a trusted friend, whose C# skills are matched only by his prowess in reverse engineering, and we embarked on this challenging endeavor.

## Chapter 3 - Gazing Into the Abyss

Much like ships sailing the vast seas, the Windwards game sails using the programming language C...sharp.
Programming languages such as C# and Java get translated to an "intermediate language" (IL) rather than being directly assembled and compiled into executables, a practice common in low-level languages.

The IL "words" are special opcodes, some even describing quite complicated operations. During runtime, these IL commands are executed by a virtual machine that interprets this unique language.

This architectural choice makes IL easier to reverse engineer: the conversion from IL back to code is notably straightforward. Furthermore, unless intentionally stripped during compilation, IL retains meaningful names and debugging information, invaluable for the process of reverse engineering.

Numerous programs do a good job reflecting (the jargon for "reversing" an IL-based language) C#. We opted for [dnSpy](https://github.com/dnSpyEx/dnSpy), a great tool for reflecting the IL used by C#.

To use dnSpy, our immediate quest was to load some file and preferably one containing the relevant code. An online search quickly revealed the treasure trove for Unity games- the `Assembly-CSharp.dll` file. Indeed, upon loading this file and inspecting classes without a namespace (distinguished by the `-` marker in dnSpy), we discovered the `GamePlayer` class. Within its cargo hold, we discovered some very interesting functions like `GiveItem`, `AwardXP`, and `Save`.

```csharp
public static void Save(bool encoded)
{
  if (string.IsNullOrEmpty(GamePlayer.mPlayerFile))
  {
    return;
  }
  // ...
  DataNode dataNode = TNManager.playerData as DataNode;
```

This `Save` function is called from another class's function, bearing a similarly descriptive name: `MyPlayer.Save`. Taking a deeper look we discovered `MyPlayer.Save` is invoked on various occasions, including `SavePeriodically`, `OnStart`, and during `FastTravel`. Makes sense.

The `dataNode` variable we see above is eventually written to the destination where I had initially found the `.player` file. This variable contains player data in the form of a `DateNode` object, alongside some additional nodes that are added during `Save`. The `DataNode` class appears to implement a hierarchical structure of nodes, each marked by a key and a value.

While constructing the object destined to be written to a file, the `Save` function checks a boolean flag, `GameConfig.saveInBinary`. This flag determines whether the file is stored using `binaryWriter` or `streamWriter`. According to dnSpy, this flag is always set to `true`. Inspecting the data that is being stored in `TNManager.playerData`, this makes sense, given that the values are often primitive data types like integers and floats.

```csharp
if (GameConfig.saveInBinary)
  {
    MemoryStream memoryStream = new MemoryStream();
    BinaryWriter binaryWriter = new BinaryWriter(memoryStream);
    // ...
    dataNode.Write(binaryWriter, encoded && GameConfig.saveCompressed);
    array2 = memoryStream.ToArray();
    // ...
  }
else
  {
    MemoryStream memoryStream2 = a StreamWriter(memoryStream2);
    StreamWriter streamWriter = new StreamWriter(memoryStream2);
    // ...
    dataNode.Write(streamWriter, 0);
    // ...
  }
```

As depicted in the code above, the `dataNote` variable implements a `Write` function, tasked with writing the `DataNode` object to the writer it's given.

At this juncture, we faced a difficult decision. We could buckle down and dive deeper into the code to fully understand the savefile's format. However, the developer's comment hinted at a big obstacle: a custom `binaryWriter` implementation, which greatly complicates static reverse engineering efforts.

To circumvent that, we could instead simply execute the code. This strategy allows pausing just before `Save` enabling manipulation of objects like the `dataNote` variable during runtime.

While my friend opted to try to go for the latter approach, I charted a different course, delving further into the code. 

Further down in the `Save` function, I noticed it concludes with a short piece of code that backs up the `.player` file in the `Documents\Windward\Backup` directory if the `dataNote` object was successfully processed. 

```csharp
if (array2 != null)
  {
    // ...
    string text = DateTime.Now.ToString("M_d_yyyy_HH");
    string text2 = Tools.GetDocumentsPath("Backup/" + text + "/" + GamePlayer.mPlayerFile);
    if (!File.Exists(Tools.FindFile(text2, false)))
    {
      Tools.WriteFile(text2, array2, false, false);
    }
  }
```

I navigated to my local `Backup` directory, retrieved one of the early `.player` files, and to my astonishment, I had a plaintext `.player` file in all its glory!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Plaintext_1.png" title="What does it say down there? Hmm...">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Our player Savefile, completely plaintext!</i></figcaption>
</figure>

So what happened here? Why is the file in (sort of) plaintext? Well, it seems that when a player is first created, the game calls `Save` with the `encoded` parameter being `false`. Only afterward is the `Save` function called again with `encoded` set to `true`. While the standard `.player` file is overwritten, the Backup file remains unchanged (thanks to the `File.Exists` check), preserving its plaintext form.

But isn't there a custom `binaryWriter` implementation? Well, inspecting `DataNode.Write`, we found this code:

```csharp
public void Write(BinaryWriter writer, bool compressed = false)
  {
    if (compressed)
    {
      LZMA lzma = new LZMA();
      lzma.BeginWriting().WriteObject(this);
      byte[] array = lzma.Compress();
      if (array != null)
      {
        for (int i = 0; i < 4; i++)
        {
          writer.Write(DataNode.mLZMA[i]);
        }
        writer.Write(array);
        return;
      }
    }
    writer.WriteObject(this);
    // ...
  }
```

The code doesn't do anything special. It simply writes 4 bytes (`CD01`) using the static `mLZMA` class member and then the `DataNode` object follows, compressed using [the LZMA algorithm](https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Markov_chain_algorithm). The outcome is then simply written to the built-in `BinaryWriter`.

So by taking any non-plaintext `.player` savefile, removing the first 4 bytes, and then uncompressing (I used `$ lzma -d {playerName}.player`), we get an output file identical to the file found in that backup folder.

Now we know what the developer changed: they added compression on top of the savefile, making it harder to analyze or edit without reverse engineering. 

Finally, as you can notice, the so-called "plaintext" is, in fact, a `DataNode` object. This object comprises nodes identified by string keys (which is what we see and can easily read), each carrying a value of varying types.

## Chapter 4 - It's (Almost) Patchin' Time!

As we now know, the file is simply a `DataNode` object saved using a `BinaryWriter`. After figuring this out, we dove into the intricacies of how such an object is saved to a file. 

It seems to follow a straightforward pattern: key names starting with their length, followed by the string key itself. Then, there's a type indicator for the value which comes right after. Nodes are separated using a null byte. We also found that list-type values have their elements separated by a null byte as well.

Below are several examples illustrating this format:

```
04         || 74 6F 77 6E || 07         || 09         || 43 61 73 65 6E 76 69 65 77
key length || t  o  w  n  || type (str) || str length || C  a  s  e  n  v  i  e  w
```

```
04         || 77 6F 6F 64 || 14         || 22 00 00 02
key length || w  o  o  d  || type (int) || 4-byte int
```

```
07         || 55 6E 6C 6F 63 6B 73 || 00          || 05          || 10             || 53 6C 6F 6F 70 ... || 00                || ...
key length || U  n  l  o  c  k  s  || type (list) || list length || element length || S  l  o  o  p  ... || element seperator || ...
```

This format allows us to quite easily manipulate the file's content! We had an immediate question: will Windward accept a plaintext `.player` file? If it does, we can make patching an easy process.

Carefully taking the `wood` key's value (`22 00 00 02`), copying it to the value of the `stone` key, placing the edited `.player` file in the right place, and opening a new game loading the edited profile in the process...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Test-Before.png" title="Can't wait for the next one...">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Before editing the .player file</i></figcaption>
</figure>

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Test-After.png" title="Worth it">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>After editing the .player file</i></figcaption>
</figure>

The experiment was a success! We now also have an increased amount of 50 stone :) To ensure Windward consistently loaded the new edit file every time, we removed all instances of the original `.player` file in various save locations. I would later discover that simply changing the name of the file works. At the time I was worried that the name was verified in some way using the file's content.

So now our goal is in sight: let's figure out how to give us heaps of gold...Let's say, a million?

Recalling the previous test, something struck us as odd. Why the hell did the value `22 00 00 02` in the Wood and Stone keys correspond to `50`? And why does `20 22 00 00` results in `100` Gold? Furthermore, we observed other integer values in the file were saved with type `04`, while all resources used type `14`. Very odd indeed.

Despite making multiple tests, changing resource values, and seeing in-game results, we couldn't discern a pattern.  

Another weirdness, we noticed that the player's XP was not present in the save file although the `GamePlayer` class had an attribute for it.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Test-Weird.png" title="Do you think that's enough powder?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Playing around with values</i></figcaption>
</figure>

Our journey into understanding Windward's savefile format raised more questions than answers, leaving us eager to uncover the mystery.

## Chapter 5 - Unmasking the Obfuscation

Back into the depths of dnSpy, we set our sights on code segments that deal with resources. Eventually, we landed at the `MyPlayer.SetResource` function:

```csharp
public static void SetResource(string name, int val)
  {
    DataNode playerDataNode = TNManager.playerDataNode;
    DataNode dataNode;
    if (GlobalManager.assemblyMods.size != 0)
    // ...
    else
    {
      dataNode = playerDataNode.GetChild("Resources", true);
    }
    dataNode.SetChild(name, new ObsInt(val));
    MyPlayer.syncNeeded = true;
    MyPlayer.saveNeeded = true;
  }
```

As you can see, this function takes the `Resources` node and assigns it as a child using the `name` parameter with the new value determined by `val`. But here's the twist: instead of using the primitive `int` type of `val` as we expected, it used `ObsInt`.

Jumping over to the `ObsInt` class, we immediately unveiled the secret - it employs two functions named `Obfuscate` and `Restore` to transform ordinary integers into the `ObsInt` type:

```csharp
    private static int Obfuscate(int x)
    {
      int num = (x ^ (x >> 7)) & 5570645;
      int num2 = x ^ num ^ (num << 7);
      num = (num2 ^ (num2 >> 14)) & 52428;
      return num2 ^ num ^ (num << 14);
    }

    private static int Restore(int y)
    {
      int num = (y ^ (y >> 14)) & 52428;
      int num2 = y ^ num ^ (num << 14);
      num = (num2 ^ (num2 >> 7)) & 5570645;
      return num2 ^ num ^ (num << 7);
    }
```

To confirm our suspicion, we translated this code to Python and applied it to `Restore(0x02000022)` (converting `22 00 00 02` to little-endian). Lo and behold, it returned `50`!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Restore.png" title="The magic of XORing stuff">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Uncovering the obfuscation</i></figcaption>
</figure>


Concluding with a bang, we executed `Obfuscate(1000000)` and obtained the result (`08 28 89 10` after converting to little-endian). With this knowledge, we patched our save file, and...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Test-Rich.png" title="Feeling like Scrooge McDuck here">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>We're rich!</i></figcaption>
</figure>

During the second dnSpy expedition, we discovered that the player's experience points also resided within the `Resources` list. Our initial file lacked it as our player was a noob with 0 XP. So, we patched the `Resources` list to contain 5 elements instead of 4, and introduced one at the beginning named `xp`, and gave ourselves a staggering 1 million XP - catapulting our player to level 83!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Test-Level-83.png" title="I totally have 4000 hours on this game">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Not a noob anymore</i></figcaption>
</figure>

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile/Windward-Savefile-Final-Patches.png" title="Proud of you for getting this far">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The final patched file</i></figcaption>
</figure>

As evident in the patched file above, we adjusted the `Resources` list's length to `5`, added a key length of `2`, and the key name `xp`, accompanied by the obfuscated 1 million value. You can also see here the edited gold and the rest of the resource values marked.

Satisfied and elated, we crafted the ultimate savefile, granting everyone ample coins for ship upgrades and some good equipment, a substantial XP boost to start at level 5, and onwards we sailed towards the LAN party!
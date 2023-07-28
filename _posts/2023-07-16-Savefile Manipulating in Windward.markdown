---
layout: post
title:  "Savefile Manipulating in Windward Game"
subtitle: "A story of getting 1 million gold in a single click"
date:   2023-07-16 18:05:34 +0300
tags: [RE, dotnet, patching, gaming]
readtime: true
cover-img: ["/assets/images/Windward-Savefile-Test-Rich - Copy.png": "Spoiler alert"]
---

### Preface

Hey, this is the first official post in my new blog!
For a while now I've been having this itch of putting online some record of the tech stuff I'm doing in my free time.
I mean, I like telling friends about these, and (it seems that, at least) they like listening to them, so while it's pretty frightening writing publicly, it's time to tear off the bandage and give it a try. Here goes!

## Intro

Starting relatively mildly, this (short-ish) post has to do with reverse engineering. The best kind of reverse engineering - one resulting in having fun with friends!

This year our annual LAN party will take place for the 10th time. It started a decade ago with someone asking "Hey, let's spend the weekend at my house and play some games together", and ended up being a 20ish-people event I'm preparing the entire year for: making preparations, choosing games for the upcoming event, testing that they still work on the latest Windows version, and finally distributing them (compressed with a password, so to not ruin the surprise, of course!).

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-LP1-Terraria.png" title="Do you think we killed the Eye of Cthulhu?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Terraria in the 1st LAN party</i></figcaption>
</figure>

Normally, we refrain from playing the same game twice - only new games! (I'd lie if I said that we aren't scraping the barrel at this point). However, to celebrate the round number of this year's party, we decided to run a "best-of" theme, playing games we had most enjoyed in the previous years.

The process of eliminating games was tough, there were just so many good ones! In the end, just 9 reamined, and out of them was the infamous, very controversial, highly addictive, pirate-y [Windward](http://www.tasharen.com/presskit/sheet.php?p=windward), the game that took the 3rd-year party by storm.


<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Windward.png" title="Windward, probably the best game ever invented">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Windward Game</i></figcaption>
</figure>

## Chapter 1 - The Challenge

The last time we played Windward, we had a blast, especially when someone discovered you can pay money to change town names, leaving us to discover the great city of "Bitches and Hoes".

But not all was gold,
1. It was impossible to play on a map that allows us to sail the seas without being completely destroyed by high-level pirates.
2. The early game consisted of too much long and lonely trading and questing expeditions taking us to different areas.

So, this time around, I vowed to make the experience better by making sure these problems were resolved.

Launching the recent version of Windward (`v.2017-06-17.0`), and creating a new world, I immediately noticed that the map generator was completely overhauled, giving you the ability to create great maps, like this one, where it's a co-op mission against level 3 pirates, 

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Coop-World.png" title="Taking on these pirates head-on, yarr!">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Co-op Windward Map</i></figcaption>
</figure>

Or this one where it's simply team VS team, no pirates allowed,


<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Team-Vs-Team-World.png" title="Let's go Reds!">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Team vs. Team Windward Map</i></figcaption>
</figure>

So this solves the first problem. For the second one (and also to make sure that we can extend the map further and take on higher-leveled pirates), we have to do the unthinkable: manipulate our savefile to give us a jumpstart!

I don't aspire to do a lot, only give everyone few initial levels and some extra resources, so the game kicks into a higher gear quickly. Thus, off we go to edit our savefile.

## Chapter 2 - All the Ways Lead to Reverse Engineering

The most important rule I learned so far in life is why work hard if you can just Google it, and indeed, some lovely person asked ["Is it possible to cheat and give yourself money"](https://steamcommunity.com/app/326410/discussions/0/626329186961056107/) on the Windward forums on 2014. 

Fortunately, one helpful individual in the comments pointed out that editing your savefile is as simple as changing the value after the resource name appears, and that it's in little-endian.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Hacker-Origins.png" title="Hacker: Origins, the true story">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>A helpful individual</i></figcaption>
</figure>

Jumping straight into the action, I opened the savefile (automatically saved at `Documents\Windward\Players\{playerName}.player` on my Windows system), opened it in a hex editor, and...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Not-Plaintext.png" title="Never feared random hex until now">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>My amazing savefile</i></figcaption>
</figure>

It's not plaintext.

Seems that in 2015 the developer of the game changed it so the savefile is no longer in plaintext. We can go to an older version of the game, but this means no new world editor, reintroducing problem #1. 

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Brb-RE.png" title="They never came back :(">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>brb, reverse engineering</i></figcaption>
</figure>

So looks like we're going to have to get our hands dirty. I set up a date with a good friend whose C# skills only rival his reversing expertise, and we got down to business.

## Chapter 3 - Staring Into the Abyss

Alike games made in Unity, Windward is written in C#. Programming languages like C# and Java get translated to an "intermediate language" (IL) instead of being assembled and compiled directly into an executable like many low-level languages such as C. 

The IL resembles a combination of assembly opcodes and more complicated operations and during runtime, the IL commands are executed by a virtual machine (VM) that "speaks" that language.

Due to this architecture, IL is often much easier to reverse engineer: the IL -> code conversion is more direct, additionally by default, many indicative names are still present in the IL, unless actively removed during compilation.

Many programs do a good job reflecting (the jargon for "reversing" an IL-based language) C#, and we chose to use [dnSpy](https://github.com/dnSpyEx/dnSpy), an awesome tool for working with .NET assemblies.
Opening dnSpy, we need to load a file and preferably one that contains the interesting code. A quick search online reveals that for Unity games, you want to take a look inside an `Assembly-CSharp.dll` file. Indeed, loading this file and looking for classes that do not belong in a namespace (marked by `-` in dnSpy), we find the `GamePlayer` class, and within some interesting functions like `GiveItem`, `AwardXP`, and `Save`.

```csharp
public static void Save(bool encoded)
{
  if (string.IsNullOrEmpty(GamePlayer.mPlayerFile))
  {
    return;
  }
  if (!TNManager.isConnected)
  {
    return;
  }
  // ...
  DataNode dataNode = TNManager.playerData as DataNode;
```

The `Save` function is called by a similarly-named function from a different class, `MyPlayer.Save`. Taking a look at its uses, it seems to be called on several occasions, like `SavePeriodically`, `OnStart`, `FastTravel` and others. Makes sense so far.

The `dataNode` variable we see above is eventually written to the path  where we found the `.player` file. The variable contains the player data as a `DateNode` class, alongside some additional nodes that are being added to it during `Save`. The `DataNode` class seems to implement a tree of nodes, each node having a key and a value.

While constructing the object that is saved to file, the `Save` function checks a boolean value indicating whether to store the file in Binary, named `GameConfig.saveInBinary`. According to dnSpy, this is always `true`, and this means that the player object is written, after being [`LZMA` compressed](https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Markov_chain_algorithm) (if the parameter `encoded` is `true`), using the built-in `BinaryWriter` class.

```csharp
if (GameConfig.saveInBinary)
    {
      MemoryStream memoryStream = new MemoryStream();
      BinaryWriter binaryWriter = new BinaryWriter(memoryStream);
      dataNode.SetChild("h0", hashCode);
      dataNode.SetChild("h1", hashCode2);
      dataNode.SetChild("h2", (networkInterfaces.size <= 0) ? 0 : networkInterfaces[0].Id.GetHashCode());
      dataNode.Write(binaryWriter, encoded && GameConfig.saveCompressed);
      array2 = memoryStream.ToArray();
      // ...
    }
else
  {
    MemoryStream memoryStream2 = new MemoryStream();
    StreamWriter streamWriter = new StreamWriter(memoryStream2);
    dataNode.SetChild("h0", hashCode);
    dataNode.SetChild("h1", hashCode2);
    dataNode.SetChild("h2", (networkInterfaces.size <= 0) ? 0 : networkInterfaces[0].Id.GetHashCode());
    dataNode.Write(streamWriter, 0);
    array2 = memoryStream2.ToArray();
    // ...
  }
```

At this point, we decided to split up. My friend was trying to make this code execute, so we can breakpoint just before writing and analyze ways we can play with the `.player` file, or maybe use `BinaryReader` in a code of our own to open the save file, and I was just wondering around, looking for a different way to overcome this problem.

And indeed, something caught my eye - the `Save` function ends with a short code that backs up the `.player` file into a `Documents\Windward\Backup` directory, if it was successfully processed before. The important thing here is that it backs up whether the player object was saved to file in binary or not.

```csharp
if (array2 != null)
  {
    // ...
    Tools.WriteFile(Tools.GetDocumentsPath(GamePlayer.mPlayerFile), array2, false, false);
    Tools.WriteFile(Tools.GetDocumentsPath(GamePlayer.mVaultFile), array, false, false);
    string text = DateTime.Now.ToString("M_d_yyyy_HH");
    string text2 = Tools.GetDocumentsPath("Backup/" + text + "/" + GamePlayer.mPlayerFile);
    if (!File.Exists(Tools.FindFile(text2, false)))
    {
      Tools.WriteFile(text2, array2, false, false);
      text2 = Tools.GetDocumentsPath("Backup/" + text + "/" + GamePlayer.mVaultFile);
      Tools.WriteFile(text2, array, false, false);
    }
  }
```

I ran straight to my local `Backup` directory, loaded up one of the early `.player` files I found, and lo and behold - we have a plaintext `.player` file!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Plaintext_1.png" title="What does it say down there? Hmm...">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Our player Savefile, completely plaintext!</i></figcaption>
</figure>

## Chapter 4 - It's (Almost) Patchin' Time!

Getting to the nitty-gritty of the file format, it seems to follow a simple way to save any node in the `DataNode` tree: it starts with the length of a key name, then the key name string, and immediately afterward the value which can be one of some possible types, but all behave similarly - a type indicator and then the value. Different nodes or values in a list are separated using a null byte. Let's take a look at a few examples:

```
04         || 74 6F 77 6E || 07         || 09         || 43 61 73 65 6E 76 69 65 77
key length || t  o  w  n  || type (str) || str length || C  a  s  e  n  v  i  e  w
```

```
04         || 77 6F 6F 64 || 14         || 22 00 00 02
key length || w  o  o  d  || type (int) || 4-byte int
```

```
07         || 55 6E 6C 6F 63 6B 73 || 00          || 05          || 10             || 53 6C 6F 6F 70 ... || 00
key length || U  n  l  o  c  k  s  || type (list) || list length || element length || S  l  o  o  p  ... || element seperator
```

Not that complicated, we can change stuff at will! But the immediate question was something else: will the game even accept a plaintext `.player` file? If it does, we can simply patch the one we have. 

I did a careful test by taking the value of the `wood` key (`22 00 00 02`), putting it as the value of the `stone` key, deleting all my saves and putting the edited `.player` file in their place, and...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Test-Before.png" title="Can't wait for the next one...">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Before editing the .player file</i></figcaption>
</figure>

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Test-After.png" title="Worth it">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>After editing the .player file</i></figcaption>
</figure>

Success! We now also have 50 stone :) 

For the next couple of tests, to make sure Windward loads the new file every time, I made sure to remove all instances of the `.player` file in all save locations before inserting the patched one. Later on, I would discover that simply changing the name of the file works, but I was worried that this value is verified in some way against the file's content.

Moving on, I immediately went ahead and tried to give myself 1 million gold. Wait...how do I do that?

Recalling the previous test, why the hell did the value `22 00 00 02` correspond to `50` Wood and Stone? And why does `22 00 00 02` give `100` Gold? Another strange behavior is that other integer values were saved with type `04` (like the `h0` key), so howcome all the resources have `14`?

Many questions, but they all boil down to understanding howcome `22 00 00 02` equals 50. We made some tests, like changing resource values and seeing the result inside the game, gathering more data points. But no pattern we could comprehend emerged. 

Also, at some point we noticed that the amount of XP the player has doesn't appear on the save file. At least, there's no key with this name, but the `GamePlayer` class does have this attribute...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Test-Weird.png" title="Do you think that's enough powder?">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Playing around with values</i></figcaption>
</figure>

## Chapter 5 - Obfuscation and Real Patchin' Time!

Back to dnSpy we go. We decide to look at pieces of code that deal with resources, and eventually landed at the `MyPlayer.SetResource` function,

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

As you can see, this function accepts the name of the resource as the `name` parameter and sets a child with this name under the `Resources` node, but not as an `int` as we expected, but as an `ObsInt`.

Jumping over to the `ObsInt` class, we immediately see what's going on: it uses two functions called `Obfuscate` and `Restore` to transform normal integers to the `ObsInt` type:

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

To verify our suspicion, we copied this code to Python and found that `Restore(0x02000022)` (using the "little-endian" hint to convert `22 00 00 02` to this input), returns `50`!

Finishing with a bang, we executed `Obfuscate(1000000)`, got the result (`08 28 89 10`, after converting to little-endian), patched our save file, and...

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Test-Rich.png" title="Feeling like Scrooge McDuck here">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>We're rich!</i></figcaption>
</figure>

During the second dnSpy review, we discovered that `xp` is also contained within the `Resources` list, and our file didn't have it because the player we worked on was a noob with 0 XP. We patched the `Resources` list to contain 5 elements, and added one at the beginning with the key name `xp`, and gave ourselves 1 million XP - straight to level 83 we go :)

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Test-Level-83.png" title="I totally have 4000 hours on this game">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Not a noob anymore</i></figcaption>
</figure>

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Windward-Savefile-Final-Patches.png" title="Proud of you for getting this far">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The final patched file</i></figcaption>
</figure>

As you can see in the patched file above, we had to change the `Resources` list's length to `5`, added a key length of `2` and the text `xp`, with the 1 million value. You can also see the edited gold, and the rest of the resource values marked as well.

So, happy and satisfied, we created the final version of the file, granting everyone enough coins to start the game with a ship upgrade or get some good equipment, a hefty chunk of XP to start at level 5, and onwards we go to the LAN party!
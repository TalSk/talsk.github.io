---
layout: post
title:  "The Secrets of Javascript"
subtitle: 'An unusual take on the stupidity of Javascript'
date:   2024-04-12 21:37:34 +0300
tags: []
readtime: true
cover-img: ["/assets/images/Stupid-Javascript/Cover.png"]
thumbnail-img: "/assets/images/Stupid-Javascript/Thumbnail.png"
share-img: "/assets/images/Stupid-Javascript/Share.png"
---

# Intro

If you've messed around long enough with web development, you probably watched or read about how Javascript tends to behave oddly in many, many cases.

// Image of the famous talk

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Javascript-Stupid/Javascript-Stupid-wat.png" title="https://www.youtube.com/watch?v=EtoMN_xi-AM">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The amazing <a href="https://www.destroyallsoftware.com/talks/wat">Wat talk</a></i></figcaption>
</figure>

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Javascript-Stupid/Javascript-Stupid-meme.png" title="Cause an array is actually an object (i.e dictionary), whose keys are the indices, which `in` uses">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Why does this happen?</i></figcaption>
</figure>

Javascript, being a scripting language, has to interpret code on the fly - it doesn't validate or verify the written code beforehand, besides basic syntactic checks. As a byproduct, the language has evolved to accept basically any expression that matches Javascript's very simple syntax requirement.

While this made Javascript very flexible, this caused the engine coders to make tough decision when it came to parsing expressions. 

For instance, how should unary operators (that work on single operand) operate on different operand types? What happens when you add objects for which addition doesn't really make sense? And what kind of strings should `parseInt` accept?

We will answer these questions soon (and explain the "why" behind the result), but just consider that not matter what, since Javascript's lax syntatic rules, the language was bound to behave weirdly on one edge-case or another - so that shouldn't surprise us as much as it does.

The bottom line is that these quirks made Javascript the laughingstock for strong-typed language enthusiasts, though this didn't stop JS from becoming the [most used languages according to recent Stackoverflow survey](https://survey.stackoverflow.co/2023/#most-popular-technologies-language) and [topping the list of the programming language used in new Github repositories(https://octoverse.github.com/2022/top-programming-languages).

Moreover, these quirks Javascript fans to create some really magical things, and this the focus for this short blog post: we'll explore these oddities while showing how it is possible to write *any program we want using just 6 different characters: `(`, `)`, `[`, `]`, `!` and `+`*!

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Javascript-Stupid/Javascript-Stupid-jsfuck.png" title="It's a beauty!">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>[JSFuck](https://en.wikipedia.org/wiki/JSFuck) in action</i></figcaption>
</figure>

Note: while reading this post, I encourage you to open the console (F12 on most browsers) and run the scripts given here yourself, play around a little and see if you can achieve the next step yourself.

## Part 0 - Problem Overview

So we have a weird mission - supporting executing any program with just 6 symbols. 

Our program will accept a string expressing any valid Javascript code, and output a script using just these 6 symbols which, when executed, produces the exact same result as the original code.

But, how is that possible? The input can contain many symbols we don't have. All the alphabet, for starters.

Let's imagine we're somehow able to run the [`eval`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/eval) function. If we could construct a string identical to the code given to us , we'll just call `eval` on that string and we're done!

Well, easier said than done - this means we'll need to somehow create every possible valid Javascript symbol using our 6 symbols before concatinating them.

But how will we do that? The basic idea is that we'll create various Javascript built-in objects, cast them to string by calling their built-in `toString` function, and then take specific characters out of these strings by index to slowly gather an inventory of all valid Javascript symbols.

Given a string `"Some String"`, we have brackets in our allowed symbols which can be used to select a single character out of this string. However, we need numbers for that which we don't have. So, they will be our initial goal.

## Part 1 - Generating Numbers

The plus operator (https://262.ecma-international.org/#sec-addition-operator-plus) in Javascript is a bit weird. 

The reason behind it is that it's actually behaves differently depending on if it's being used with two operands or one (called the [unary plus operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Unary_plus)).

The difference comes since each of these operands does its best to produce a meaningful output by following a [specific set of rules](https://262.ecma-international.org/#sec-applystringornumericbinaryoperator) telling it what to do on its operands to convert them to something which makes sense to operate on (usually strings or numbers).

As a rule of thumb, this works well, but sometimes it just doesn't:

```js
true + true; // Outputs 2
"b" + "a" + +"a" + "a"; // Outputs `baNaNa`
[] + [] // Outputs '' (empty string)
{} + [] // Outputs 0
[] + {} // Outputs '[object Object]'
```

A weird set of results for sure. Let's go over them one by one and understand what the plus operator is doing:

- `true + true` - Boolean values are to be converted to numbers by applying `Number` on them. `Number` returns 0 on "falsy" objects, and 1 on "truthy" objects (this properly is determined by whether `if <object>` is picked or not). `true` is unsurprisingly "truthy", so here we get the result of `2`.

- `"b" + "a" + +"a" + "a"` - Let's put parenthesis first: `((("b" + "a") + (+"a")) + "a")`. When the two operands are strings the plus operator simply concatenats them. The only thing which isn't a string here is `(+"a")`. The unary operator [always applies `Number`](https://262.ecma-international.org/#sec-unary-plus-operator) on its operand. In this case, `"a"` cannot be converted to the default base-10 number, so `toNumber` rightfully returns `NaN` (an object represnting something which is not a number). Then the next plus sign has to evaluate `"ba" + NaN`. Since one operand is a string, the plus sign forces a call to `toString` on `NaN`, which unsurprisingly results in (the string) `"NaN"`. Now all the plus signs can happily concatanate the rest of the values to get `baNaNa`.

- `[] + []` - Due to some design choices, the primtive value of an empty array is a string, thus `toString` is applied on both `[]`s. This returns an empty string, which concatanated together to results in an empty string again.

- `{} + []` - Now this is a matter of syntax: Javascript interprets this expression as an empty code block first (`{}`, which does nothing), and then `+[]`. As we saw, the unary operator applies `Number`, since an empty list is "falsey", this evaluates to `0`.

- `[] + {}` - Funnily, the different interpretation compared to the last expression shows that addition is not commotative in Javascript. The primitive value of an empty object is also a string, so `toString` is called on both sides, which returns an empty string for the empty array and `"[object Object]"` for the empty object.

Okay, so everything mostly makes sense now. How can we use that to generate numbers?

First, we already saw how to generate one number from symbols we have - `+[]` evaluates to 0.

We can theoretically keep using `++` on the result to get more numbers, but executing `(+[])++` returns a weird syntax error - `invalid increment/decrement operand`. 

That's because Javascript doesn't evaluate parenthesis first like in a normal arithmetic expression, so we'll need to use trick named "Array Wrapping": we can put any expression within an array (`[]`) to force JS to evaluate it. Then, we just pick the result out of the length-1 array the expression produced using the 0 index (a number which we can already produce).

So `[ +[] ] [ +[] ]` will successfully evaluate to 0 (because we get `[0][0]` after evaluation), and by applying the increment operator, 

```js
++ [ +[] ][ +[] ] // Outputs 1!
```

By continously using the array wrapping trick, we can get any number we want to!

```js
        ++ [ +[] ][ +[] ] // Outputs 1
    ++ [++ [ +[] ][ +[] ]][ +[] ] // Outputs 2
++ [++ [++ [ +[] ][ +[] ]][ +[] ]][ +[] ] // Outputs 3
// And so on...
```

# Part 2 - Generating the Alphabet

Strings, as we know, are simply arrays of characters. Using the numbers we just found how to create, together the index operator and a string, we can pick characters for our use, and then also concatenate them using our plus sign.

But how would we get such strings? In the previous section, we already found that `[] + {}` outputs the string `"[object Object]"`, so if we use the wrapping trick together with generating numbers,

```js
[ [] + {} ]           [ +[] ] [ ++ [ +[] ][ +[] ] ] // Evaluates to...
[ "[object Object]" ] [ 0 ]   [ ++ [ +[] ][ +[] ] ] // Evaluates to...
  "[object Object]"           [ ++ [ +[] ][ +[] ] ] // Evaluates to...
  "[object Object]"           [ 1 ] // Evaluates to "o"!
```

Since we can generate any number we want to, we have in our inventory the letters
```js
["O", "b", "c", "e", "j", "o", "t"]
```

Using another small quirk of JS:

```js
[][+[]] // Evaluates to undefined
```

This happens because we trying to get the first element of an empty array.

We know that it's enough that one side of the addition is a primitive string, so by adding `undefined` to an empty array, we get: 

```js
[][+[]] + [] // Outputs "undefined" (the string)
```

Which unlocks more charactes!

```js
["O", "b", "c", "d", "e", "f", "i", "j", "n", "o", "t", "u"] // Our inventory so far
```

Up to this point, we only used 5 out of our 6 symbols. It's time to take the not operator out of the bag`!`.

Like the unary addition operator allowed us to cast things as numbers, the unary not operator will [let us cast things as booleans](https://262.ecma-international.org/#sec-logical-not-operator), so:

```js
![] // Outputs false
!![] // Outputs true
```

With the trick of converting things to strings using an empty array, 

```js
![] + [] // Outputs "false"
!![] + [] // Outputs "true"
```

And we also unlock the characters "a", "l", "r" and "s".

```js
["O", "a", "b", "c", "d", "e", "f", "i", "j", "l", "n", "o", "r", "s", "t", "u"] // Our inventory so far
```

That's nice! At this point, however, we're a bit stuck with generating further strings for letters. What now?

### Part 2.1 - Object's methods

They say that in Javascript, "everything's an object". And that's right, everything(\*) in Javascript "inherits" from the `Object` object, whilst adding more methods on top of the already-existing ones from `Object`

Usually, one accesses any Javascript object's methods by the dot operator, for instance, `[].toString()` will access the `toString` method of the `Array` object and call it. Thankfully, since objects are glorified dictionaries, methods can also be accessed by using our lovely index operator! So:

```js
[]["toString"]() // Returns empty string, just like [].toString()
```
Let's take a look at the long list of methods `[]` has, and *find* one we can build with our existing inventory: `find`! (see what I did there?):

```js
[][
    [[][+[]]+[]][+[]] [++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[+[]][+[]]]
  + [[][+[]]+[]][+[]] [++[++[+[]][+[]]][+[]]]
  ] // Evaluates to...

[][
    [[][+[]]+[]][+[]] [4] 
  + [[][+[]]+[]][+[]] [5] 
  + [[][+[]]+[]][+[]] [1]
  + [[][+[]]+[]][+[]] [2]
  ] // Evaluates to...

[][
    ["undefined"][0] [4] 
  + ["undefined"][0] [5] 
  + ["undefined"][0] [1]
  + ["undefined"][0] [2]
  ] // Evaluates to...

[]["f"+"i"+"n"+"d"] // Evaluates to `function find()`
```

So we can access the `find` function. Using the same trick as before to force-call `toString` on the function, `[]["f"+"i"+"n"+"d"] + []`, we get

```js
[][
    [[][+[]]+[]][+[]] [++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[+[]][+[]]]
  + [[][+[]]+[]][+[]] [++[++[+[]][+[]]][+[]]]
  ] + [] // Outputs:

// "function find() {
//    [native code]
// }" 
```

While this is a long, new string output, we didn't unlock new letters but rather some useful symbols (which we'll need anyway, eventually).

```js
["O", "a", "b", "c", "d", "e", "f", "i", "j", "l", "n", "o", "r", "s", "t", "u", "(", ")", "[", "]", "{", "}"] // Our inventory so far
```

Let's utilize the same idea to *find* more methods of primitive objects we have access to! We're limited to methods whose name that we can *construct* using our existing inventory. One of which is...`constructor`! (see what I did there? #2)

```js
[][
    [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]
  + [[][+[]]+[]][+[]][++[+[]][+[]]]
  + [![]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][+[]]
  + [[!![]][+[]]+[]][+[]][++[+[]][+[]]]
  + [[!![]][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][+[]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][++[+[]][+[]]]
  ] + // Evaluates to...

[][
    "c"
  + "o"
  + "n"
  + "s"
  + "t"
  + "r"
  + "u"
  + "c"
  + "t"
  + "o"
  + "r"
  ] // Evaluates to...

[]["constructor"] // Evaluates to `function Array()...`


// Likewise...

""["constructor"] // Evaluates to `function String()...`
false["constructor"] // Evaluates to `function Boolean()...`
0["constructor"] // Evaluates to `function Number()...`
[]["find"]["constructor"] // Evaluates to `function Function()...`
[{}][0]["constructor"] // Evaludates to `function Object()...`
```

Converting these to strings (yet again using `+ []`), will net us the letters `A`, `B`, `F`, `N`, `S`, `m`, `g`, and `y`.

```js
["A", "B", "F", "N", "O", "S", "a", "b", "c", "d", "e", "f", "g", "i", "j", "l", "m", "n", "o", "r", "s", "t", "u", "y", "(", ")", "[", "]", "{", "}"] // Our inventory so far
```

Almost there, just a few more letters left...

### Part 2.2 - Object's Methods (Again)

Using `constructor`, we utilized access to an object's method as a way to get their primitive constructor as a string to get more letters.

Once we used up all primitives, this idea leads to a dead-end. 

But if you recall our first example of accessing the object's methods above, we used parenthesis (which the restricton allows us to use) to *call* the method. How can we utilize this to get more letters?

Another method we can construct using our current inventory is `toString`. When used as a method of a `Number`, it will try and smartly convert it to a string. Luckily, `toString` accepts an argument telling it with which base to parse the number with.

So, taking the number `10` for example, and converting it to a string using base-16, will give us the string `a`:

```js
10["toString"](16) // Outputs "a"
```

As with base-16 encoding the needed 6 values beyond 9 using the letters *a,b,c,d,e,f*, it's natural for higher bases to continue this way. Once we reach base-36 (10 + 26), we run out of letters, but all we care about here is to get the missing letters: if we want to get the letter "h" we're missing, we'll *just* evaluate the `17["toString"](36)` expresison, which, when created using our methods, looks a bit more frightening:

```js
[   ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]
  + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
  + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
  + (++[++[+[]][+[]]][+[]])][+[]] 
  [
    [[!![]][+[]]+[]][+[]][+[]] // t
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]] // o
  + ([[]+[]][+[]][[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[![]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][+[]]+[[!![]][+[]]+[]][+[]][++[+[]][+[]]]+[[!![]][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][+[]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][++[+[]][+[]]]]+[])[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]+(++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]])] // S
  + [[!![]][+[]]+[]][+[]][+[]] // t
  + [[!![]][+[]]+[]][+[]][++[+[]][+[]]] // r
  + [[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]] // i
  + [[][+[]]+[]][+[]][++[+[]][+[]]] // n
  + ([[]+[]][+[]][[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[![]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][+[]]+[[!![]][+[]]+[]][+[]][++[+[]][+[]]]+[[!![]][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][+[]]+[[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[!![]][+[]]+[]][+[]][++[+[]][+[]]]]+[])[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]+(++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]) + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])] // g
  ]
  (
      ++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] 
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
    + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])][+[]]
  ) // Evaluates to...

[   ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]
  + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
  + (++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])
  + (++[++[+[]][+[]]][+[]])][+[]]
["toString"](
  ++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] + ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] + ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] + ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] + ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]+ ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] + ++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]] ][+[]]
  ) // Evaluates to...

17["toString"](36) // Outputs "h"
```

(Try to run the first expression yourself)

Success! We can generate all of the lowercase alphabet now (and some extras)

```js
["A", "B", "F", "N", "O", "S", "a-z", "(", ")", "[", "]", "{", "}"] // Our inventory so far
```

# Part 3 - Finalizing Our Inventory

There are some bits and pieces left to fill our inventory of every possible valid symbol for Javascript. I won't go through the details of getting each of them, but here's some in high level:

1. Getting `<`, `>`, `=`, `"`, `/` by abusing CSS exposed to us via Javascript:

```js
"a"["fontsize"]() // Outputs "<font size="undefined">a</font>"
```

2. Getting `.` and `+` by playing with exponents:

```js
+(11e20)+[] // Outputs "1.1e+21"
```

3. Using our ability (using `constructor`) to get the functions `String`, `Function` and `Object`, let's get `U` and `C`
```js
(Object()["to"+String["name"]]["call"]()) // Outputs "[object Undefined]" 
Function("return escape")()(("")["italics"]()) // Outputs "%3Ci%3E%3C/i%3E"
```

4. Now, using the capitals `U` and `C`, we can call `toUpperCase` on any of the lowercase letters we already have to produce the rest of the capital letters.

There are some more valid symbols in a Javascript code missing from our inventory, but at this point you get the jist and trust me that we can produce anything!

# Part 4 - Evaluating Code

If you remember, we assumed at teh beginning that after we create a given program as a string using our 6 symbols, we can simply call `eval` to execute it.

However, we can't *simply* do that, and have to use our 6 symbols yet again to do that, instead. Luckily, it's pretty straightforward and the above techniques already allude to the method:

```js
[]["find"]["constructor"] // Returns function Function()
````

The above results in us getting a refernce to `Function`, which is a nice method that accepts a string, and returns an anonymous function that executes this string, essentially letting us use `eval` on the string. So, given some code as a string, let's say, `alert(1)`, we can do:
 
```js
[]["find"]["constructor"]("alert(1)")()
````

And `alert(1)` will run (try it yourself!). 

Let's use this knowledge to produce a valid piece of code that executes the same `alert(1)`, now only by using our 6 symbols!


```js
[][
    [[][+[]]+[]][+[]] [++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]] 
  + [[][+[]]+[]][+[]] [++[+[]][+[]]]
  + [[][+[]]+[]][+[]] [++[++[+[]][+[]]][+[]]]
  ]
  [
    [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]
  + [[][+[]]+[]][+[]][++[+[]][+[]]]
  + [![]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][+[]]
  + [[!![]][+[]]+[]][+[]][++[+[]][+[]]]
  + [[!![]][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[+[]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][+[]]
  + [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][++[++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]][+[]]]
  + [[!![]][+[]]+[]][+[]][++[+[]][+[]]]
  ]
  (
  [![]+[]][+[]][++[+[]][+[]]] // a
+ [![]+[]][+[]][++[++[+[]][+[]]][+[]]] // l
+ [![]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]] // e
+ [[!![]][+[]]+[]][+[]][++[+[]][+[]]] // r
+ [[!![]][+[]]+[]][+[]][+[]] // t
+ [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[+[]][+[]]][+[]]][+[]])] // ( 
+ ++[+[]][+[]]+[] // 1
+ [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]])] // )
  )() // Evaluates to...


[]["find"]
  ["constructor"]
  (
  [![]+[]][+[]][++[+[]][+[]]] // a
+ [![]+[]][+[]][++[++[+[]][+[]]][+[]]] // l
+ [![]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]] // e
+ [[!![]][+[]]+[]][+[]][++[+[]][+[]]] // r
+ [[!![]][+[]]+[]][+[]][+[]] // t
+ [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[+[]][+[]]][+[]]][+[]])] // ( 
+ ++[+[]][+[]]+[] // 1
+ [[][[[][+[]]+[]][+[]][++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]]]+[[][+[]]+[]][+[]][++[+[]][+[]]]+[[][+[]]+[]][+[]][++[++[+[]][+[]]][+[]]]]+[]][+[]][(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]]][+[]])+(++[++[++[++[+[]][+[]]][+[]]][+[]]][+[]])] // )
  )() // Evaluates to...

[]["find"]
  ["constructor"]
  ("alert(1)")() // Evaluates to...

Function("alert(1)")() // Will alert "1"!
```

# Conclusion & Acknowledgements

Expanding on the final step of the sections above, we can convert *any* given Javascript code to obtain a string of the same program, composed of just 6 symbols - `[`, `]`, `(`, `)`, `+` and `!`. We also construct the primitive `[]["find"]["constructor"]` which allows calling `Function` constructor. It then takes the converted string as an input, outputs an anonymous function whose code matches the original string, and then we finally execute using a simple `()` call.

To conclude, in this post, we walked through how to take Javascript's "funkyness" and convert it something beautiful - executing any valid Javascript code using only six symbols. While looking a bit extreme, hopefully the message gets through - sometimes looking at thing from different perspective can yield great results. Matter of fact is, Javascript (and its derivative Typescript) didn't really care people thought it's weird or laughed at how it handled certain cases, and rose to huge popularity amongst backend and frontend developers alike.

Ending the post, some acknowledgements are in order:

1. First an foremost, if you wish to play around and generate valid programs of your own using these 6 symbols, go to [JSFuck website](https://jsfuck.com/), which is created by [Martin Kleppe](https://twitter.com/aemkei), the original creator of this wonderful idea.

2. This [wtfjs repo](https://github.com/denysdovhan/wtfjs) detailing many (many) funky behaviours of Javascript, and explaining them quite clearly!

3. The [ECMAScript language specification](https://262.ecma-international.org/) (for 2023). Yes, a bit odd to acknowledge that, but someone has to make tough decisions when it comes to type coersion in Javascript and these guys take on this task.

4. The [*Wat* talk by Gary Bernhardt](https://www.destroyallsoftware.com/talks/wat) which was the first time I was exposed to the hilarious side of Javascript, which led me to learn more about Javascript's weirdness which what was what eventually led to me taking the JSFuck challenge as a learning exercise.

So, thanks to these amazing researchers, and to you for reading. Until next time!
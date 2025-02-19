---
layout: post_math
title:  "What's your Thesis about? - Part 1"
subtitle: "Computational Complexity all the way to Interactive Proofs"
date:   2025-01-12 18:05:34 +0300
tags: [CS, computer-science, theory, computational-complexity, complexity, IP, interactive-proofs, NP, P]
readtime: true
cover-img: ["/assets/images/Thesis-P1/cover.png"]
thumbnail-img: "/assets/images/Thesis-P1/thumbnail.png"
use_math: true
---

## Preface

It has been about 2 years since I published my paper - [On Interactive Proofs of Proximity with
Proof-Oblivious Queries](https://eccc.weizmann.ac.il/report/2022/124/).

During my Master studies (which culminated with the paper), I fell in love with theoretical computer science. This subfield is concerned with many different topics, but one of the most researched area is **computational complexity**.

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Thesis-Paper-P1/computational-complexity.jpeg" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>Oded's incredible book covering the topic of computational complexity</i></figcaption>
</figure>

This area focuses on understanding the power of computers by classifying different problems according to the amount of resources they require (usually time or memory) into computational classes, and the relations between them. 

As I studied these topics, I grew increasingly amazed by the discoveries made since the inception of this area, while intrigued by the still unsolved questions.

While [the `P` versus `NP` problem](https://en.wikipedia.org/wiki/P_versus_NP_problem) is probably the most well-known unsolved question in this area, there has been many lesser-known but still incredible important questions that have been successfully answered, each showing amazing results (like [the PCP theorem](https://en.wikipedia.org/wiki/PCP_theorem)).

Additionally, many topics in the area that are of extereme importance to the future of computers still have many unanswered questions and unexplored topics (like the [power of randomization](https://en.wikipedia.org/wiki/BPP_(complexity)#Problems) and [open quantum computing questions](https://www.scottaaronson.com/writings/qchallenge.html)).

<figure>
  <img style="display:block; margin-left: auto; margin-right: auto" src="/assets/images/Thesis-Paper-P1/complexity-zoo.png" title="">
  <figcaption style="text-align: center; font-size:14px; color: gray"><i>The Complexity Zoo, courtesy of <a href="https://www.youtube.com/watch?v=YX40hbAHx3s">hackerdashery's great video on the topic</a></i></figcaption>
</figure>

My interest led me to explore the area of computational complexity further, taking advanced courses and reading the most recent papers in the area.

Two topics emerged which I took special interest in: **Interactive Proofs** and **Property Testing**.

It was while I was reading one specific paper that introduced a new object that combines both topics, that I identified an unanswered question on this object, prompting me to research it further and eventually write a paper about the discoveries.

I expect readers of this blog are more on the pratical technical side rather than the theortical one, so before writing a post on the results in my paper, two preceeding posts are in order:

1. The first explores **Computational Complexity**, introducing perliminary definitions of computational classes and models, and then dives deeper into **Interactive Proofs** - a specific model adding the ability to communicate with a powerful entity to solve problems more effeciently.

2. The second presents the intriguing subject of **Property Testing**, which alters the original definitions of some classes slightly to allow for some error leniency. Surprisingly, this small change makes many problems extremely easy to solve.

With this, my short preface is done, and the remainder below is the first post in the series.

Genrally, I wrote in a way that intended to be understood by anyone who wrote code (even just a little bit) and wondered how efficient their triple loop is.

Unfortuantely, there will be some parts I gloss over and not go into detail to avoid re-writing a 200-page book on the subject. What that happens, I attach a link to relevant articles for further reading.

Ready? Let's go!

# Complexity Theory

Right after putting the first computers to churn work on some complicated calculation, computer scientists at the time sat down and asked the burning question:

> What can a computer compute?

Imagine that you had a very very (very) powerful computer (in terms of its spec and ability to do complex calculations), and all the time in the universe (which is very large, while finite).

Could you compute any function you wish?

When I say that a computer calculates a "function", I mean that it runs some program that accepts the function's input and spits out the result in a finite time.

Summing two numbers is a simple function. It's also pretty simple to write a program that computes this function.

But, even for more complicated functions - like a function that takes a graph and two points as input and finds the shortest path between them - we have algorithms that compute them.

So, does that mean we can compute anything we want to?

Well, in 1936 Church (and a few months later also Turing) published a proof showing that a certain problem, called the *Halting Problem* in **undecideable** - meaning there cannot exist a program which computes the function of the halting problem. (More on the problem [here](https://en.wikipedia.org/wiki/Halting_problem) and also on the [appendix](TODO)). 

This stamps a large red <span style="color: red">no</span> as the answer to the above question. So are we done?

Well, not really. This discovery tells us that the world contains both decideable and undecideable problems. But then comes a follow-up question:
 
> What can a computer compute, efficiently?

The word <u>efficiently</u> is key here, and we will stand on its meaning soon, but this question is (in my opinion) the backbone of **Complexity Theory**:

It has proved to be, on one hand, very difficult to answer in general. On the other hand though, it pushed us towards crucial advances in our understanding in the power of computers, through many years of intriguing results on the topic.

## Definitions

In theoretical computer science, we have to prove our results the mathematical way: rigourously and using abstract, well-defined objects.

While an actual rigourous proof are not an absolute necessity for the intention in my blog, it's still important I present the abstract object definitions, both so I can use correct language consistently throughout the blog, and for you to be able to search for terms online if interested.

Throughout the post, I follow a simple method: **Bolded** words signify a term or definition, and *Italicized* words are reserved for specific problems or algorithms.

You might have noticed I've already used this - above, I mentioned the *Halting Problem*, a classic problem in **Complexity Theory**.

### Defining **Decision Problem**

So let's start by defining a **problem**. 

Starting off, it's the main subject in the field of computational complexity. There are couple types of problems, but we'll focus on a specific type: **decision problems**.

A **decision problem** has two parts: what type of objects it operates on, and a property of these objects.

To make this definiton clearer, let's give two examples:

- [*Graph Connectivity Problem*](https://en.wikipedia.org/wiki/Connectivity_%28graph_theory%29)
    1. The type of object is a graph
    2. The property is whether the graph is connected (i.e that you can travel from every node to every other node)

- *Majority Of 0s Problem*
    1. The type of object is a binary string
    2. The property is the string having strictly more 0s than 1s.

We successfully **solve** a **decision problem** if we create a program that, on a given **instance** of an object, correctly determines whether it satisfies the propery or not.

The best visualization that works for me is to imagine a large bag containing all possible **instances** of objects we're working with, and then two additional empty bags, marked <span style="color: green">YES</span> and <span style="color: red">NO</span>. 

A possible solution for the **decision problem** would be an **algorithm** that, given an instance from the large bag as an input, _decides_ whether to put it in the <span style="color: green">YES</span> bag or the <span style="color: red">NO</span> bag.

The **algorithm** successfully solves the problem if all the objects that it puts in the <span style="color: green">YES</span> bag satisfy the property (which we call **YES-instances**), and those who don't are put in the <span style="color: red">NO</span> bag (which we unsurprisingly call **NO-instances**).

There were a lot of terms here, let's break them down by using a concrete example - the *Majority of 0s Problem* we defined above:

1. This **decision problem** consists of binary strings and whether they have strictly more 0s than 1s.
2. An **instance** of the problem is a binary string. So, the imaginary bag of **instances** contains all possible binary strings. An example for a single **instance** - `0011000101`.
3. The **YES-instances** of the problem are all strings who satisfy the property - so they have strictly more 0s than 1s. The **NO-instances** of the problem are all strings who do not satisfy the property - so they have less or equal number of 0s than 1s.
4. An **algorithm** solves the problem is it returns `"YES"` for every **YES-instance** and `"NO"` for every **NO-instance**. For the example in point 2 - it would return `"YES"`.

Let's go a step further and write an actual **algorithm** that tries to solve the problem:

```py
def less_1s_than_0s(bitstring):
    one_count = 0
    zero_count = 0
    for bit in bitstring:
        if bit == 0:
            zero_count += 1
        else:
            one_count += 1
    if zero_count > one_count:
        return "YES"
    return "NO"
```

Here, it's pretty simple to be convinced that the **algorithm** above successfully **solves** the *Majority of 0s Problem*. However, for more complicated problems and algorithms, we would require a more thorough proof.

### Defining **Complexity**

As you probably know, running an algorithm requires a certain amount of time and space (i.e amount of system memory). Going back to the question we posed, how can we tell whether a problem can be solved <u>efficiently</u>?

We might expect that longer inputs will take more resources than shorter ones.

So, we'll also provide the algorithm with the **size** of the instance as an input, denoted by \\( n \\) (so for the bitstring input `11011`, \\( n \\) would be \\( 5 \\)), and refine our question: how efficiently does the algorithm perform on instaces of a specific size \\( n \\)?

For example, the algorithm for *less_1s_than_0s* we described above iterates over the entire input once, so the time it takes it to finish grows linearly with the $n$. 

The memory it uses is just the two counters which have to count up to $n$ in the worst case (if the input is just 1s or just 0s). This means that the memory grows logarithmically with $n$.

A shorter way of saying of all that is that the **time complexity** of the algorithm is $O(n)$, and its **space complexity** is $O(log(n))$.

Aside: As common [O-notaion](https://en.wikipedia.org/wiki/Big_O_notation) is used to describe algorithm's complexities. You can read more about it online ([or watch a short video](https://www.youtube.com/watch?v=__vX2sjlpXU)), but described shortly, it's used in computational complexity as a way to describe the algorithm's effeciency by focusing on the largest term. So, if algorithm 1 takes $5*n+1000$ time in the worst-case, and algorithm 2 takes $1000*n$ time in the worst-case, in "practical" terms algorithm 2 takes about 200 times more time thatn algorithm 1, they both have $O(n)$ time complexity and are equivalent in our eyes.

Aside #2: We're interested in the **worst-case complexity** of an algorithm. This means that for us, the time or space complexity of an algorithm is the time or space it takes for it to decide on the worst possible input of length $n$. There are other notions of complexity (such as [average-case complexity](https://en.wikipedia.org/wiki/Average-case_complexity) that are practical and of interest), but we won't consider them for now.

Here's a short recap on the definitions so far:

- **Decision Problem** - what we want to solve. Consists of types of objects and a property.
- **Instance** - a specific input to the decision problem.
- **Algoirthm** - a program solving a decision problem by outputting the correct binary choice per input.
- **Size $n$** - the size of an instance being given as an input to the algorithm.
- **Worst-case Time/Space complexity** - an big O-notated function of $n$ describing the time/space it takes for an algorithm to solve a decision problem in the worst-case over all inputs of size $n$.

Through the years, comptuer scientists working on computational complexity considered many algorithms to solve prominent decision problems (like *graph connectivity*, *linear programming*, *hamiltonian cycle existance*, *3-SAT*, *Subset sum* and even *Sudoku* (of variable sizes)). 

Circling back to our question, which of the algorithms we consider as efficient when it comes to solving these problems? To answer this, we place each problem into a **class** according to the whether an algorithm satisfying certain complexities and definition requirements is known for it.

## Polynomial-Time Complexity

Today, we generally consider problems that reside in the complexity class $\cal{P}$ as solved effeciently, and call them **polynomial-time** algorithms.

> A problem resides in the class $\cal{P}$ if there's an algorithm whose time complexity is a [polynomial](https://en.wikipedia.org/wiki/Polynomial) in $n$ (for which $n$ doesn't appears in a power) which solves the problem.


Why polynomial-time complexity? There are 2 reasons:

1. Ambivalency to computational model. The system you're using to read this could be vastly different from mine in terms of capabilities. Who's to say that an algorithm running on one system (with a certain processor and maybe written using one programmaing language) won't run in very different time complexity than on system two (using another processor and written with another programmaing language)? In fact, Turing does. The famous [Church-Turing thesis](https://en.wikipedia.org/wiki/Church%E2%80%93Turing_thesis#Variations) showed how different models of computations are actually equivalent in their time and space complexities, as long as you're willing to take a polynomial increase in the time complexity. Future work extended this to show that basically, if the time complexity of an algorithm running on a Turing Machine (the chosen model for assessing an Algorithm's complexity) is polynomial, it is also so on a modern-day powerful computer.

2. Size of inputs. In real-life applications, like finding shortest distance between two points on an actual city map, or iterating over lists of people living in a country, the input size $n$ isn't _that_ big. Combine this with the power of our modern-day processors, and considering the speed a polynomial grows with $n$, we find that polynomial-time algorithms finish computation on practical inputs in (mostly) reasonable time.

Hoping that these reasons are satisfying enough, we can consider positioning a problem in $\cal{P}$ a good indicator that it can be solved efficiently.

Aside: In recent years, the theory community began inspecting $\cal{P}$ further, by trying to separate problems within into buckets according to the exact polynomial that describes their time complexity. This area is called [fine-grained complexity](https://www.mpi-inf.mpg.de/fileadmin/inf/d1/teaching/summer19/finegrained/lec1.pdf) and gathers a lot of interest in the world where, working with big-data, the size of inputs $n$ sometimes grows so large that even certain polynomials are too large for us.

But, I imagine you say, there are tons of problems. What about those we weren't able to find polynomial-time algorithms for?

## Beyond Polynomial-Time

Well, once scientists began inspecting algorithms for their best time-complexity, a strange phenomenon happened: there were many these problem which, tooth and nail, researchers were able to devise polynomial algorithms for, and rightfully place them inside $\cal{P}$. However, there were many _other_ problems for which they just...couldn't do it. In fact, for many of those problems, it seemed as if nothing works besides the bruteforce method (like trying every possible paths between place A and B to find the shortest distance between them). 

This bruteforce method's complexity usually happened to be _exponential_ in the size of the input, making them an **exponential-time** algorithms and reside in the class [$\cal{EXP}$](https://en.wikipedia.org/wiki/EXPTIME).

To show how different exponential-time algorithms are from their polynomial counterpart, imagine that there's some graph problem we want to solve. A nice mid-sized graph could have $n=10000$ (a decently mid-sized populated urban area in the US, for one). A polynomial-time algorithm running in $n^3$ would run for about a trillion instructions on that input, whereas an exponential-time algorithm running in $2^n$ iterations would run for about $2 * 10 ^ {3010}$ iterations. That's a numer with more than 3,000 zeroes. Yes, it's that large.

Is that all we're able to do? Separate vasts amount of problems in the world to two very, _very_ far-apart complexity classes? It all feels a bit crud for what we're trying to achieve here.

As an earlier paragraph hinted, we can do something better. We understand that trying to shoot for the moon (which is polynomial-time algorithms) proves too difficult to certain kinds of problems. So let's relax the necessity to _just_ running in polynomial-time, by working with different constraints that may not depend on the time-complexity of the algorithm. We can use this idea by providing different kinds of help to the algorithm, and figure out what's the minimum push it needs to solve the problem efficiently in polynomial-time.

Remember that phenomenon about the exponential-time algorithms? Well, another intersting phenomenon about many of the problems we were unable to place in $\mathcal{P}$ is that if we were able to give our algorithm a "hint" alongside the input, then suddenly checking whetehr the input satisfies the property becomes much easier.

This leads us to the second famous class, $\cal{NP}$ (which _doesn't_ stand for "non-polynomial") whose definition is as follows:

> A problem resides in the class $\cal{NP}$ if there's a polynomial-time algorithm $A$ taking an input $x$ and a _witness_ $w$ such that:

* If $x$ is a YES-instance, then there exists a $w$ such that $A$ outputs YES.

* If $x$ is a NO-instance, then for all $w$ $A$ outputs NO.

Obviously, any problem in $\mathcal{P}$ satisfies this definition - these algorithms didn't need a hint at all and can simply ignore the witness and find the answer themselves in polynomial-time.

So why is this definition helpful? The class $\mathcal{NP}$ seems bit odd in first sight, but is actually very intuitive! It consists of all problems for which it is _easy to verify a solution_, rather than finding a solution yourself (that for which the class $\mathcal{P}$ exists). This "proposed" solution is provided to the algorithm using $w$, and the algorithm just has to verify that it's indeed a solution for $x$.

More intuitive? Well, think about your favorite newspaper puzzle (or just pick Suduko because it's the best). How much time does it take you to solve one? They're usually possible, yes, but can prove quite difficult, and there are types of puzzles which are much tougher than others. 

Now imagine that you sit down on a quiet Saturday evening to solve your favorite puzzle, only to find that someone has already filled it in. Annoying! But, how long would it take you to verify that the solution is correct? In most puzzles (and Suduko is an excellent example of this phenomenon), it _feels_ much simpler checking that all constraints are satisfied rather than finding the solution yourself.

In fact, this is the crux of the $\cal{P}$-equals-$\cal{NP}$ [millenium prize problem](https://en.wikipedia.org/wiki/Millennium_Prize_Problems#P_versus_NP) and generally a very interesting philosophical question: is it really harder to find a solution to a puzzle than to just verify it?

A practical example of a decision problem which is in $\mathcal{NP}$ is the *$T$-Subset-sum* [problem](https://en.wikipedia.org/wiki/Subset_sum_problem). In which the input is a list of integers, and the property is that the list contains a subset of numbers which sum up to $T$. 

Given the list of integers, one can also provide the algorithm as the witness $w$ the positions of the integers that sum up to $T$. This only requires $O(n)$ time to verify! On the other hand, as mentioned, so far no polynomial-time algorithm was found for this problem (and trying out all possible subsets takes exponential-time).

The class $\mathcal{NP}$ is a great example showing how a relatively simple relaxation of the requirements for the algorithm lead us to defining a class that is much "closer" to $\mathcal{P}$ than $\mathcal{EXP}$, and allows us the explore the world of problems in a more thoroughly.

--

I started this post stating that our target is presenting interactive proofs, but 2,000 words later discussing many aspects of computational complexity, we seem not even close to the concept of proofs, nor interactivity.

Don't worry, we're closer than it seems.

Have a second look at the $\mathcal{NP}$ class definition. Now, imagine that instead of the dry definition of us magically "providing" the algorithm with a  witness $w$ alongside the input $x$, let's be a bit more playful and alter our definition:

The algorithm now would only receive the input $x$. But there also exists another entity in the world which is the **prover**. This prover also receives the input $x$, but is vastly more powerful than the algorithm. In fact, the prover knows everything and anything about the world, and its sole purpose is to convince the algorithm it output YES.

So now our definition for a polynomial-time algorithm in $\mathcal{NP}$ that solves the problem is as follows:

* If $x$ is a YES-instance, then there exists a message $w$ that the prover sends to the algorithm, which would convince it to output YES.

* If $x$ is a NO-instance, then no matter what message the prover sends the to the algorithm, it would always output NO.

// TODO: Image of a non-interactive system

This equivalent definition of $\mathcal{NP}$ class is the first step towards discussing interactive proofs. We created a prover that uses one-way _interaction_ with the algorithm (which we also call the verifier, being its main purpose) to _prove_ that the input $x$ is a YES-instance.

A simple step forward takes us all the way: imagine that now the verifier can interact _back_ with the prover. In fact, let's let them interact as much as they wish. Suddenly, we have managed to define a new complexity class: [**Interactive Proofs**](https://en.wikipedia.org/wiki/IP_(complexity)), or $\mathcal{IP}$.

> A problem resides in the class $\mathcal{IP}$ if there's a polynomial-time verifier $V$ taking an input $x$ and an _honest prover_ $P$ such that:

* If $x$ is a YES-instance, then after communicating with the $P$, $V$ outputs YES

* If $x$ is a NO-instance, then for every possible prover $P*$ after communicating with $P*$, $V$ outputs NO.

This definition adds another layer to our alterantive definition to $\mathcal{NP}$: now we say that there's a honest prover which is able to convince the verifier when $x$ is a YES-instance, but when $x$ is a NO-instance, no matter what strategy the prover takes, it won't be able to convince the verifier to output YES.

// TODO: Image of an interactive system

The follow-up question is: what's the power of $\mathcal{IP}$? Is it equivalent to $\mathcal{NP}$? Very close to it? Or perhaps really far and we're too close to $\mathcal{EXP}$?

Unfortunately, there's no simple practical example of a problem which is in $\mathcal{IP}$ I can present here. The most known problem is called *Graph Non-isomorphism*, which is a pretty scary name for a not-so-scary problem. However, presenting both it and its correponding $\mathcal{IP}$ verifier and prover is a bit too much for this blog, but you can read the excellent lecture notes explaining this problem [here](https://people.csail.mit.edu/ronitt/COURSE/F17/NOTES/lec6-scribe.pdf).

Forgoing showing a practical example, let's at least answer the above question. In a [seminal paper](https://dl.acm.org/doi/10.1145/146585.146609) from 1992, Adi Shamir showed equivlancey between $\mathcal{IP}$ and $\mathcal{PSPACE}$, which is the class of algorithm solving problems in probabilistic _space_-complexity (can be seen as the space-analog to $\mathcal{P}$).

This result places $\mathcal{IP}$ in a very interesting spot on the complexity heirarchy. On one hand, it isn't too "close" to $\mathcal{NP}$ and $\mathcal{P}$, as it contains problems from $\mathcal{PSPACE}$ which seem unreasonable to solve in polynomial time. On the other hand, it isn't too "close" to $\mathcal{EXP}$ either, because $\mathcal{EXP}$ contains problems which seem unfeasible to solve in polynomial space.

However, both of these questions are still open to this day, and we could suddenly find outselves in a world where $\mathcal{IP}$ is closer to one side than we expected it to, while it doesn't seem likely.

In recent years $\mathcal{IP}$ garned much attention, because it is a crucial tool when it comes to blockchain algorithm and cryptocurrency which heavily relies on interactive proofs for core aspects of these systems.

## Summary

We understood why the question of computational complexity is of interests to anyone who interacts with computers in any way. We've then covered the core aspects of communication complexity: starting with the most basic definition to defining natural and intuitive different complexity classes to categorize differnet problems to.

We built the famous and important classes of $\mathcal{P}$ and $\mathcal{NP}$ and disucssed the relation between them. We altered $\mathcal{NP}$ to fling us into the world of interactive proofs, where we landed on the class $\mathcal{IP}$, which will come to play partly in the second post about **Property Testing**, and finally in the last post about my Thesis's subject.

The area of computational complexity is vast and filled with interesting classes and research. An endless source of information about the field is the [complexity zoo](https://complexityzoo.net/Complexity_Zoo) website, which lists many complexity classes, they relations and relevant academic articles about them. There's also this [amazing video by hackerdashery](https://www.youtube.com/watch?v=YX40hbAHx3s) on the topic, which I highly recommend you to watch.

// Image of the complexity zoo.

That's all for today, we'll meet in the next one to present a unique and very interesting take on classic computational complexity, which is the area of **Property Testing**. See you then!


// TODO: Sources, credit for definitions








We can define and place algorithms in other complexity classes. In fact, computational complexity deals with proving properties within and between classes as much as it deals with defining these classes and proving problems reside (or don't) in one class or another.



I wanted to write about the paper I published during my master's thesis research.
The paper involves topics from **Complexity Theory** that aren't too difficult themselves but are built on top of things that even most Computer Science students are not familiar with, even if done a basic course on **Complexity** in the past.

// Explain about the series
So, this is a series intending to have the 3rd post delving into the paper and its results, and to get there we will need to pass through two other (standalone) posts. This one presenting important concepts from the field of **Complexity Theory**, usually taught during introductory courses in a CS degree, and a bit further than that. The second post will detail a beautiful extension of **Complexity** concepts, called **Property Testing**.

// Let people know the outline of concepts introduced here.
This **Complexity Theory** post includes the following concepts: **Search Problems**, **Time Complexity** and the classes $\cal{P}$,$\cal{NP}$ and $\cal{IP}$. If you're familiar with these concepts, you can jump straight to the second post.

// Cover for mistakes or inaccuracies
The post that follows is designed to be understood by basically anyone who ever wrote even the most basic piece of code on a computer. But, as with these kind of posts, it's going to include many over-simplficiations and slight inaccuracies (some intended,some not). I apologize in advance and do let me know if you spot anything that I should fix.

## Intro

// Introduce the question of trying to understand how hard or difficult a problem or a riddle is. Give examples.
Computer scientists, porgrammers, mathematicians and basically a pretty big amount of people in history tried to understand how *hard* certain problems are (usually those they couldn't solve themsleves). For instance, how hard is it to solve a Sudoko puzzle, figure out if a number is a prime, or even just write a funny joke? 

// Introduce Complexity Theory - it's the subject of understanding how hard problems are, but for computers. Give examples specific to computers.
One of the goals of **Complexity Theory** is figuring out how hard these (and other) problems are for *computers* to solve. Most problems are math-related, but were considered since they arise naturally when computer programmers try to solve real-life problems. 
For instance, when a map software tries to direct you to the closest cafe, it needs to find the shortest path amongst all possible paths, or when your favorite streaming service needs to decide which show it should recommend you to watch next.

We'll start by defining the type of problem we're interested in: search problems.

// Define terms related to search problems
## Search Problems
To be able to discuss problems, we'll define some terms: a *problem* is a generalized form of something we want to solve. It contains specific *instances* that we receive and needs to solve. By solving, we mean that the computer will execute an *algorithm* that needs to *search* for a solution to the instance. Let's use these terms to define a simple example:

// Give the first problem, and a specific instance of it.
#### Problem 1: Largest Number in List
> Given a list of positive numbers, search for the largest number.

An *instance* of this *problem* could be:

> Search for the largest number in the list `[6, 1, 7, 2, 5]`.

// Give an algorithm that solves the first problem.
#### Algorithm 1
An algorithm that solves this *problem* could be:
```c
uint solve(uint * numberList, uint size) {
    uint largestNumber = 0;
    for (uint index = 0; index < size; index++) {
        if (numberList[index] > largestNumber) {
            largestNumber = numberList[index];
        }
    }
    return largestNumber;
}
```

// Run the algorithm on the instance. Discuss the size variable and handling edge-case?
Upon executing `solve([6, 1, 7, 2, 5], 5)`, the *algorithm* will output `7`. 
There are two things we overlooked and appear implicitly in the *algorithm* above:

1. Besides getting the specific *instance*, our *algorithm* also receives an important variable - `size` which indicates how wlong the instance that we've given. As programmers, we prefer that the algorithm is agnostic to this variable, even if it's used within (this means that the algorithm behaves the same for different values of `size`).

2. When we discuss *search* problems, we need to handle edge-cases and some cases where there's no possible solution for the problem (imagine asking a mapping software for the closest cafe, but you're standing on a deserted island). We'll just assume that the algorithm outputs a special value to indicate that. In this current case, we decided we're okay with outputing `0` if the array is empty.

// Explain differnce to decision problems. Maybe move above when talking about problem types.
> (TODO: Change to a note box) You should ask why I prepended the word "search" before "problems" in the title above. This is because we're also interested in other types of problems. The most famous type is *decision* problems, where instead of searching for an output value we instead wish to know whether the instance our *algorithm* receives satisfies some condition. These types of problems will be much more useful to us in the next post.

// Go back to the hardness question, and come to a conclusion that we must define efficiency of an algorithm.
Now that we've seen example of a *search problem*, we must ask how *hard* this problem really is? As it turns out, the *algorithm* that we wrote is the best we can do for this *search problem* in terms of computation efficiency. But wait, how do we define efficiency?

// Introduce time complexity, give example by counting the time complexity of the algorithm.
### Time Complexity
When we talk about how efficient an *algorithm* is, we usually care how much *time* the *algorithm* executes before outputting an solution.

For the *algorithm* above, let's count the number of operations it does: 
- Initializes two values.
- For every element in the list:
    * Makes a single comparison (for the loop)
    * Then another comaprison (checking if the current element is the largest so far) 
    * Then (sometimes, only if the `largestNumber` needs to be updated), updates a variable.
    * Finally, increasing `index` by 1.

// Talk about worst case time complexity, and ignore constant by hand-waving O notation.
That means that in the worst case (when we update the value on every element), a total of `4*size + 2` operations will be executed. However, since the constants are usually small, in most cases we're only concerend with the effect of the `size` parameter on the running *time* of the *algorithm*. We use [O-notation](https://en.wikipedia.org/wiki/Big_O_notation) to signify this, and thus say that the *time complexity* of the *algorithm* above is $O(size)$.

// Discuss space complexity
> (TODO: Change to a note box) There are other complexity measures that interests us. The most known one is the *space* complexity, which deals with how much storage the *algorithm* requires during run-time. We won't be interested in other measures during the following posts, but it's good to mention nevertheless.

// Prove that this is the best we can do?
In the case of the *problem* above, we can prove to ourselves why using $O(size)$ is essentially required: if we're running in less time than that (in our notation this means that our *algorithm* inherently doesn't have enough time to look at the entire list), then for every *instance*, there are at least one element in the list that the *algorithm* doesn't see. In the worst case, this element is the largest in the list, meaning that we'll output a wrong solution.


// Go back to asking whether this means that the problem is hard or not. Try to come up with a practical answer, fail and conclude that we need to decide on something that is good generally.
But, what does this entail for the original question of whether the *problem* is hard or not? 

Trying to think practically, we'd want to check if *time complexity* of our *algorithm* for an average `size` variable is short enough that a decent computer would be able to find a solution in reasonable time. Notice that all of this depends on several factors: the averge `size` of our instances, how powerful our computer is, and the number many times we'll have to run the *algorithm*, making this very difficult to do generally.

### Polynomial Time and the Class $\cal{P}$


// Define polynomial time.
In the world of *complexity theory*, a good goal for an *algorithm*'s *time complexity* is "something polynomial in `size`". This means that we'd like how *time complexity* to be a [polynomial function](https://en.wikipedia.org/wiki/Polynomial) if we take `size` to be the variable. We say that such *algorithm* run in *polynomial time*.

This decision is not aribtrary. Solving a *problem* with a *polynomial time* *algorithm* usually means that we can efficiently solve instances of reasonble `size`. 

// Define the class P
The *class* of all *problems* that we've already found a *polynomial time* *algorithm* for is called $\cal{P}$ 

# TODO: Insert image of a bucket with the name P and multiple problems inside of it.

// Conclude that the problem above is in P
If we go back to the example above, *algorithm 1* is indeed *polynomial time* (the function $f(size)=4*size+2$ is polynomial in `size`), and therefore *problem 1* is in $\cal{P}$!.


### Going Beyond to the class $\cal{NP}$

// Consider cases that we haven't been able to show that they're in P.


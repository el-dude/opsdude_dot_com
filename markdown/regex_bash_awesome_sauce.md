*Posted on May 11, 2013 by El Duderino — 1 Comment ↓*

# Regex bash awesome sauce

![xkcd Comic #208 Jan 10 2007](./assets/xkcd_regular_expressions.png)

This is going to be a quick post. I have been extremely busy and have been without a laptop for over a month which in turn has caused me to neglect this blog. Sorry. I now have a new shiny MacBook Air so I will be able to start making more regular posts.

Lets talk about regular expressions for a minute. In my day to day fumbling around I find myself leaning on regex to help me find and narrow down patterns all the time. I am going show a quick and easy exercise that will show you a very simple example of how to use regular expressions at the command line.

Lets get started by talking about “grep” for a minute. Grep is a fantastic tool that is in its essence a command line search utility. One of the things you can use grep for besides literal matches in your search is searching for patterns. By default grep uses Basic Regular Expressions(BRE’s) but you can use the “-E” flag that will allow you to use Extended Regular Expressions(ERE’s). In this quick run down of looking for patterns within grep I will be using ERE’s with grep.

So here is the exercise:
You need to get all associated IP addresses from a host name/DNS record.

Lets use the “`host`” command that comes in most modern distributions([Ubuntu] (https://ubuntu.com/), [RHEL] (https://www.redhat.com/en), [Debian] (https://www.debian.org/), [OS X] (https://www.apple.com/macos/), etc…)

**example:**

	
```
Dudes-Mac-mini:~ dude$ host www.google.com 
www.google.com has address 74.125.226.212
www.google.com has address 74.125.226.208
www.google.com has address 74.125.226.210
www.google.com has address 74.125.226.209
www.google.com has address 74.125.226.211
www.google.com has IPv6 address 2607:f8b0:4004:802::1013
Dudes-Mac-mini:~ dude$
```

As you can see this will get you all the IP addresses including IPv6 addresses associated with the name but we just want to see the IPv4 Addresses and not the name or any other text. So we could use “awk” to slice out the column of the IP addresses:

```
Dudes-Mac-mini:~ dude$ host www.google.com|awk '{print $4}'
74.125.226.212
74.125.226.208
74.125.226.210
74.125.226.211
74.125.226.209
address
Dudes-Mac-mini:~ dude$
```

As you can see this is sort of a problem. as it also gets the word “address” from the IPv6 output.

So let’s switch gears here and think about what we want to do. We want to use a pattern to match the IPv4 addresses and only get that output for us. So instead of using “awk” we will swap it out for “grep”.

Now when using grep to pattern match I will be using the ERE’s so we will want to pass in the -E flag. Also we only want to show the section of the pattern found not the whole line so we will use the “-o” option as well. This option will display only the match found not the whole line as by default.

Lets talk about Patterns and what we want to do with them. Using Regular Expressions is a massive can of worms and there is endless resources on the web & in books on how they work. I am going to just cover the basics for this silly exercise to expose some of their benefits. A good recourse to use in teaching yourself Regular Expressions is regexpal I use this page all the time to vet out my patterns that I want to use. I highly recommend you to check it out.

So when using expressions to match patterns in grep we will want to use “()” as a capture group. We will also for this exercise want to capture digits(numbers) and there is a hand full of ways to do that. you could use a character class “[0-9]” to match numbers or as I prefer the shorthand equivalent “\d”. We will need to capture literal matching for the “.” in between the digits. We will also need to use quantifiers “{}” to to tell us the exact number of occurrences of things we want to capture.

Here is the pattern I came up with to match IPv4 addresses:
`(\d{1,3}\.){3}\d{1,3}`

So lets break this down a bit so it makes sense. So I will explain character by character what is happening here:

```
( = open a capturing group
\ = start the character shorthand or escape next character
d = end character shorthand(match any digit 0 through 9 with \d)
{ = open a quantifier
1 = minimum quantity to match
, = separate quantities
3 = maximum quantities to match
} = close quantifier
\ = start escape next character
. = escaped character(for literal match)
) = close capturing group
{ = open another quantifier
3 = match exactly 3
} = close quantifier
\ = start the character shorthand or escape next character
d = end character shorthand
{ = open another quantifier
1 = minimum quantity to match
, = separate quantities
3 = maximum quantities to match
} = close quantifier
```

Now that we have the expression lets use it with grep. make sure to use the -E & -o options I spoke about earlier.

```
Dudes-Mac-mini:~ dude$ host www.google.com|grep -Eo '(\d{1,3}\.){3}\d{1,3}'
74.125.226.209
74.125.226.208
74.125.226.211
74.125.226.212
74.125.226.210
Dudes-Mac-mini:~ dude$
```

You can see that it is now giving us exactly what we are looking for. To spice it up just a tad you can use sort to sort the output in order and then pipe that through uniq to only show it once if there were multiple occurrences of the output.

```
Dudes-Mac-mini:~ dude$ host www.google.com|grep -Eo '(\d{1,3}\.){3}\d{1,3}'| sort | uniq
74.125.226.208
74.125.226.209
74.125.226.210
74.125.226.211
74.125.226.212
Dudes-Mac-mini:~ dude$
```

That is all I have time for today. If you would like to learn more about regular expressions I would highly recommend the book titled [“Introducing Regular Expressions”] (http://shop.oreilly.com/product/0636920012337.do) written by [Michael Fitzgerald] (https://www.oreilly.com/pub/au/1365) (O’Reilly) This book is short and sweet gets right to the point. After reading this book you will be well on your way to using regex in your day to day tasks.

xkcd: Regular Expressions
https://www.explainxkcd.com/wiki/index.php/208:_Regular_Expressions

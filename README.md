# Looking For Bag Guys

## The CLI version

Stay away! This is earlier than alpha software!

## Scope

This little script's scope is to act as regex collection in order to do
code scanning about maliciuos code and files.
The are two search models:

* filenames
* snippets

The former will search for filenames based on regexes listed in _include.list_,
excluding those matching regexes in _exclude.list_. The latter will search for
files matching the _include.list_ regexes, than scan the code for patterns 
matching the _regex.list_.

## Why?

All began thanks to the idea born from [25yearsofprogramming](http://25yearsofprogramming.com/php/findmaliciouscode.htm).
In @welaika we have a lot of hosted sites, hosted on massive hosting services, 
with intrinsic security holes. We had some attacks, the most were web-shells
injections or defacements; so we was in need of a passive security scan to monitor
our site's code, just like lfbg from 25yearsofprogramming.

But that is a PHP script, with all the side effects (some are subjective):

* slow
* need a webserver
* so fu***ng slow scanning hundreds of thousends of files
* almost usable only interactively
* a browser killer
* a resources killer
* too hardcoded

So we decided to write down a few lines of Perl code in order to make:

* fast as it can
* the best regex engine built in
* easily configurable regex collections (with comments too)
* ultra portable (just few installs from cpan)
* non-interactive

## Search for what?

I'm working on making _lfbg.pl_ a web-shell and htaccess hack detector. But it
is a little search and scan engine based on regular expressions, so it could
be extended in any direction.
But I'm assuming that the most you write regexes to scan for generic dangerous
code, the most you'll get false positives; and the most you'll get false positives
the most you'll ignore the report in your inbox! :)
So I'm focusing on reading webshells' code and htaccess attack technics, cathcing
significant and representative snippets and writing down regular expression
matching them.

## Status

At the moment we are working (slowly) on the script in this way:

* we run it on our backup server: backups in the night, sec scanning during the
day on the backed up files
* we are refactoring the shipped regex collection: too many false positives in
the original lfbg; and we are specializing the scan (I'll write more about)
* we are implementing the _exclude_ functions (not a hard work, so it will be
shipped soon)
* we are planning (it is just on my local dev branch ;) ) to implement a sec
check specifically for wordpress sites based on the md5 hashes of the core's files

## Just a piece of security

We are moving towards to use three passive security check tools:

* NeoPI
* Maldet
* Lfbg.pl

So we are not interested in writing a full featured search&scan script or an
IDS or whatsoever similar.

## Sharing

We will be happy, one day, if anyone using _lfbg.pl_ will share usefull regexes
adding them to the shipped collection :) 
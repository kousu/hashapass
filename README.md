hashapass.sh
============

Linux implementation of http://hashapass.com (zenity- and shell-based).

In a world of shortening attention spans and exploding password use,
most people use _one password across several accounts_,
making common attacks like the [LinkedIn hack](FIXME) and the [PS3 break-in](FOXYOU) and worse: those no one is even aware of, viciously dangerous.
The security-savvy use _distinct passwords everywhere_,
but the human mind is short on [serial memory](https://www.youtube.com/watch?v=XxIzmkWygjY) so this requires: i) keeping an insecure copy on paper, 
ii) putting your trust in an online, for-profit password manager,
or iii) maintaining an offline password wallet (e.g. [the Firefox password manager](https://support.mozilla.org/en-US/kb/password-manager-remember-delete-change-passwords?redirectlocale=en-US&redirectslug=Remembering+passwords), [gnome-keyring](https://wiki.gnome.org/Projects/GnomeKeyring), [Keychain](https://en.wikipedia.org/wiki/Apple_Keychain), [keepass](http://keepass.info/)) which is vulnerable to brute forcing if (really, when) someone gets physical access to your device, and has all the sync problems that come with rolling your own.
**Hashapass** is the best of both worlds, creating distinct passwords with more creativity (that is, entropy) than you have in your head from one single master password, all while  _**making no records anywhere**_.

[Hashapass](http://hashapass.com/en/index.html) was originally written by [a very nice frenchman](FIXME).

Hashapass is part software and part habit. The habit is to use it when creating accounts. Everytime you do a signup, take the domain name of the site, or some other string that the site
reminds you of (for example, I used "lj" for livejournal, and I use "github.com" for github),
and enter it as the "parameter" in hashapass. Then type your _master password_,
click the button, and give **the result** it gives to the site you are signing up for as your new password.

Every time you need to log in again, just repeat these steps.
You only need to remember your master password, and you never need to write down anything.

After a while, hashing your password on login becomes second nature, and you will find yourself updating your older passwords to hashapass form on your next cycle (you do change your passwords regularly, right?).

Some sites have extra rules for their passwords--like requiring at least one
punctuation character and at least one number.
[These sites are assholes](http://xkcd.com/936/).
My workaround for them is to keep a `passwords.txt` which records `hashapass(assholesite.com)+"2#"` where "2#" is whatever addition assuaged their rules.

If you do need to update an account password later _for some reason_, you can [salt](https://en.wikipedia.org/wiki/Salt_%28cryptography%29) the parameter. e.g. instead of "github.com" enter "github.com2". I record these cases in `passwords.txt` but only if I find myself forgetting the salt.

Because you get to explicitly choose the "parameter", you can use hashapass for anywhere you need a password: your laptop's root account, your ssh account at work, or a throwaway account on a friends' machine. It is not limited to just the web (like [some other](FIXME) password schemes are).

The more people are disciplined enough to use hashapass or one of the [competitors](#The Competition) everywhere, the safer the web is for all of us.

Pull requests welcome!

## Paranoia

But after you have done this for a while, you might start to wonder if you can trust hashapass. Indeed, some people do:

["God I hope this isn't backdoored"](https://play.google.com/store/apps/details?id=com.hashapass.androidapp&reviewId=Z3A6QU9xcFRPRkRfbkk3aE1nWnZyN2ZmQU1hcFBDdlRNSm9xVnFfQnBscG9YdWxNeHQ3TXBFRUkzcUI3b0ZITjctN0Z5VnYtcnZSRktiR1dLaXRTMS1DcUNR)

Sure, you can [audit the source](http://hashapass.com/en/index.js), but it has been minified since it was first written.
The web interface is convenient but the site doesn't use SSL so you as a user of it are very vulnerable to a MITM'd inserting code that records passwords as they are constructed,
and anyway might crash, run out of funding, electricity or chutzpah any day.

The site provides a [bookmarklet](http://hashapass.com/en/bookmarklet.html), but that only works for websites, many of those websites
break the bookmarklet is activated but trying to be more clever than the web (I'm looking at you, wikispaces; you aren't the only offender, though),
and it is impossible to use the bookmarklet to e.g. sign in to an ssh account.

You can save the [mobile edition](http://hashapass.com/en/phone.html) to your desktop, but that requires spawning
a browser with a javascript engine to use--no good if X has crashed on you and you need to login to your remote site to recover a backup.

**This implementation is my safety net**: by running the code locally, you can operate offline, stay in control, and are future-proofed. The core* is clear and auditable, and uses only basic, open-source, cryptography tools:
```
  hashed_pass=$(echo -n $parameter \
        | openssl dgst -sha1 -binary -hmac $password \
        | openssl enc -base64)
```
[* from the original author](http://hashapass.com/en/cmd.html)

If you appreciate this, toss the original author a few dollars on [the android marketplace](https://play.google.com/store/apps/details?id=com.hashapass.androidapp) (or email [him](mailto:info@hashapass.com) and ask if he has a paypal or flattr).


Usage
------

```
usage: hashapass [-l] [-s] [parameter]

Ask for your "master password" and compute hashapass(master, parameter).
Writes the resulting, constructed, password to the system clipboard via `xclip` if posible.

-l           output "long" passwords: 28 characters (216 bits of entropy).
             By default, outputs 8 chars (64 bits), which is hashapass.com-compatible.
-s           "show" the password: display it to the user when it has been computed.
             Always on if xclip is not installed.
parameter    can be given on the command line to speed up usage or be used in aliases and scripts.

All the arguments are optional.

If run from the command line (i.e. a tty), interacts with you on stdin.
If run from a GUI (e.g. .desktop file or by the Gnome/KDE command launcher), interacts via `zenity`.
```


You might want to add
```
alias hashapass="hashapass -l"
```
to your `.profile` to use long passwords by default. The only reason short passwords are default is that I used web- hashapass for so long that almost all of my passwords are in short hashapass format and changing them now would be a pain.

The quickest way to use this in daily linux desktop use is to make sure `zenity` is installed,
then memorize this key sequence:  
`ctrl-F2` + `hashapass site.com` + `[enter]` + `[password]` + `[enter]`. Note that there is a small security risk here:
a user (eg a virus) that has the ability to run `ps -auxww` or read your `.bash_history` will be able to see your parameters (but not your master password and not your generated passwords) and,
if hmac is some day compromised, could reverse engineer your passwords.

Dependencies
------------

You must have [openssl](https://www.openssl.org/)'s command line interface installed, but if you don't have that your linux is crippled and you should reinstall.  
You must have [zenity](https://help.gnome.org/users/zenity/) and [xclip](http://sourceforge.net/projects/xclip/) installed to use the GUI implementation.

I say above that this is "Linux" and "zenity" based, but it should be usable on any platform with OpenSSL. This means it should work on *BSD, Linux 2 through 3, Cygwin, and OS X (again, pull requests, especially usability and cross-platform work, welcome).

Mathematical Details
--------------------

The password is protected by [HMAC](https://en.wikipedia.org/wiki/HMAC)ing the parameter with your master password as the key. HMAC is a way of constructing verifiable hashes out of basic hash functions, and has so far even resisted attacks that have broken the hashes inside it, like MD5. The hash function used is hashapass is [SHA-1](https://en.wikipedia.org/wiki/SHA-1).


For security, your _master password_ should not be used anywhere except for hashapass, and should not be written down. Hashapass offers zero theoretical security if your master password is recovered from the LinkedIn database dump or by a malicious Facebook employee.


## The Competition

* [pwdhash](http://pwdhash.com) - _js_ - incompatible (par Stanford University Cryptographer [Dan Boneh](https://crypto.stanford.edu/~dabo/)
who was one of the founding instructors of Coursera)
* [hap](https://github.com/sitaramc/hap) - _perl + bash_
* [hap2](https://github.com/sitaramc/hap2) - _perl + bash_ - incompatible, probably stronger
* [ecin's](https://github.com/ecin/hashapass.rb/blob/master/hashapass.rb) - _ruby_
* [emacs-hashapass](https://github.com/ekpneo/emacs-hashapass) - _elisp_ - for emacs
* [pdf rainbow encryptor](https://github.com/ant4g0nist/rainbow.py) - _python + pdftk_ - custom purpose

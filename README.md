hashapass
=========

Linux implementation of http://hashapass.com (zenity and shell-based).

In a world of shortening attention spans and exploding password use, most people use one password across several accounts,
making common attacks like the [LinkedIn hack](FIXME) and the [PS3 break-in](FOXYOU) vicious,
or obsessively use distinct passwords everywhere,
requiring them to keep an insecure copy on paper or in an online password manager.
**Hashapass** is the best of both worlds, mathematically protecting your many distinct passwords with a single master password,
_**and not recording them anywhere**_.

[Hashapass](http://hashapass.com/en/index.html) was originally written by [?????????????????](FIXME).

To start to use hashapass, get yourself in the habit of signing up for new accounts with it:
when you make an account, take the domain name of the site, or some other string that the site
reminds you of (for example, I used "lj" for livejournal, and I use "github.com" for github),
and enter it as the "parameter" in hashapass. Then type your _master password_,
click the button, and give **the result** it gives to the site you are signing up for as your new password.

Every time you need to log in again, just repeat these steps.
You only need to remember your master password, and you never need to write down anything.

After you do this for while it becomes second nature, and it will be smooth to change your older passwords to
hashapass form on your next change cycle (you do change your passwords regularly, right?).

If you do need to change an account password later for some reason then you can modify the parameter you use, e.g. "github.com" -> "github.com2" (though you could also come up with a second master password).

## Paranoia

But after you have done this for a while, you might start to wonder if you can trust hashapass. Indeed, some people do:

["God I hope this isn't backdoored"](https://play.google.com/store/apps/details?id=com.hashapass.androidapp&reviewId=Z3A6QU9xcFRPRkRfbkk3aE1nWnZyN2ZmQU1hcFBDdlRNSm9xVnFfQnBscG9YdWxNeHQ3TXBFRUkzcUI3b0ZITjctN0Z5VnYtcnZSRktiR1dLaXRTMS1DcUNR)

Sure, you can [view the source](http://hashapass.com/en/index.js), but it has been minified since it was first written.
The web interface is convenient but the site doesn't use SSL so you as a user of it are very vulnerable to a MITM'd inserting code that records passwords as they are constructed,
and anyway might crash, run out of funding, electricity or chutzpah any day.

The site provides a [bookmarklet](http://hashapass.com/en/bookmarklet.html), but that only works for websites, many of those websites
break the bookmarklet is activated but trying to be more clever than the web (I'm looking at you, wikispaces; you aren't the only offender, though),
and it is impossible to use the bookmarklet to e.g. sign in to an ssh account.

You can save the [mobile edition](http://hashapass.com/en/phone.html) to your desktop, but that requires spawning
a browser with a javascript engine to use--no good if X has crashed on you and you need to login to your remote site to recover a backup.

**This implementation is my safety net against all of these worries**: it runs locally and the core* uses only basic, open-source, cryptography tools:
```
  hashed_pass=$(echo -n $parameter \
        | openssl dgst -sha1 -binary -hmac $password \
        | openssl enc -base64)
```
[* from the original author](http://hashapass.com/en/cmd.html)



## Usage

```
usage: hashapass [-l] [-s] [parameter]


-l    output "long" passwords: 28 characters (224 bits). By default, output 8 char (64 bit) passwords, which is hashapass.com's version.
-s    "show" the password: display it when it has been computed; if this is not given, just write the password to the system clipboard; if xclip is not installed, -s is automatically on.
parameter   if given on the command line, does not ask for it

```

You can use this script either on the command line, where it will use `read` to ask for input, or
from a a GUI (e.g. a .desktop file or by the Gnome/KDE command launcher).

You might want to add
```
alias hashapass="hashapass -l"
```
to your `.profile` to use long passwords by default. The only reason short passwords are default is that I used web- hashapass for so long that almost all of my passwords are in short hashapass format and changing them now would be a pain.

The quickest way to use this in daily linux desktop use is to make sure `zenity` is installed,
then memorize this key sequence:  
`ctrl-F2` + `hashapass site.com` + `[enter]` + `[password]` + `[enter]`. Note that there is a small security risk here:
a user (eg a virus) that has the ability to run `ps -auxww` will be able to see your parameters (but not your master password and not your generated passwords) and,
if hmac is some day compromised, could reverse engineer your passwords.

You must have [openssl](https://www.openssl.org/)'s command line interface installed, but if you don't have that your linux is crippled and you should reinstall.
You must have [zenity](https://help.gnome.org/users/zenity/) and [xclip](http://sourceforge.net/projects/xclip/) installed to use the GUI implementation.

Some sites have extra rules for their passwords like required amount of punctuation or letters.
[These sites are assholes](http://xkcd.com/936/).
My workaround for them is to keep a `passwords.txt` which **only** lists those sites and for each 
**only** records `hashapass(assholesite.com)+"2#"` where "2#" is whatever addition assuaged their rules.

Pull requests welcome!

## Mathematical Details

The password is protected by [HMAC](https://en.wikipedia.org/wiki/HMAC)ing the parameter with your master password as the key.

[pwdhash](http://pwdhash.com)---by Stanford University Cryptographer [Dan Boneh](https://crypto.stanford.edu/~dabo/)
who was one of the founding teachers in Coursera--is the same idea with different (and incompatible) details.

For security, your _master password_ should not be used anywhere except for hashapass, and should not be written down. Hashapass offers zero theoretical security if your master password is recovered from the LinkedIn database dump or by a malicious Facebook employee.


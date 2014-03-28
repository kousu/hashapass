hashapass
=========

Linux implementation of http://hashapass.com (zenity and shell-based).

In a world of shortening attention spans and exploding password use, most people use one password across several accounts,
making common attacks like the [LinkedIn hack](FIXME) and the [PS3 break-in]() vicious, or obsessively use distinct passwords
everywhere, requiring them to keep an insecure copy on paper or in an online password manager.
Hashapass is the best of both worlds, mathematically protecting your many distinct passwords with a single master password,
**and not recording them anywhere**.

[Hashapass](http://hashapass.com/en/index.html) was originally written by [?????????????????](FIXME).

To start to use hashapass, you get yourself in the habit of signing up for new accounts with it. When you make an account,
take the domain name of the site, or some other string that the site reminds you of (for example, I used "lj" for livejournal, and I use "github.com" for github),
and enter it as the "parameter" in hashapass. Then type your master password, and click the button. _Take_ the result it gives,
and paste it into the site you are signing up for as your new password.

But after you have done this for a while, you might start to wonder if you can trust hashapass. Indeed, some people do:

["God I hope this isn't backdoored"](https://play.google.com/store/apps/details?id=com.hashapass.androidapp&reviewId=Z3A6QU9xcFRPRkRfbkk3aE1nWnZyN2ZmQU1hcFBDdlRNSm9xVnFfQnBscG9YdWxNeHQ3TXBFRUkzcUI3b0ZITjctN0Z5VnYtcnZSRktiR1dLaXRTMS1DcUNR)

Sure, you can [view the source](http://hashapass.com/en/index.js), but it has been minified since it was first written.
And if you are using it via the web interface, then every time you need to use it you need to load this site,
which doesn't use SSL and so could be MITM'd to insert code that recorded all passwords constructed with it,
and anyway might be taken offline any day. This implementation is my safety net.

Hashapass provides a [bookmarklet](http://hashapass.com/en/bookmarklet.html), but that only works for websites, many of those websites
break the bookmarklet is activated but trying to be more clever than the web (I'm looking at you, wikispaces; you aren't the only offender, though),
and it is impossible to use the bookmarklet to e.g. sign in to an ssh account.

You can save hashapass's [mobile edition](http://hashapass.com/en/phone.html) to your desktop, but that requires spawning
a browser with a javascript engine to use--no good if X has crashed on you and you need to login to your remote site to recover
a backup.

The core of this script is [from the original author](http://hashapass.com/en/cmd.html) and only uses basic, open-source cryptography tools:
```
hashapass() {
  #from http://hashapass.com/en/cmd.html
  parameter=$1
  password=$2
  hashed_pass=$(echo -n $parameter \
        | openssl dgst -sha1 -binary -hmac $password \
        | openssl enc -base64)
  if [ $LONG ]; then
    echo $hashed_pass
  else
    echo $hashed_pass | cut -c 1-8
  fi
}
```



## Usage

```
usage: hashapass [-l] [-s] [parameter]


-l    output "long" passwords: 28 characters (224 bits). By default, output 8 char (64 bit) passwords, which is hashapass.com's version.
-s    "show" the password: display it when it has been computed; if this is not given, just write the password to the system clipboard; if xclip is not installed, -s is automatically on.
parameter   if given on the command line, does not ask for it

```

You can use this script either on the command line, where it will use `read` to ask for input, or
from a a GUI (e.g. a .desktop file or by the Gnome/KDE command launcher).

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

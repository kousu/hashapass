#!/usr/bin/env bash
#hashapass: implement the algorithm from hashapass.com as a shell script
#nick@kousu.ca, Sep 8, 2013 -- 2015
#public domain <http://creativecommons.org/publicdomain/zero/1.0/>

#usage: hashapass [-l] [-s] [parameter]
# hashapass combines a 'parameter' (imagine a username, website, favourite quote...)
# with a secret password to generate another associated password. In this way
# you can have one hard master password that you memorize and never ever write 
# down or tell anyone yet any number of *distinct* subsidiary passwords for
# each website or account you maintain.
#
# Like sudo, the master password is always read interactively. If you insist on
# weakening your security by writing down passwords in scripts, write down the
# generated password, not the master password.
# (if you have another use case that needs reading from stdin, submit an issue)
# 
# Provide your parameter and master password, and find your hashed pass
# in your X CLIPBOARD.
# If you aren't running X, don't have xclip, or you give -s,
# this will display the password *instead of* using the clipboard.
#
# Being diligent about separating your passwords in this way will leave you safe while everyone else is crying when yet another site gets hacked and acco means that you'll be sitting pretty while everyone else is crying, like these fine specimens
#  * Sony PS3: TODO
#  * LinkedIn: TODO
#
# This program implements the particular algorithm from hashapass.com, but
# pwdhash.com is the same idea with different--tho incompatble--details. Both
# sites have handy Android apps. The former is $1 in the Play Store. The
# latter is libre and free.
#
# This program works both from a command line or--with the help of zenity(1)--
#  under X. If you run it from a terminal you will get a terminal interface. 
#  if you run it otherwise--eg from Gnome's Alt-F2 menu or a system .desktop file--it will attempt to use Zenity to get your parameter.
#
# If you provide the parameter on the command line, this program will forego -- use this to make favourite buttons or just be able to rattle off hashapasses slightly faster
# -s		show generated password
#
# requirements:
#   bash(?)
#   openssl
#   zenity [OPTIONAL] (for GUI interface)
#   xclip [OPTIONAL]
# 
# [ ] don't use zenity; instead use `gksu -p`; alternately, patch zenity to do screen grabbing during --password dialogs
# [ ] read master password from
#   [ ] a keyring
#   [ ] a file
#   [x] stdin (UNSAFE, depending on how the user does it)
#   [ ] on the command line (UNSAFE).
#  then you could log in, unlocked your password hashes, and not actually have to type your master password anywhere.
# [-] implement variant algorithms, e.g. hmac-sha256, hmac-sha3, hmac-ripemd160. See: https://github.com/kousu/hashapass/pull/1
# [-] bulk hashing (tho why you would want this I don't know)
# [ ] clear the clipboard automatically, suggestion from @matlink: https://github.com/matlink/hashapass/commit/c6950c032d440c2ba04a3f19545b4707c6ce50c6
# [ ] Normalize on spaces (not tabs)
# [ ] i18n
# [ ] Figure out how to distinguish between being run from the GUI (e.g. dmenu, Alt-F2 in Gnome, or a .desktop file) and having stdin piped to us
#     In the stdin case, give an error, since by design we refuse to read passwords non-interactively

usage() {
  echo "Usage:" "hashapass [-l] [-s] [parameter]"
}

#there is getopt and there is getopts. fml.
while getopts "hsl" opt; do
#echo "currently parsing argument '$opt'"

case "$opt" in
  h)
  USAGE=true;;
  s)
  #echo "SHOW turned on"
  SHOW=true;;
  l)
  #echo "LONG turned on"
  LONG=true;;
  *)
  #echo "Unknown option '$opt'";
  exit -1;;
esac
done
shift $((OPTIND-1)) #eat everything

if ! which xclip 1>/dev/null; then  #check if we can use xclip
  echo "Warning: xclip not found in \$PATH. You should install xclip so that we do not need to display your password openly." >/dev/stderr
  SHOW=true;
fi;
if [ ! $DISPLAY ]; then   #check if we can use the clipboard, which only works if X is running
  SHOW=true;
fi

if [ $USAGE ]; then
  usage;
  exit 0;
elif [ $# -gt 1 ]; then
  echo -n "Too many parameters.  "
  usage;
  exit -1;
elif [ $# -eq 1 ]; then
  parameter=$1
fi


if tty -s; then
  # we're on the command line, use `read`
  if [ -z "$parameter" ]; then
    read -p "[hashapass] Parameter: " parameter;
  fi
  
  read -s -p "[hashapass] Master Password: " password
  echo >/dev/stderr   #add a newline after the nonechoing password input above
else
  if which zenity >/dev/null && [ $DISPLAY ]; then
    # we're in a GUI (e.g. dmenu, a .desktop button or via Gnome/KDE's Alt-F2): use `zenity`
    if [ -z "$parameter" ]; then
      if ! parameter=$(zenity --entry --title "hashapass" --text "Parameter: "); then
        exit 1;
      fi
    fi
	
    if ! password=$(zenity --password --title "hashapass" --text "Master Password: "); then
      exit 1;
    fi;
  else
    # see TODO above about this section
    # (in short: this *should* trigger when the user tries to pipe in to us;
    #  instead it triggers only when they pipe into us when not running X or if missing zenity)
    echo "hashapass will not read passwords non-interactively."
    # (that would defeat the purpose of hashapass, afterall; if the user
    # is that insistent, they can explicitly save to a plain text file)
    exit 1;
  fi
fi

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

result=$(hashapass $parameter $password)


P=true #whether to print or not.
       #to support scripting, *always* print when not on a tty
       # and when on a tty, *only* hide when user has not specified show
       #XXX does this leak password results into loggers unintentionally?? what is that socket
if [ -t 1 ]; then
  if [ -z $SHOW ]; then
    unset P
  fi
fi

if [ $P ]; then
  echo $result
fi


if [ ! -t 0 ]; then
  if [ $SHOW ]; then
     zenity --info --text "$result" --title "hashapass: Hashed Password"
  fi
fi

# okay, how about: *always* print to stdout except for if stdout is a tty 

echo -n $result | xclip -selection clipboard -i >/dev/null # dumping xclip's stdout to the bitbucket works around xclip's failure to properly daemonize  
                                                           # *when run in a $() subshell*, xclip inherits the pipe the parent is reading values off and thus hangs the process.  
                                                           # proper patch in review at https://sourceforge.net/p/xclip/patches/9/  

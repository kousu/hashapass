#!/bin/bash
#hashapass: implement the algorithm from hashapass.com as a shell script
#nick@kousu.ca, Sep 8, 2013
#public domain <http://creativecommons.org/publicdomain/zero/1.0/>

#usage: hashapass [-l] [-s] [parameter]
# hashapass combines a 'parameter' (imagine a username, website, favourite quote...)
# with a secret password to generate another associated password. In this way
# you can have one hard master password that you memorize and never ever write 
# down or tell anyone yet any number of *distinct* subsidiary passwords for
# each website or account you maintain.
# 
# Just provide your parameter and master password, and find your hashed pass
# in your X CLIPBOARD.
# If you aren't running X and/or don't have xclip installed, and/or you pass -s,
# will show the password on the command line to you.
#
# Being diligent about separating your passwords in this way will leave you safe while everyone else is crying when yet another site gets hacked and acco means that you'll be sitting pretty while everyone else is crying, like these fine specimens
#  * Sony PS3:
#  * LinkedIn: 
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
#requirements: bash(?), openssl, xclip, zenity (for GUI interface)
# 
# TODO: read master password from a keyring, from a file, from stdin (UNSAFE, depending on how the user does it), or on the command line (UNSAFE). then you could log in, unlocked your password hashes, and not actually have to type your master password anywhere.
# TODO: implement pwdhash
# TODO: clean up the if trees--maybe functional can help? 
#       maybe have to rewrite in python to get this fully nice..
# TODO: bulk hashing (tho why you would want this


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

if [ $USAGE ]; then
  usage;
  exit 0;
elif [ $# -gt 1 ]; then
  echo -n "Too many parameters.  "
  usage;
  exit -1;
elif [ $# -eq 1 ]; then
  parameter=$1
  #echo "PARAM:" $1 #DEBUG
# if this isn't set, ask for the parameter
 #echo "uhh, we'll ask for the param I guess"
fi


if tty -s; then
	if [ ! $parameter ]; then read -p "Parameter: " parameter; fi
	read -s -p "Master Password: " password
	echo   #add a newline after the nonechoing password input above

else #we're being called by a button or something--: use zenity
	if [ $parameter ]; then
		if password=$(zenity --password --text "Master Password: "); then
			echo happy > /dev/null
		else
			exit 1;
	 	fi;
	else
		if parameter=$(zenity --entry --text "Parameter: ";) &&
		   password=$(zenity --password --text "Master Password: "); then
			echo happy > /dev/null
		else
			exit 1;
	 	fi;
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


if which xclip 1>/dev/null; then              #check if xclip is on the system;5B;5B;5B;5B
  echo -n $result | xclip -selection clipboard;
else
  SHOW=true;
fi;

if [ $SHOW ]; then
  if tty -s; then
    echo $result;
  else
    zenity --info --text "$result" --title "Hashed Password"
  fi
fi


#zenity --text $result --info #useful as a debugging tool? or for other uses? hmm

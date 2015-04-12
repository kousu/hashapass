#!/bin/sh
# run this via dmenu or Alt-F2 to exercise hashapass.sh

Z=$(hashapass hidden) #when used in scripts, 
zenity --info --text "Hidden Result: $Z"

Z=$(hashapass -s shown)
zenity --info --text "Shown Result: $Z"

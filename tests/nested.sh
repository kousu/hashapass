#!/bin/sh

# this exercises a strange case wof the interaction of hashapass (really, xclip) and bash:
# a $() subshell doesn't exit until xclip does. But if you run hashapass by itself on the command line, it exits fine. What gives?

echo "-------------------------"
echo "Calling hashapass"

F=$(echo nested.sh: $$ >&2; ls -l /proc/$$/fd >&2; #$$ is the root bash PID, in a chain of subshells; use this so we can compare what the child sees to what the parent sees *simultaneously*
    echo nested subshell: $BASHPID >&2; ls -l /proc/$BASHPID/fd >&2;

    hashapass -s hello

    echo xclip: `pgrep xclip` >&2; ls -l /proc/`pgrep xclip`/fd >&2;
   )

echo "hashapass result: $F"

echo "-------------------------"


exit #avoid parsing the paste below:

It turns out that the bug isn't about processes (which is why I was so confused: in pstree you can see that xclip has daemonized itself and been reparented to init)
disown/nohup did nothing for me, even `disown -a`
it's about *file descriptors*. the clue was in http://web.archive.org/web/20120914180018/http://www.steve.org.uk/Reference/Unix/faq_2.html#SEC16 (via http://stackoverflow.com/questions/3095566/linux-daemonize):
 and the code at http://code.activestate.com/recipes/278731-creating-a-daemon-the-python-way/.

When run in a $() subshell, the subshell makes a pipe and connects it to
the subshell's stdout, which is what it reads to do the substitution.
as you can see in the example: pipe:[283654], which "nested.sh" has r-x on and everyone else has -wx on

*xclip inherits this pipe*.

A rule about pipes is that many processes can pour into it at once, and as long as anyone has and end open, the reader(s) do do not see EOF.
So xclip holding the pipe is a Bad Thing. It means that as long as xclip is alive, the parent shell cannot proceed because it thinks there's more output coming.
 I would even put this down to a bug in xclip: xclip (in its default mode) is daemonizing itself but *not very well*.
 If it did it properly, it would not be holding open any writeables. There's no excuse though, because there's the daemon() routine which does all the busywork.
instead it does this:
```
    /* fork into the background, exit parent process if we
     * are in silent mode
     */
    if (fverb == OSILENT) {
        pid_t pid;

        pid = fork();
        /* exit the parent process; */
        if (pid)
            exit(EXIT_SUCCESS);
    }
```
which is exactly the sort of code that explains why daemon() was invented.


[kousu@galleon hashapass]$ ./tests/nested.sh
-------------------------
Calling hashapass
nested.sh: 31298
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:26 0 -> /dev/pts/1
lrwx------ 1 kousu kousu 64 Apr 12 02:26 1 -> /dev/pts/1
lrwx------ 1 kousu kousu 64 Apr 12 02:26 2 -> /dev/pts/1
lr-x------ 1 kousu kousu 64 Apr 12 02:26 255 -> /home/kousu/pro/hashapass/tests/nested.sh
lr-x------ 1 kousu kousu 64 Apr 12 02:26 3 -> pipe:[283654]
nested subshell: 31299
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:26 0 -> /dev/pts/1
l-wx------ 1 kousu kousu 64 Apr 12 02:26 1 -> pipe:[283654]
lrwx------ 1 kousu kousu 64 Apr 12 02:26 2 -> /dev/pts/1
[hashapass] Master Password: 
HASHAPASS: 31302
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:26 0 -> /dev/pts/1
l-wx------ 1 kousu kousu 64 Apr 12 02:26 1 -> pipe:[283654]
lrwx------ 1 kousu kousu 64 Apr 12 02:26 2 -> /dev/pts/1
lr-x------ 1 kousu kousu 64 Apr 12 02:26 255 -> /home/kousu/pro/hashapass/hashapass.sh
displaying result AB5voMVp
running xclip
xclip is now running
[[[(note: xclip gets run with  `echo -n $result | xclip -selection clipboard -i` ]]]
xclip: 31315
total 0
lr-x------ 1 kousu kousu 64 Apr 12 02:26 0 -> pipe:[283659]
l-wx------ 1 kousu kousu 64 Apr 12 02:26 1 -> pipe:[283654]
lrwx------ 1 kousu kousu 64 Apr 12 02:26 2 -> /dev/pts/1
lrwx------ 1 kousu kousu 64 Apr 12 02:26 3 -> socket:[282633]
^C [hangs here, at least until xclip dies (e.g. pkill xclip or just simply copy something else so it shuts itself down), at which point it continues identically]


Now, if instead we call xclip as
  echo -n $result | xclip -selection clipboard -i >/dev/null
(don't be confused by the pipe numbers changing; they change because this is a different instance)
[kousu@galleon hashapass]$ ./tests/nested.sh
-------------------------
Calling hashapass
nested.sh: 32332
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:49 0 -> /dev/pts/2
lrwx------ 1 kousu kousu 64 Apr 12 02:49 1 -> /dev/pts/2
lrwx------ 1 kousu kousu 64 Apr 12 02:49 2 -> /dev/pts/2
lr-x------ 1 kousu kousu 64 Apr 12 02:49 255 -> /home/kousu/pro/hashapass/tests/nested.sh
lr-x------ 1 kousu kousu 64 Apr 12 02:49 3 -> pipe:[289508]
nested subshell: 32333
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:49 0 -> /dev/pts/2
l-wx------ 1 kousu kousu 64 Apr 12 02:49 1 -> pipe:[289508]
lrwx------ 1 kousu kousu 64 Apr 12 02:49 2 -> /dev/pts/2
[hashapass] Master Password: 
HASHAPASS: 32336
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:49 0 -> /dev/pts/2
l-wx------ 1 kousu kousu 64 Apr 12 02:49 1 -> pipe:[289508]
lrwx------ 1 kousu kousu 64 Apr 12 02:49 2 -> /dev/pts/2
lr-x------ 1 kousu kousu 64 Apr 12 02:49 255 -> /home/kousu/pro/hashapass/hashapass.sh
displaying result AB5voMVp
running xclip
[[[(note: xclip gets run with  `echo -n $result | xclip -selection clipboard -i >/dev/null` ]]]
xclip is now running
xclip: 32349
total 0
lr-x------ 1 kousu kousu 64 Apr 12 02:49 0 -> pipe:[289513]
l-wx------ 1 kousu kousu 64 Apr 12 02:49 1 -> /dev/null
lrwx------ 1 kousu kousu 64 Apr 12 02:49 2 -> /dev/pts/2
lrwx------ 1 kousu kousu 64 Apr 12 02:49 3 -> socket:[294613]
[[ previously it hung here. not it outputs: ]]
hashapass result: AB5voMVp
-------------------------




I changed xclip to call daemon() and now it looks like:
[kousu@galleon hashapass]$ ./tests/nested.sh
-------------------------
Calling hashapass
nested.sh: 32356
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:53 0 -> /dev/pts/2
lrwx------ 1 kousu kousu 64 Apr 12 02:53 1 -> /dev/pts/2
lrwx------ 1 kousu kousu 64 Apr 12 02:53 2 -> /dev/pts/2
lr-x------ 1 kousu kousu 64 Apr 12 02:53 255 -> /home/kousu/pro/hashapass/tests/nested.sh
lr-x------ 1 kousu kousu 64 Apr 12 02:53 3 -> pipe:[298000]
nested subshell: 32357
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:53 0 -> /dev/pts/2
l-wx------ 1 kousu kousu 64 Apr 12 02:53 1 -> pipe:[298000]
lrwx------ 1 kousu kousu 64 Apr 12 02:53 2 -> /dev/pts/2
[hashapass] Master Password: 
HASHAPASS: 32360
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:53 0 -> /dev/pts/2
l-wx------ 1 kousu kousu 64 Apr 12 02:53 1 -> pipe:[298000]
lrwx------ 1 kousu kousu 64 Apr 12 02:53 2 -> /dev/pts/2
lr-x------ 1 kousu kousu 64 Apr 12 02:53 255 -> /home/kousu/pro/hashapass/hashapass.sh
displaying result AB5voMVp
running xclip
xclip is now running
xclip: 32373
total 0
lrwx------ 1 kousu kousu 64 Apr 12 02:53 0 -> /dev/null
lrwx------ 1 kousu kousu 64 Apr 12 02:53 1 -> /dev/null
lrwx------ 1 kousu kousu 64 Apr 12 02:53 2 -> /dev/null
lrwx------ 1 kousu kousu 64 Apr 12 02:53 3 -> socket:[294614]
hashapass result: AB5voMVp
-------------------------
[kousu@galleon hashapass]$ 

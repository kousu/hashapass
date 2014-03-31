TODO
====

* Write tests
* Fix the FIXME links in README.md
* Investigate if it's worth supporting explicit salts
* Investigate if, instead of salting, running hashapass in a loop makes sense
  (so, the salt to remember becomes $n$, the number if iterations, which is easier for a user to guess and check so that they needn't write it down)
* Reflow long lines and reindent if necessary
* Parse the usual [openbsd flamewar](http://marc.info/?l=openbsd-misc&m=138625020303992&w=2) on the subject for security tips

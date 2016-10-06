#!/bin/sh
ls -lAR $pwd|grep ^-|sort -nrk 5,5|cat  -n|head -n 5 | awk '{print $1":"$6" "$10}'|sed '5a\'$'\n'"Dir num: $(ls -lAR $(pwd)|grep -c ^d)\\"$'\n'"File num:$(ls -lAR $(pwd)|grep -c ^-)\\"$'\n'"Total: $(ls -lAR $(pwd)|grep ^-|awk '{print $5}'|paste -sd+ -|bc)"$'\n'

#!/bin/sh
ls -lAR ./ |grep ^-|sort -nrk 5,5|cat  -n|head -n 5 | awk '{print $1":"$6" "$10}'|sed '$a\'$'\n'"Dir num: $(ls -lAR ./ |grep -c ^d)\\"$'\n'"File num:$(ls -lAR ./ |grep -c ^-)\\"$'\n'"Total: $(ls -lAR ./ |grep ^-|awk '{print $5}'|paste -sd+ -|bc)"$'\n'

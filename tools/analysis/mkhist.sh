#!/bin/bash

touch proj/$proj_name/4_analysis/docking/histogram_fine
while read line
do
be=$(echo $line | cut -d ' ' -f 4)
if [ -n "$(cat proj/$proj_name/4_analysis/docking/histogram_fine | grep \\$be)" ]; then
hits=$(grep \\$be proj/$proj_name/4_analysis/docking/histogram_fine | cut -d ' ' -f 2)
let "nhits = $hits + 1"
sed -i -e "s/$be $hits/$be $nhits/g" proj/$proj_name/4_analysis/docking/histogram_fine
else
echo "$be 1" >> proj/$proj_name/4_analysis/docking/histogram_fine
fi
done < proj/$proj_name/4_analysis/docking/logs.csv


i=1
while [ $i -le 9 ]; do
a=$(cat proj/$proj_name/4_analysis/docking/histogram_fine | grep "\-$i.*" | cut -d ' ' -f 2 | paste -s -d+ - | bc)
echo "-$i $a" >> proj/$proj_name/4_analysis/docking/histogram_clustered
let "i++"
done

a=0
while read line; do
if [ $(echo "$(echo $line | cut -d ' ' -f 1) <= -10" | bc -l) = 1 ]; then
let a+=$(echo $line | cut -d ' ' -f 2)
fi
done < proj/$proj_name/4_analysis/docking/histogram_fine
echo "-10 $a" >> proj/$proj_name/4_analysis/docking/histogram_clustered


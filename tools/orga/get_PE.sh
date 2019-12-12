#!/bin/bash

list=0
for MD in $(ls -d proj/*/1_MD/*); do
list="${list}+$(grep "Core hours" $MD/1_MD/out/LOG_feedback | tr -s ' ' | cut -d ' ' -f 4)"
done

for dock in $(ls -d proj/*/3_docking/*); do
cd $dock
for ddock in $(ls -d docking/*); do
list="${list}+$(grep "Core hours" $ddock/out/LOG_feedback | tr -s ' ' | cut -d ' ' -f 4)"
done
cd ../../../..
done

echo "Core hours: $(echo $list | tr -s '+' | bc -l)"

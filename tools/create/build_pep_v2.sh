#!/bin/bash

seqfile=$1
ss=$2

while read line
do
arr=(${line%$'\r'})
name=${arr[0]}
sequ=${arr[1]}

if [ ! -z ${arr[2]} ]; then
if [ ${arr[2]} == 'H' ]; then
ss=1
elif [ ${arr[2]} == 'S' ]; then
ss=2
fi
fi

echo "fab ${sequ}, ${name}, ss=$ss" > tmp
echo "save ${name}.pdb" >> tmp

pymol -kcQ -d @tmp

rm tmp

if [ -f .pdb ]
then
rm ./.pdb
fi

mv ${name}.pdb pdb

done < ./$seqfile
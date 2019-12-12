#!/bin/bash

proj_name=$1
name=$2
cutoff=$3

lim=$4

named=$name

cd proj/$proj_name/2_clustering
v=$(ls | grep $name)
if [ -z $v ]; then
named+=_1
mkdir $named
else
n=$(ls | grep $name | wc -l)
let n++
named+=_$n
mkdir $named
echo "Creating cluster as ${named}."
fi
cd $named
pwd

gmx cluster -f ../../1_MD/${name}/1_MD/out/${name}_MD.pdb -o rmsd-clust.xpm -g clust.log -s ../../1_MD/${name}/1_MD/out/md_0_1.tpr -cl ${name}_clusters.pdb -sz clust-size.xvg -cutoff $cutoff <<eof
1
1
eof

if [ ! -z $(cut -d ':' -f 1 <<< $lim) ]; then
# number
number=$(cut -d ':' -f 1 <<< $lim)
grep -v '^#\|^@' clust-size.xvg | sort -nk 2,2 | tac > sort
i=1
while read -a arr && [ $i -le $number ]; do
let i++
echo ${arr[0]}
echo "load ${name}_clusters.pdb" > tmp
echo "save ${name}_clusters_${arr[0]}.pdb, state=${arr[0]}" >> tmp
pymol -kcQ -d @tmp
done < sort
rm sort
elif [ ! -z $(cut -d ':' -f 2 <<< $lim) ]; then
# percentage 
percentage=$(cut -d ':' -f 2 <<< $lim)
let "pp=$percentage*10"

declare -i frames=0
declare -a clusters

while read a b
do
frames=$(( $b + $frames ))
clusters+=($b)
done < <(grep -v '^#\|^@' clust-size.xvg)

declare -i structure

i=1
for structure in ${clusters[@]}
do
part=$(bc <<< "scale=0; 1000 * $structure / $frames")
#echo $part
if [ $part -gt $pp ]
then
#echo "$i $structure"
echo "load ${name}_clusters.pdb" > tmp
echo "save ${name}_clusters_${i}.pdb, state=${i}" >> tmp
pymol -kcQ -d @tmp
fi

#echo ${clusters[@]}
(( i+=1 ))
done
fi
rm tmp
cd ../../../..

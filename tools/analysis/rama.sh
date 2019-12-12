#!/bin/bash

# Ramachandran plot
gmx rama -f md_0_1.xtc -s md_0_1.tpr

mkdir analysis
mkdir analysis/xvg
mv *.xvg ./analysis/xvg
cd analysis

# Plot Ramachandran plot from the whole peptide

echo "reset" > plot_rama.gpl
echo "set terminal png transparent size 1920,1800 font \",30\"" >> plot_rama.gpl
echo "set output 'Rama_'$folder'.png'" >> plot_rama.gpl
echo "set datafile commentschar \"#@&\"" >> plot_rama.gpl
echo "set key right" >> plot_rama.gpl
echo "set xrange [-180:180]" >> plot_rama.gpl
echo "set yrange [-180:180]" >> plot_rama.gpl
echo "set xlabel 'phi / °'" >> plot_rama.gpl
echo "set ylabel 'psi / °'" >> plot_rama.gpl
echo "plot \\" >> plot_rama.gpl
echo "'rama.xvg' u 1:2 w points pt 7 ps 1 lc rgb 'black' title '$folder', \\" >> plot_rama.gpl

# Make a clear xvg file without comments and get all the AA of a ligand, filled in array as

as=()
grep ^[^#@] ./xvg/rama.xvg > ./xvg/rama_c.xvg
while read line
do
arr=($line)
if [ "${arr[2]}" != "${as[0]}" ]
then
as+=(${arr[2]})
else
break
fi
done < ./xvg/rama_c.xvg
echo ${as[@]}

# Gnuplot all AS

mkdir gnuplot

i=1
for AS in ${as[@]}
do
echo "" > ./gnuplot/${i}_$AS.xvg
grep $AS ./xvg/rama_c.xvg >> ./gnuplot/${i}_${AS}_tmp.xvg

I=1
while read line
do
arrr=($line)
arrr+=($I)
echo ${arrr[@]} >> ./gnuplot/${i}_$AS.xvg
let "I=I+1"
done < ./gnuplot/${i}_${AS}_tmp.xvg
rm ./gnuplot/${i}_${AS}_tmp.xvg

cd gnuplot

echo "
reset
set terminal png transparent size 2150,1800 font \",30\"
set output '${i}_${AS}_rama.png'
set datafile commentschar \"#@&\"
set key right

set palette defined (0 'black', 500 'green', 1000 'blue' )

set size 1,1
set xrange [-180:180]
set yrange [-180:180]
set xlabel 'phi / °'
set ylabel 'psi / °'
plot \
'${i}_${AS}.xvg' u 1:2:((\$4)-1) w points pt 7 ps 3 lc palette title  '$AS', \
" > ${i}_${AS}_rama.gpl

gnuplot ${i}_${AS}_rama.gpl

cd ..

let "i=i+1"
done

mv ./gnuplot/*.xvg ./xvg/
mkdir png
mv ./gnuplot/*.png ./png/


cd ..

if [ ! -d ../../../../4_analysis/$MD ]; then
mkdir ../../../../4_analysis/$MD
fi
mkdir ../../../../4_analysis/$MD/rama
cp analysis/png/*.png ../../../../4_analysis/$MD/rama/
cp ${MD}_MD.pdb ../../../../4_analysis/$MD/

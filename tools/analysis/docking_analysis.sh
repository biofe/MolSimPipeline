#!/bin/bash

# create missing directories

if [ ! -d proj/$proj_name/4_analysis/docking ]; then
mkdir proj/$proj_name/4_analysis/docking
fi

if [ -f proj/$proj_name/4_analysis/docking/logs.csv ]; then
for file in $(ls proj/$proj_name/4_analysis/docking/*.csv); do
mv $file $file.old
done
fi

# read out the log files

if [ $threshold = 1 ]; then
for dock in $(ls proj/$proj_name/3_docking); do
for ddock in $(ls proj/$proj_name/3_docking/$dock/docking); do
cat proj/$proj_name/3_docking/$dock/docking/$ddock/out/*.log | grep "^   [0-9]" >> .tmp_log
while read line; do
echo "$dock $ddock $(echo $line | tr -s ' ' | cut -d ' ' -f 1-2)" >> proj/$proj_name/4_analysis/docking/logs.csv
done < .tmp_log
rm .tmp_log
done
done
else
for dock in $(ls proj/$proj_name/3_docking); do
for ddock in $(ls proj/$proj_name/3_docking/$dock/docking); do
cat proj/$proj_name/3_docking/$dock/docking/$ddock/out/*.log | grep "^   [0-9]" >> .tmp_log
while read line; do
if [ $(echo "$(echo $line | tr -s ' ' | cut -d ' ' -f 2) <= $threshold" | bc -l) -eq 1 ]; then
echo "$dock $ddock $(echo $line | tr -s ' ' | cut -d ' ' -f 1-2)" >> proj/$proj_name/4_analysis/docking/logs.csv
fi
done < .tmp_log
rm .tmp_log
done
done
fi

# generate sticks from helices

tools/analysis/split_pdb.sh
tools/analysis/mkhist.sh

# generate histograms

len=$(cat proj/$proj_name/4_analysis/docking/logs.csv | wc -l)
cp tools/analysis/plot_hist proj/$proj_name/4_analysis/docking/
sed -i -e "s/PROJ/$proj_name/g" proj/$proj_name/4_analysis/docking/plot_hist
sed -i -e "s/NUMBER/$len/g" proj/$proj_name/4_analysis/docking/plot_hist

cp tools/analysis/plot_hist_clust proj/$proj_name/4_analysis/docking/
sed -i -e "s/PROJ/$proj_name/g" proj/$proj_name/4_analysis/docking/plot_hist_clust
sed -i -e "s/NUMBER/$len/g" proj/$proj_name/4_analysis/docking/plot_hist_clust

cd proj/$proj_name/4_analysis/docking
gnuplot plot_hist
gnuplot plot_hist_clust
cd ../../../..

# get min and max value

min=0
max=-20
while read line; do
be=$(echo $line | cut -d ' ' -f 1)
if [ $(echo "$min > $be" | bc -l) -eq 1 ]; then
min=$be
fi
if [ $(echo "$max < $be" | bc -l) -eq 1 ]; then
max=$be
fi
done < proj/$proj_name/4_analysis/docking/histogram_fine

abs_min=$(echo $min | tr -d '-')
abs_max=$(echo $max | tr -d '-')

# create PyMOL session

cd proj/$proj_name/4_analysis/docking
recs=($(ls ../../3_docking/$dock/receptor/*))
srecs=($(i=0; for rec in ${recs[@]}; do basename ${recs[i]} .pdb; let i++; done))

for file in $(ls states); do
echo "load states/$file" >> .tmp
done
echo "spectrum b, blue_red, minimum=$abs_min, maximum=$abs_max" >> .tmp
for rec in ${recs[@]}; do
srec=$(echo $rec | cut -d '/' -f 6 | cut -d '.' -f 1)
echo "load $rec
color white, $srec" >> .tmp
done
echo "save rec_sticks.pse
" >> .tmp
pymol -kcQ -d @.tmp
rm .tmp
cd ../../../..

# create histogram for all dockings

awk '{a[$1]=a[$1] FS $4}END{for(i in a)print i,a[i]}' proj/$proj_name/4_analysis/docking/logs.csv | tr -d '-' > proj/$proj_name/4_analysis/docking/logs_trans

cp tools/analysis/plot_histogram proj/$proj_name/4_analysis/docking/
sed -i -e "s/MAX/$abs_min/g" proj/$proj_name/4_analysis/docking/plot_histogram
cd proj/$proj_name/4_analysis/docking
gnuplot plot_histogram
cd ../../../..
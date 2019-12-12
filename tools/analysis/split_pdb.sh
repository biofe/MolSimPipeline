#!/bin/bash

j=1
export j

if [ ! -d proj/$proj_name/4_analysis/docking/states ]; then
mkdir proj/$proj_name/4_analysis/docking/states
fi
while read line; do
dock=$(cut -d ' ' -f 1 <<< $line)
ddock=$(cut -d ' ' -f 2 <<< $line)
be=$(cut -d ' ' -f 4 <<< $line)
export be
mdl=$(cut -d ' ' -f 3 <<< $line)
if [ $(echo "scale=3;$be < $threshold" | bc -l) -eq 1 ]; then
name=$(ls proj/$proj_name/3_docking/$dock/docking/$ddock/out/*.log | cut -d '.' -f 1 | cut -d '/' -f 8)
cat proj/$proj_name/3_docking/$dock/docking/$ddock/out/${name}.pdbqt | awk "/MODEL $mdl/,/ENDMDL/" | awk "/ROOT/,/ENDROOT/" > proj/$proj_name/4_analysis/docking/.${dock}_${ddock}_${mdl}.pdbqt
tools/analysis/get_stick.sh .${dock}_${ddock}_${mdl}.pdbqt
#rm .${name}_${mdl}.pdbqt
let j++
fi
done < proj/$proj_name/4_analysis/docking/logs.csv
#done
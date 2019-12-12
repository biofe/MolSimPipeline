#!/bin/bash

#read -p "Filename: " filename
filename=$1
filenameb=$(basename $filename .pdbqt)

XN=($(grep " N   " proj/$proj_name/4_analysis/docking/$filename | cut -c 32-38))
YN=($(grep " N   " proj/$proj_name/4_analysis/docking/$filename | cut -c 40-46))
ZN=($(grep " N   " proj/$proj_name/4_analysis/docking/$filename | cut -c 48-54))

X1=$(echo "scale=3; (${XN[1]} + ${XN[3]}) / 2" | bc -l)
Y1=$(echo "scale=3; (${YN[1]} + ${YN[3]}) / 2" | bc -l)
Z1=$(echo "scale=3; (${ZN[1]} + ${ZN[3]}) / 2" | bc -l)

X2=$(echo "scale=3; (${XN[-4]} + ${XN[-2]}) / 2" | bc -l)
Y2=$(echo "scale=3; (${YN[-4]} + ${YN[-2]}) / 2" | bc -l)
Z2=$(echo "scale=3; (${ZN[-4]} + ${ZN[-2]}) / 2" | bc -l)

if [ $(echo "$X1 > $X2" | bc -l) -eq 1 ]; then
Xd=$(echo "scale=3; ${X1} - ${X2}" | bc -l)
else
Xd=$(echo "scale=3; ${X2} - ${X1}" | bc -l)
fi

if [ $(echo "$Y1 > $Y2" | bc -l) -eq 1 ]; then
Yd=$(echo "scale=3; ${Y1} - ${Y2}" | bc -l)
else
Yd=$(echo "scale=3; ${Y2} - ${Y1}" | bc -l)
fi

if [ $(echo "$Z1 > $Z2" | bc -l) -eq 1 ]; then
Zd=$(echo "scale=3; ${Z1} - ${Z2}" | bc -l)
else
Zd=$(echo "scale=3; ${Z2} - ${Z1}" | bc -l)
fi

Vabs=$(echo "scale=3; sqrt(${Xd}^2 + ${Yd}^2 + ${Zd}^2)" | bc -l)

Xr=$(echo "scale=3; $Xd / $Vabs * 1.5" | bc -l)
Yr=$(echo "scale=3; $Yd / $Vabs * 1.5" | bc -l)
Zr=$(echo "scale=3; $Zd / $Vabs * 1.5" | bc -l)

if [ $(echo "$X1 > $X2" | bc -l) -eq 1 ]; then
wX="+"
else
wX="-"
fi
Xl=$X2
Xh=$X1

if [ $(echo "$Y1 > $Y2" | bc -l) -eq 1 ]; then
wY="+"
else
wY="-"
fi
Yl=$Y2
Yh=$Y1

if [ $(echo "$Z1 > $Z2" | bc -l) -eq 1 ]; then
wZ="+"
else
wZ="-"
fi
Zl=$Z2
Zh=$Z1

Xs=$Xl
Ys=$Yl
Zs=$Zl

# b factor / binding energy
bes=$(echo $be | tr -d '-')
bes=$(echo "scale=2; $bes * 1.00" | bc -l)
spacebe=$(echo "$bes" | cut -d '.' -f 1 | wc -c)
let "spacebes=10-$spacebe"

line="$Xs $Ys $Zs"

spacea=$(echo "$line" | cut -d ' ' -f 1 | cut -d '.' -f 1 | wc -c)
spaceb=$(echo "$line" | cut -d ' ' -f 2 | cut -d '.' -f 1 | wc -c)
spacec=$(echo "$line" | cut -d ' ' -f 3 | cut -d '.' -f 1 | wc -c)
let "spacex=31-$spacea"
let "spacey=5-$spaceb"
let "spacez=5-$spacec"

echo "ATOM$(printf "%${spacex}s")$(echo "$line" | cut -d ' ' -f 1)$(printf "%${spacey}s")$(echo "$line" | cut -d ' ' -f 2)$(printf "%${spacez}s")$(echo "$line" | cut -d ' ' -f 3)$(printf "%${spacebes}s")$(echo "$bes")$(printf "%11s")C  " >> proj/$proj_name/4_analysis/docking/states/sticks_$j.pdb

i=0

while [ $(echo "$Vabs - 4 > $i" | bc -l) -eq 1 ]; do
Xs=$(echo "scale=3; $Xs $wX $Xr" | bc -l)
Ys=$(echo "scale=3; $Ys $wY $Yr" | bc -l)
Zs=$(echo "scale=3; $Zs $wZ $Zr" | bc -l)

line="$Xs $Ys $Zs"

spacea=$(echo "$line" | cut -d ' ' -f 1 | cut -d '.' -f 1 | wc -c)
spaceb=$(echo "$line" | cut -d ' ' -f 2 | cut -d '.' -f 1 | wc -c)
spacec=$(echo "$line" | cut -d ' ' -f 3 | cut -d '.' -f 1 | wc -c)
let "spacex=31-$spacea"
let "spacey=5-$spaceb"
let "spacez=5-$spacec"

echo "ATOM$(printf "%${spacex}s")$(echo "$line" | cut -d ' ' -f 1)$(printf "%${spacey}s")$(echo "$line" | cut -d ' ' -f 2)$(printf "%${spacez}s")$(echo "$line" | cut -d ' ' -f 3)$(printf "%${spacebes}s")$(echo "$bes")$(printf "%11s")C  " >> proj/$proj_name/4_analysis/docking/states/sticks_$j.pdb

let i++
done
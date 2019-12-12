#!/bin/bash

i=$1

cat $i | grep -E 'HETATM|ATOM' | cut -c 32-38 | sort -gk 1 > .sortx
cat $i | grep -E 'HETATM|ATOM' | cut -c 40-46 | sort -gk 1 > .sorty
cat $i | grep -E 'HETATM|ATOM' | cut -c 48-54 | sort -gk 1 > .sortz

minx=$(head -n 1 .sortx)
maxx=$(tail -n 1 .sortx)
size_x=$(echo "scale=3; $maxx - $minx" | bc -l)

miny=$(head -n 1 .sorty)
maxy=$(tail -n 1 .sorty)
size_y=$(echo "scale=3; $maxy - $miny" | bc -l)

minz=$(head -n 1 .sortz)
maxz=$(tail -n 1 .sortz)
size_z=$(echo "scale=3; $maxz - $minz" | bc -l)

off_x=$(echo "scale=3; $minx + $size_x / 2" | bc -l)
off_y=$(echo "scale=3; $miny + $size_y / 2" | bc -l)
off_z=$(echo "scale=3; $minz + $size_z / 2" | bc -l)

size_x=$(echo "scale=3; $size_x + 30" | bc -l)
size_y=$(echo "scale=3; $size_y + 30" | bc -l)
size_z=$(echo "scale=3; $size_z + 30" | bc -l)

rm .sortx .sorty .sortz

echo "
center_x = $off_x
center_y = $off_y
center_z = $off_z

size_x = $size_x
size_y = $size_y
size_z = $size_z
"

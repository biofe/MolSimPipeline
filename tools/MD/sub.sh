#!/bin/bash

#PBS -l nodes=X:ppn=X
#PBS -l walltime=XX:XX:XX
#PBS -S /bin/bash
#PBS -N SIMNAME
#PBS -j oe
#PBS -o LOG

echo ""
echo "my Username is:"
whoami
echo "My job is running on node:"
uname -a

cd SERVPATH/USERNAME/PROJNAME/lignamd
module load chem/gromacs

#This script runs the commands from the Lysozyme tutorial: http://www.mdtutorials.com/gmx/lysozyme/01_pdb2gmx.html

name='ligname'
ff='amber99sb-ildn-fme'
water='spce'
bt='dodecahedron' #triclinic, cobic, dodecahedron, octahedron

grep -v HOH ${name}.pdb > ${name}_clean.pdb
gmx pdb2gmx -f ${name}_clean.pdb -o ${name}_processed.gro -water $water -ff $ff -ignh
gmx editconf -f ${name}_processed.gro -o ${name}_newbox.gro -c -d BOXSIZE -bt $bt
gmx solvate -cp ${name}_newbox.gro -cs spc216.gro -o ${name}_solv.gro -p topol.top
gmx grompp -f ions.mdp -c ${name}_solv.gro -p topol.top -o ions.tpr
gmx genion -s ions.tpr -o ${name}_solv_ions.gro -p topol.top -pname NA -nname CL -neutral <<eof #choose group "SOL" (13 or 16, depends on version of GMX)
13
eof
gmx grompp -f minim.mdp -c ${name}_solv_ions.gro -p topol.top -o em.tpr
gmx mdrun -gcom 2 -deffnm em
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -gcom 2 -deffnm nvt
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -gcom 2 -deffnm npt
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
gmx mdrun -gcom 2 -deffnm md_0_1
gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center <<eof
1
0
eof
gmx trjconv -s md_0_1.tpr -f md_0_1_noPBC.xtc -o lignamd_MD.pdb <<eof
1
eof

#!/bin/bash

#PBS -l nodes=1:ppn=1
#PBS -l walltime=WALLTIME
#PBS -S /bin/bash
#PBS -N dock
#PBS -j oe
#PBS -o LOG

echo ""
echo "my Username is:"
whoami
echo "My job is running on node:"
uname -a
cd SERVPATH/USERNAME/PROJECT/DOCKING/PAIR
module load chem/autodockvina/1.1.2
module load chem/mgltools
pythonsh /opt/bwhpc/common/chem/mgltools/1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py -r RECEPTOR.pdb -A bonds_hydrogens -U nphs -o RECEPTOR.pdbqt
pythonsh /opt/bwhpc/common/chem/mgltools/1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py -l LIGAND.pdb -A bonds_hydrogens -U nphs -MODE -o LIGAND.pdbqt
vina --config CONFIG --exhaustiveness EXHAUSTIVENESS --receptor RECEPTOR.pdbqt --ligand LIGAND.pdbqt --out LIGAND_Ex-EXHAUSTIVENESS_FLEX.pdbqt --log LIGAND_Ex-EXHAUSTIVENESS_FLEX.log --num_modes 20 --energy_range 5

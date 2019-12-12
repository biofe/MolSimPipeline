# MolSimPipeline
The Molecular Simulation Pipeline simplifies molecular dynamics simulations with GROMACS and dockings with AutoDock Vina. Therefore it facilitates the communication to a computational cluster and performs simulations on a cluster with simple commands. Further, it provides some analysis methods.

```txt
Manual Molecular Simulation Pipeline

Commands

PROJ

NAME
	proj – handles projects

SYNOPSIS
	proj [OPTION] [PROJECTNAME]

DESCRIPTION
	Creates new projects, sets project name, deletes projects and move
	and restore them to the archive. A list of the existing projects can
	also be created.

	-l
		lists all exisiting projects in the structure (recent ones an
		the ones from the archive).

	-n PROJNAME
		create a new project and generate the nessesary, even in the
		workspace.

	-s PROJNAME
		set the project name you want to work with.

	-a PROJNAME
		archives a project. You‘ll find all files from the project in
		the archive, also the ones from the cluster.

	-r PROJNAME
		restore a project from the archive. All files will be in their
		common places

	-d PROJNAME
		deletes the whole project from the working directories, archive
		and from the cluster. You need to confirm a deletion.



CREATE

NAME
	create - generates structures de novo via pymol

SYNOPSIS
	create [OPTION] [FILENAME]

DESCRIPTION
	Generates PDB-files from a sequence file with pymol. Each line of the
	sequence file contains one peptide. The first column defines the name,
	the secound the sequence and the third may contain an H or S which	
	defines the secondary structure of the drawn peptide. Make sure you use
	space characters as delimiter and that there's an ampty line in the end
	of the document.

	-f
		defines the sequence file name. If not defined the program
		searches for a file named 'sequences'. You pass the sequence
		file via the input folder.

	-x
		if not other defined in the sequence file, all sequences are
		drawn as helix.

	-s
		if not other defined in the sequence file, all sequences are
		drawn as sheet.


ADMIN_CLUSTER

NAME
	admin_cluster - administrates the information from the cluster

SYNOPSIS
	admin_cluster [OPTION]

DESCRIPTION
	admin_cluster checks the states of the uploaded simulations. In case
	they have finished it downloads and deletes them from the cluster.
	Further it provides the qstat from the file and can provide a short
	report over the running simulations.

	-c
		checks the recent state of the simulations and downloads them
		in case the have finished. Further you'll find a recent qstat
		file

	-r
		prints out a report over the running simulations. See the
		file 'report'


MD

NAME
	MD - starts MD simulations

SYNOPSIS
	MD [OPTION] [ARG]

DESCRIPTION
	Starts MD simulations with the provided parameters. It passes the
	simulation files to the cluster and starts it.

	-t, --simtime
		defines the simulation time in ns. Default: 1 ns

	-w, --walltime
		walltime; After this time the simulation will be interrupted

	-b, --boxsize
		boxsize of the water box in A. Default: 1.0 A

	-N, --pepname
		name of th file of which the MD shall be performed. The file is
		passed via the input/pdb folder. If the option is not chosen a
		MD simulation of all the files in the input/pdb folder will be
		done.

	-m, --simname
		name which is shown in the qstat, so it's not important.
		Default: md

	-n, --nodes
		number of nodes for the simulation. Default: 1

	-p, --cpu
		number of cpus for the simulatoin. Default: 10

	-g, --gcom
		gcom value - every n steps the processors will comunicate.
		Increasing this might accelerate the simulation


CLUSTERING

NAME
	clustering - clusters the result of a MD simulation

SYNOPSIS
	clustering [OPTION] [ARG]

DESCRIPTION
	Condenses the structures obtained by MD. It concentrates structures in
	one due to a lower RMSD value than the cutoff. After clustering it cuts
	out the most important structures from the cluster.

	-c, --cutoff
		defines the cutoff for the RMSD value. Default: 0.12

	-n, --number
		number of largest clusters that will be cut out in seperate
		files.

	-p, --percentage
		percentage of all structures obtained by MD a cluster must
		reach to be extracted

	-s, --structure
		structure of the MD folder which will be clustered. If option
		not chosen every MD will be clustered with this parameters.


LTOD

NAME
	LtoD - inverts a peptide

SYNOPSIS
	LtoD [OPTION] [NAME]

DESCRIPTION
	Inverts a peptide from L to D or D to L. Tho output folder is
	proj/proj_name/pdb

	-c, --clustering
		takes all extracted structures of a cluster given by it's name
		and cluster number and inverts it.

	-n, --name
		with this option you can pass a list of pdb files you provide
		in the input/pdb folder. All this files will be inverted.


DOCK

NAME
	dock - docks two peptides

SYNOPSIS
	dock [OPTION] [ARG]

DESCRIPTION
	With this function dockings are performed. You can define single files
	or whole folders of pdb files as receptor or ligand. Vina is a protein
	ligand docking program. This is why you have to define a rezeptor and a
	ligand. The program creates a gridbox of 5 A around the receptor and
	docks the ligand with flexible or rigid sidechains.

	-n, --name
		name of the docking.

	-rp, --rproj
		needs to be set when the receptor is sourced from another
		project.

	-lp, --lproj
		needs to be set when the ligand is sourced from another
		project.

	-r, --rezeptor
		name of the cluster which sould be set as receptor followed by
		the number of the cluster.

	-l, --ligand
		name of the cluster which sould be set as ligand followed by
		the number of the cluster.

	-ri, --rinput
		the receptor will be obtained from the input/pdb folder. You
		need to specify the name of the file or just type in 'all' to
		set all .pdb files from the input directory as receptors.

	-ri, --rinput
		the ligand will be obtained from the input/pdb folder. You
		need to specify the name of the file or just type in 'all' to
		set all .pdb files from the input directory as ligands.

	-rb, --rpdb
		the receptor will be obtained from the proj/pdb folder. You
		need to specify the name of the file or just type in 'all' to
		set all .pdb files from the input directory as receptors.

	-lb, --lpdb
		the ligand will be obtained from the proj/pdb folder. You
		need to specify the name of the file or just type in 'all' to
		set all .pdb files from the input directory as ligands.

	-e, --exhaustiveness
		set the exhaustiveness value for the entire docking.

	-f, --flexibility
		with r or f the flexibility of the ligand's sidechains is set
		to rigid or flexible.

	-w, --walltime
		walltime of the run.
```

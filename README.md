# MolSimPipeline
The Molecular Simulation Pipeline simplifies molecular dynamics simulations with GROMACS and dockings with AutoDock Vina. Therefore it facilitates the communication to a computational cluster and performs simulations on a cluster with simple commands. Further, it provides some analysis methods.

## Dependencies on the cluster
* [GROMACS](http://www.gromacs.org/)
* [AutoDock Vina](http://vina.scripps.edu/)
* [MGLTools](http://mgltools.scripps.edu/)
* [PyMOL (Open Source)](https://github.com/schrodinger/pymol-open-source)

### Other requirements on the cluster
* Established passwordless ssh login
* qsub command for queueing scripts
* qstat to obtain queue stats

## Dependencies on the local computer
* [GROMACS](http://www.gromacs.org/)
* [MGLTools](http://mgltools.scripps.edu/)
* [PyMOL (Open Source)](https://github.com/schrodinger/pymol-open-source)
* [GNUPlot](http://www.gnuplot.info/)
* [python3](https://www.python.org/)

## Installation
```bash
git clone https://github.com/ortzt/MolSimPipeline.git
```

## Setup
* In the file 'main.sh' the servername (server='login@server.com') and the absolute path to the working directory on the server (servpath='/root/path/on/server/to/working/dir') must be changed.
* A Username directory must exist or manually created in the working directory on the server
## Usage
cd into the ```MolSimPipelin``` directory and run the script with ```./main.sh```. For the usage visit the [USAGE](https://github.com/ortzt/MolSimPipeline/blob/master/USAGE) file.

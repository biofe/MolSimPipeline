#!/bin/bash

server='login@server.com' # login@server.com
servpath='/root/path/on/server/to/working/dir' # /root/path/on/server/to/working/dir

noerror=true
dock=""
export dock

duration="" # tiny, short, long

export proj_name

chmod -R 774 ./tools

checktree() {
if [ ! -d archive ]
then
mkdir archive
fi
if [ ! -d input ]
then
mkdir input
fi
if [ ! -d out ]
then
mkdir out
fi
if [ ! -d proj ]
then
mkdir proj
fi
ssh $server "
cd $servpath/${username}
if [ ! -d finished ]
then
mkdir finished
fi
exit
"
}

conbin() {
ssh -i ~/$key_file $server "exit"
}

# time in, -d, -h, -m, -s out
times() {
a=$(awk -F ":" '{print NF-1}' <<< $2)
let "col = $a + 1"
while [ ! -z $1 ]
do
case "$1"
in
-d) shift
if [ $col -eq 3 ]; then
h=$(echo $1 | cut -d ':' -f $(( $col - 2 )))
echo $(( $h / 24 ))
else
echo $1 | cut -d ':' -f $(( $col - 3 )); fi;;
-H) shift; h=$(echo $1 | cut -d ':' -f $(( $col - 2 ))); echo $(( $h % 24 ));;
-h) shift; echo $1 | cut -d ':' -f $(( $col - 2 ));;
-m) shift; echo $1 | cut -d ':' -f $(( $col - 1 ));;
-s) shift; echo $1 | cut -d ':' -f $(( $col - 0 ));;
\?);;
esac
shift
done
}

duration() {
t=$1
d=$(times -d $t)
h=$(times -H $t)
m=$(times -m $t)
s=$(times -s $t)
let "sum=(($d*24+$h)*60+$m)*60+$s"
if [ $sum -le 1200 ]; then
duration="tiny"
elif [ $sum -le 172800 ]; then
duration="short"
elif [ $sum -le 604800 ]; then
duration="long"
else
duration="fail"
fi
}

# mkcfg calls a script which genereates a config file for a docking

mkcfg() {
./tools/docking/conf.sh ./proj/${proj_name}/3_docking/${dock_name}/receptor/${rec} proj/3_docking/${dock_name}/docking/${srec}_vs_${slig}/rec_${rec}
}

proj() {
usage() { echo "Usage: proj [-n <name> | -a <name> | -d <name> | -s <name>] | -r <name>] | -l]";  }

while getopts n:a:d:s:r:l option
do
case "${option}"
in

# lists all projects
l) 
b=true
if [ -n "$(ls archive/*/)" ]; then
ls -d archive/*/
b=false
fi
if [ -n "$(ls proj/*/)" ]; then
ls -d proj/*/
b=false
fi
if $b; then
echo "No projects found."
fi;;

# creates a new project and sets it to recent project name
n) if [ -d proj/${OPTARG} ]; then
echo "Project '${OPTARG}' exists already in the workspace."
elif [ -d archive/${OPTARG} ]; then
echo "Project '${OPTARG}' exists already in the archive."
else
proj_name=${OPTARG}
mkdir input/${proj_name} input/${proj_name}/pdb out/${proj_name} proj/${proj_name} proj/${proj_name}/1_MD proj/${proj_name}/2_clustering proj/${proj_name}/3_docking proj/${proj_name}/4_analysis proj/${proj_name}/pdb
ssh $server "mkdir $servpath/${username}/${proj_name}"
echo "All necessary folders have been created and the project name was set to '$proj_name'."
fi;;

# archives a project (moves all files to the archive folder)
a) if [ -d input/${OPTARG} ]; then
mkdir archive/${OPTARG} archive/${OPTARG}/input archive/${OPTARG}/proj archive/${OPTARG}/out archive/${OPTARG}/cluster archive/${OPTARG}/finished
mv proj/${OPTARG}/* archive/${OPTARG}/proj
mv input/${OPTARG}/* archive/${OPTARG}/input
scp -rCB $server:$servpath/${username}/${OPTARG}/ ./archive/${OPTARG}/cluster/
scp -rCB $server:$servpath/${username}/finished/${OPTARG}/ ./archive/${OPTARG}/finished/
ssh $server "rm -r $servpath/${username}/${OPTARG}"
if [ -s out/${OPTARG}/* ]; then
mv out/${OPTARG}/* archive/${OPTARG}/out
fi
rm -r proj/${OPTARG} input/${OPTARG} out/${OPTARG}
echo "Project '${OPTARG}' has been successfully moved to the archive."
elif [ -d archive/${OPTARG} ]; then
echo "Project '${OPTARG}' is already archived!"
else
echo "Project '${OPTARG}' doesn't exist!"
fi;;

# deletes a project from workspace and archive
d) read -p " < Do you really want to delete the whole project from the directories 'archive', 'proj', 'input' and 'out'? (y/n) " -a del
if [ $del = y ]; then
if [ -d archive/${OPTARG} ]; then rm -r archive/${OPTARG}
echo "All files from the project '${OPTARG}' have successfully been deleted from the archive."
elif [ -d proj/${OPTARG} ]
then
rm -r proj/${OPTARG}
rm -r input/${OPTARG}
rm -r out/${OPTARG}
ssh $server "rm -r $servpath/${username}/${OPTARG}"
echo "All files from the project '${OPTARG}' have successfully been deleted from the working directory."
else
echo "There's nothing to delete: project doesn't exist!"
fi
else
echo "Nothing has been deleted."
fi;;

# set a project to the recent project name
s) if [ -d proj/${OPTARG} ]; then
proj_name=${OPTARG}; echo "Project name set to '${proj_name}'"
elif [ -d archive/${OPTARG} ]; then
echo "The project '${OPTARG}' is archived. Use 'proj -r <name>' to restore it from the archive."
else
echo "Project '${OPTARG}' doesn't exist"
fi;;

# restores a project from archive
r) if [ -d archive/${OPTARG} ]; then
mkdir proj/${OPTARG} input/${OPTARG} out/${OPTARG}
mv archive/${OPTARG}/proj/* proj/${OPTARG}
mv archive/${OPTARG}/input/* input/${OPTARG}
if [ -s out/${OPTARG}/* ]; then
mv archive/${OPTARG}/out/* out/${OPTARG}
fi
rm -r archive/${OPTARG}
proj_name=${OPTARG}
echo "Project '${proj_name}' has been restored successfully from the archive an the project name was set to."
elif [ -d proj/${OPTARG} ]; then
echo "The project '${OPTARG}' doesn't need to be restored, it's in the working directories."
else
echo "Project '${OPTARG}' doesn't exist"
fi;;

h) usage;;
*) usage;;
\?) usage ;;
esac
shift $((OPTIND -1))
done

}


upload() {
usage() { echo "Usage: upload [-m <name> | -d <dockname> <name> ]";  }

local a

while [ ! -z $1 ]
do
case "$1"
in

# uploads and runs the MD folder for a given system in the recent project; runs MD_run.sh
-m) shift;
ssh $server "mkdir $servpath/${username}/${proj_name}/${1}"
scp -rCB ./proj/${proj_name}/1_MD/${1}/1_MD/* $server:$servpath/${username}/${proj_name}/${1}/
ID=$(ssh $server "
cd $servpath/${username}/${proj_name}/${1}
qsub -q $duration sub.sh
" < /dev/null)

# grep ID in qstat an append it to log_jobs
a="$server \"
qstat -u fr_bd1032 | grep $ID | awk '{print \\\$7 \\\" \\\" \\\$10 \\\" \\\" \\\$11 \\\" \\\" \\\$9}'
\" < /dev/null"
b=$(eval $a)
line="${proj_name}/${1} $ID "
line+=${b}" M"
echo $line >> .log_jobs

mkdir ./proj/${proj_name}/1_MD/${1}/1_MD/in
cd ./proj/${proj_name}/1_MD/${1}/1_MD
mv $(ls | grep -v "^in") ./in
cd ../../../../..
shift;;


# uploads and runs the docking in the given folder from the recent project; runs sub.sh
-d) shift
ssh $server "
if [ ! -d $servpath/${username}/${proj_name}/$1 ]; then
mkdir $servpath/${username}/${proj_name}/$1
fi
if [ ! -d $servpath/${username}/${proj_name}/$1/$2 ]; then
mkdir $servpath/${username}/${proj_name}/$1/$2
fi" < /dev/null
scp -rCB ./proj/${proj_name}/3_docking/$1/docking/$2/* $server:$servpath/${username}/${proj_name}/$1/$2/
ID=$(ssh $server "
cd $servpath/${username}/${proj_name}/$1/$2
qsub -q $duration sub.sh
" < /dev/null)

# grep ID in qstat an append it to log_jobs
a="ssh $server \"
qstat -u fr_bd1032 | grep $ID | awk '{print \\\$7 \\\" \\\" \\\$10 \\\" \\\" \\\$11 \\\" \\\" \\\$9}'
\" < /dev/null"
b=$(eval $a)
line="${proj_name}/$1/$2 $ID "
line+=${b}" D"
echo $line >> .log_jobs

mkdir ./proj/${proj_name}/3_docking/$1/docking/$2/in
cd ./proj/${proj_name}/3_docking/$1/docking/$2
mv $(ls | grep -v "^in") ./in
cd ../../../../../..
shift
shift
;;

-h) usage;;
*) usage;;
\?) usage ;;
esac
done

}


admin_cluster() {
usage() { echo "
Usage: admin_cluster	[ -c ]	--- checks the state of running jobs and
				    downloads them in case they have been
				    finished
			[ -r ]	--- prints out a report
";  }

while [ ! -z $1 ]
do
case "$1"
in

-c|--check) # check and download: Checks the state of the sims in .log_jobs and downloads, if necessary the folders
shift
joblist=()
if [ -f .log_jobs ]; then
while read -a job
do
if [ ${job[3]} = 'R' ] || [ ${job[3]} = 'Q' ]; then
joblist+=(${job[1]})
fi
done < .log_jobs
ssh $server "
qstat -u fr_bd1032
" < /dev/null > qstat

declare -a jobscl=()
declare -i n=1
while read -a jcl
do
if [ $n -ge 6 ]
then
jobscl+=(${jcl[0]})
else
let n++
fi
done < qstat

# compares jobs listed in .log_jobs with qstat from the cluster. If a job
# exists in both lists, the states are compared. If it is completed or
# doesn't appear anymore in the qstat, the folder is downloaded and the
# line is deleted from .log_jobs file.

declare -a jobstodownload=()
for job in ${joblist[@]}
do
job_exist_in_both=0
for jobcl in ${jobscl[@]}
do
if [ $job = $jobcl ]
then
job_exist_in_both=1
fi
done

if [ ${job_exist_in_both} -eq 1 ]
then
state_job_cl=$(grep $job qstat | awk '{print $10}')
if [ $state_job_cl == 'R' ] || [ $state_job_cl == 'Q' ]
then
line=$(grep $job .log_jobs | awk '{print $1 " " $2 " " $3 " "}')
line+=$(grep $job qstat | awk '{print $10 " " $11 " " $9 " "}')
line+=$(grep $job .log_jobs | awk '{print $7}')
echo $line >> .log_jobs_new
elif [ $state_job_cl == 'C' ]
then
job_exist_in_both=0
fi
fi

# New if-statement necessary!!!
if [ ${job_exist_in_both} -eq 0 ]
then
sim=$(grep $job .log_jobs | awk '{print $7}')
tmp=$(grep $job .log_jobs | awk '{print $1}')
name=${tmp##*/}
if [ $sim == 'M' ]
then
name=$(grep $job .log_jobs | awk '{print $1}' | cut -d '/' -f 2)
loc_proj=$(grep $job .log_jobs | awk '{print $1}' | cut -d '/' -f 1)
mkdir ./proj/${loc_proj}/1_MD/${name}/1_MD/out
scp -rCB $server:$servpath/${username}/${loc_proj}/$name/* ./proj/${loc_proj}/1_MD/${name}/1_MD/out
ssh $server "
if [ ! -d $servpath/${username}/finished/${loc_proj} ]; then
mkdir $servpath/${username}/finished/${loc_proj}
fi
mv $servpath/${username}/${loc_proj}/$name/ $servpath/${username}/finished/${loc_proj}/
" < /dev/null
elif [ $sim == 'D' ]
then
loc_proj=$(grep $job .log_jobs | awk '{print $1}' | cut -d '/' -f 1)
dock_name_a=$(grep $job .log_jobs | awk '{print $1}' | cut -d '/' -f 2)
name_comp=$(grep $job .log_jobs | awk '{print $1}' | cut -d '/' -f 3)
mkdir ./proj/${loc_proj}/3_docking/${dock_name_a}/docking/${name_comp}/out
scp -rCB $server:$servpath/${username}/${loc_proj}/${dock_name_a}/${name_comp}/* ./proj/${loc_proj}/3_docking/${dock_name_a}/docking/${name_comp}/out/
ssh $server "
if [ ! -d $servpath/${username}/finished/${loc_proj} ]; then
mkdir $servpath/${username}/finished/${loc_proj}
fi
mv $servpath/${username}/${loc_proj}/${dock_name_a}/${name_comp}/ $servpath/${username}/finished/${loc_proj}/
" < /dev/null
fi
fi

done

mv .log_jobs .log_jobs_old
mv .log_jobs_new .log_jobs

else
echo "There are no own jobs to update!"
fi

#grep $ID qstat | awk '{print $1}'

;;

-r|--report) shift; echo "Simulation_name ID TSK S runtime req.time D/M" > report
cat .log_jobs >> report
cat report
;; # report

-h) shift; usage;;
*) shift; usage;;
\?) shift; usage ;;
esac
done
}

create() {
usage() { echo "Usage: create [-f <filename> | -x | -s ]";  }

seqfile=sequences
ss=1

while [ ! -z $1 ]
do
case "$1"
in

-f) shift; seqfile=${1} ; shift;;
-x) shift; ss=1;;
-s) shift; ss=2;;

-h) usage;;
*) usage;;
\?) usage ;;
esac
done
cd ./input/$proj_name
../../tools/create/build_pep_v2.sh $seqfile $ss
cd ../..
}

MD() {
usage() {
echo "
Usage:	MD [ -t | --simtime <n> ]	  --- simulation time; default: 1 ns
	   [ -n | --nodes <n> ]		  --- number of nodes; default: 1
	   [ -p | --cpu <n> ]		  --- number of cpus; default: 10
	   [ -N | --pepname <name> ]	  --- name of the file to be simulated,
					      if not specified, input from
					      input/pdb
	   [ -w | --walltime <00:00:00> ] --- estimated walltime for the
					      job / in auto-mode: for 1ns
	   [ -b | --boxsize <0.0> ]	  --- boxsize in A, default: 1.0
	   [ -g | --gcom <n> ]		  --- gcom value, default: 2
	   [ -m | --simname <name> ]	  --- simname - displayname in qstat;
					      default: md
"	#  [ -a | --auto ]		  --- auto-mode: runs 1 ns simulation and extrapolates then the runtime


}

simtime=500000 # xxxxxxx (7*x); 500000 = 1ns
stime=1 # simtime in ns
nodes=1 # nodes=X:ppn=X
ppn=10 # nodes=X:ppn=X
simname=md #SIMNAME
walltime=07:00:00 # walltime=XX:XX:XX
# ${username} <-> USERNAME
pepname="" # ligname <-> OPTARG ; default: input
boxsize="1.0" # BOXSIZE
gcom=2 # -gcom 2 <-> -gcom 4
auto=false
# duration: tiny, short, long

while [ ! -z $1 ]
do
case "$1"
in

-t|--simtime) shift; let "simtime = 500000 * $1"; stime=$1; shift;;
-n|--nodes) shift; nodes=$1; shift;;
-p|--cpu) shift; ppn=$1; shift;;
-N|--pepname) shift; pepname=$1; shift;;
-w|--walltime) shift; walltime=$1; shift;;
-m|--simname) shift; simname=$1; shift;;
-b|--boxsize) shift; boxsize=$1; shift;;
-g|--gcom) shift; gcom=$1; shift;;
-a|--auto) shift; auto=true;;

-h) shift; usage;;
*) usage;;
\?) usage ;;
esac
done

if [ -z $pepname ]; then
pepname=($(ls input/$proj_name/pdb))
fi
for name in ${pepname[@]}
do
nameb=$(basename $name .pdb)
named=$nameb
named+=_${stime}ns
mkdir proj/${proj_name}/1_MD/$named
mkdir proj/${proj_name}/1_MD/$named/1_MD
cp input/$proj_name/pdb/$name proj/${proj_name}/1_MD/$named/1_MD/
cp -r tools/MD/templ/* proj/${proj_name}/1_MD/$named/1_MD/
#cp tools/MD/sub*.sh proj/${proj_name}/1_MD/$nameb/1_MD/
cp tools/MD/sub.sh proj/${proj_name}/1_MD/$named/1_MD/

#sed -i -e "s/nodes=X/nodes=${nodes}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/nodes=X/nodes=${nodes}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/ppn=X/ppn=${ppn}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/ppn=X/ppn=${ppn}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/SIMNAME/${simname}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/SIMNAME/${simname}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/USERNAME/${username}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/USERNAME/${username}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/walltime=XX:XX:XX/walltime=${walltime}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/walltime=XX:XX:XX/walltime=${walltime}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/ligname/${nameb}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/ligname/${nameb}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/PROJNAME/${proj_name}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/PROJNAME/${proj_name}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#sed -i -e "s/BOXSIZE/${boxsize}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh


#if [ $gcom -ne 2 ]; then
#sed -i -e "s/-gcom 2/-gcom ${gcom}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh
#sed -i -e "s/-gcom 2/-gcom ${gcom}/g" proj/${proj_name}/1_MD/$nameb/1_MD/sub_main.sh
#fi

sed -i -e "s/nodes=X/nodes=${nodes}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/ppn=X/ppn=${ppn}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/SIMNAME/${simname}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/USERNAME/${username}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/walltime=XX:XX:XX/walltime=${walltime}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/ligname/${nameb}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/lignamd/${named}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/PROJNAME/${proj_name}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/BOXSIZE/${boxsize}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
sed -i -e "s/SERVPATH/${servpath}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh

if [ $gcom -ne 2 ]; then
sed -i -e "s/-gcom 2/-gcom ${gcom}/g" proj/${proj_name}/1_MD/$named/1_MD/sub.sh
fi

duration $walltime

if $auto; then
#sed -i -e "s/xxxxxxx/500000/g" proj/${proj_name}/1_MD/$nameb/1_MD/md.mdp
#mv proj/${proj_name}/1_MD/$nameb/1_MD/sub_pre.sh proj/${proj_name}/1_MD/$nameb/1_MD/sub.sh
duration $walltime
#upload -m $nameb

else
sed -i -e "s/xxxxxxx/$simtime/g" proj/${proj_name}/1_MD/$named/1_MD/md.mdp
upload -m $named
fi
done
}

clustering() {
usage() {
echo "
Usage: clustering [ -c | --cutoff <n> ]	    --- cutoff RMSD; default: 0.12 A
		  [ -n | --number <n> ]	    --- number of largest clusters to be
						extracted
		  [ -p | --percentage <n> ] --- percentage a cluster must reach
						to be extracted
		  [ -s | --structure ]	    --- structure of the MD folder, wich
						should be clustered
"
}

cutoff="0.12"
number=""
percentage=""
name=""

while [ ! -z $1 ]
do
case "$1"
in

-c|--cutoff) shift; cutoff=$1 ; shift;;
-n|--number) shift; number=$1; shift;;
-p|--percentage) shift; percentage=$1; shift;;
-s|--structure) shift; name=$1; shift;;

-h) usage;;
*) usage;;
\?) usage ;;
esac
done

if [ -z $name ]; then
cd ./proj/${proj_name}/1_MD
name=($(ls -d */ | cut -d '/' -f 1))
cd ../../..
fi

#echo $number
#echo $percentage

if [ -z $number ] && [ ! -z $percentage ]; then
for nam in ${name[@]}
do
./tools/clustering/clustering.sh $proj_name $nam $cutoff ${number}:${percentage}
done
elif [ ! -z $number ] && [ -z $percentage ]; then
for nam in ${name[@]}
do
./tools/clustering/clustering.sh $proj_name $nam $cutoff ${number}:${percentage}
done
else
echo "Improper combination of parameters (-n/-p)!"
fi

}

LtoD() {
usage() {
echo "
Usage: LtoD [ -c | --clustering <name> <n> ] --- mirrors the selected structures
						 from a given cluster; saves to
						 proj/proj_name/pdb
	    [ -n | --name <name> ]	     --- takes structure from input/pdb
						 and saves it to
						 proj/proj_name/pdb
"
}

cl_num=""
name=""

while [ ! -z $1 ]
do
case "$1"
in

-c|--clustering) shift; name=$1 ; shift; cl_num=$1; shift;
cd proj/$proj_name/pdb
for i in $(ls ../2_clustering/${name}_${cl_num}/${name}_clusters_*)
do
j=$(echo $i | cut -d '/' -f 4)
bi=$(basename $j .pdb)
python ../../../tools/LtoD/ltod.py $i ${bi}_D.pdb
done
cd ../../..
;;

-n|--name) shift;
#if [ ! -z $1 ]; then
while [ ! -z $1 ]; do
name=$1
nameb=$(basename $name .pdb)
shift
cp input/${proj_name}/pdb/$name proj/$proj_name/pdb/
cd proj/$proj_name/pdb
python ../../../tools/LtoD/ltod.py $name ${nameb}_D.pdb
rm $name
cd ../../..
done
#else
#mv input/${proj_name}/pdb/*.pdb proj/$proj_name/pdb/
#cd proj/$proj_name/pdb
#python ../../../tools/LtoD/ltod.py $name
#cd ../../..
#fi
;;

-h) shift; usage;;
*) shift; usage;;
\?) shift; usage ;;
esac
done

}

dock() {
usage() {
echo "
Usage: 	   dock	[ -n  | --name <name> ]		----- name your docking
		[ -rp | --rproj <name> ]	----- project of the receptor files; default: recent project
		[ -lp | --lproj <name> ]	----- project of the ligand files; default: recent project
		[ -r  | --receptor <name> <n> ]	----- defines cluster of receptors
		[ -l  | --ligand <name> <n> ]	----- defines cluster of ligands
		[ -ri | --rinput <name> ]	----- receptor is taken from input/pdb; if 'all' is passed, all .pdb files are chosen as receptors
		[ -li | --linput <name> ]	----- ligand is taken from input/pdb; if 'all' is passed, all .pdb files are chosen as ligands
		[ -rb | --rpdb <name> ]		----- receptor is in proj/pdb folder; pass 'all' to get the whole folder as receptors
		[ -lb | --lpdb <name> ]		----- ligand is in proj/pdb folder; pass 'all' to get the whole folder as ligands
		[ -e  | --exhaustiveness ]	----- default: 8
		[ -f  | --flexibility [ r | f ]	----- rigid / flexible sidechains; default: r
		[ -w  | --walltime <00:00:00> ]	----- expected runtime for one docking
"
}

exhaustiveness=8
flex="r"
walltime="00:15:00" # WALLTIME
dock_name="dock" # SIMNAME

rproj_name=$proj_name
lproj_name=$proj_name

r_in_meth=""
l_in_meth=""
r_in_name=""
l_in_name=""
r_cl_num=""
l_cl_num=""

confinput='false'
conffile="conf"
del=false

while [ ! -z $1 ]
do
case "$1"
in

-n|--name) shift; dock_name=$1; shift;;
-rp|--rproj) shift; rproj_name=$1; shift;;
-lp|--lproj) shift; lproj_name=$1; shift;;
-r|--receptor) shift; r_in_meth="c" ; r_in_name=${1}; r_cl_num=${2}; shift; shift;;
-l|--ligand) shift; l_in_meth="c" ; l_in_name=${1}; l_cl_num=${2}; shift; shift;;
-ri|--rinput) shift; r_in_meth="i" ; r_in_name=$1; shift;;
-li|--linput) shift; l_in_meth="i" ; l_in_name=$1; shift;;
-rb|--rpdb) shift; r_in_meth="p" ; r_in_name=$1; shift;;
-lb|--lpdb) shift; l_in_meth="p" ; l_in_name=$1; shift;;
-e|--exhaustiveness) shift; exhaustiveness=$1; shift ;;
-f|--flexibility) shift; flex=$1; shift ;;
-w|--walltime) shift; walltime=$1; shift ;;
-ci|--confinput) shift; confinput='true'; conffile=$1; shift;;

-d|--delete) shift;
while [ ! -z $1 ]; do
rm -r proj/$proj_name/3_docking/$1
shift
done
del=true ;;

-h) shift; usage;;
*) shift; usage;; 
\?) shift; usage ;;
esac
done

if ! $del; then

if [ ! -d proj/${proj_name}/3_docking/${dock_name} ]; then
mkdir proj/${proj_name}/3_docking/${dock_name} proj/${proj_name}/3_docking/${dock_name}/receptor proj/${proj_name}/3_docking/${dock_name}/ligand proj/${proj_name}/3_docking/${dock_name}/docking

rec_path=""
rec_list=()
case "$r_in_meth"
in

c) shift; rec_path="proj/${rproj_name}/2_clustering/${r_in_name}_${r_cl_num}"
prerec_list=($(ls ${rec_path}/${r_in_name}_clusters_*))
rec_list=${prerec_list[@]##*/}
;;
i) shift; rec_path="input/${rproj_name}/pdb"
if [ $r_in_name == "all" ]; then
prerec_list=($(ls ${rec_path}/*.pdb))
rec_list=${prerec_list[@]##*/}
else
rec_list=$r_in_name
fi ;;
p) shift; rec_path="proj/${rproj_name}/pdb"
if [ $r_in_name == "all" ]; then
prerec_list=($(ls ${rec_path}/*.pdb))
rec_list=${prerec_list[@]##*/}
else
rec_list=$r_in_name
fi ;;

*) echo "Improper combination of receptor input methods!"
esac

lig_path=""
lig_list=()
case "$l_in_meth"
in

c) shift; lig_path="proj/${lproj_name}/2_clustering/${l_in_name}_${l_cl_num}"
prelig_list=($(ls ${lig_path}/${l_in_name}_clusters_*))
lig_list=${prelig_list[@]##*/}
;;
i) shift; lig_path="input/${lproj_name}/pdb"
if [ $l_in_name == "all" ]; then
prelig_list=($(ls ${lig_path}/*.pdb))
lig_list=${prelig_list[@]##*/}
else
lig_list=$l_in_name
fi ;;
p) shift; lig_path="proj/${lproj_name}/pdb"
if [ $l_in_name == "all" ]; then
prelig_list=($(ls ${lig_path}/*.pdb))
lig_list=${prelig_list[@]##*/}
else
lig_list=$l_in_name
fi ;;

*) echo "Improper combination of ligand input methods!"
esac
cp ${rec_path}/*.pdb proj/${proj_name}/3_docking/${dock_name}/receptor/
cp ${lig_path}/*.pdb proj/${proj_name}/3_docking/${dock_name}/ligand/

#cp ${rec_list[@]} proj/${proj_name}/3_docking/${dock_name}/receptor
#cp ${lig_list[@]} proj/${proj_name}/3_docking/${dock_name}/ligand

if [ $flex == 'r' ]
then
mode='Z'
elif [ $flex == 'f' ]
then
mode='B'
else
echo 'Improper argument for flexibility!'
fi

for rec in ${rec_list[@]}
do
srec=$(basename $rec .pdb)
for lig in ${lig_list[@]}
do
slig=$(basename $lig .pdb)
mkdir proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}
cp proj/${proj_name}/3_docking/${dock_name}/receptor/${rec} proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/rec_${rec}
cp proj/${proj_name}/3_docking/${dock_name}/ligand/${lig} proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/lig_${lig}

if $confinput; then
cp ./input/${proj_name}/$conffile proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/
else
mkcfg proj/${proj_name}/3_docking/${dock_name}/receptor/${rec} > proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/conf
fi

# sub.sh
cp ./tools/docking/sub.sh ./proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/

sed -i -e "s/WALLTIME/${walltime}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/USERNAME/${username}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/PROJECT/${proj_name}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/DOCKING/${dock_name}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/EXHAUSTIVENESS/${exhaustiveness}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/MODE/${mode}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/FLEX/${flex}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/RECEPTOR/$(basename rec_$rec .pdb)/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/LIGAND/$(basename lig_$lig .pdb)/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/PAIR/${srec}_vs_${slig}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/CONFIG/${conffile}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh
sed -i -e "s/SERVPATH/${servpath}/g" proj/${proj_name}/3_docking/${dock_name}/docking/${srec}_vs_${slig}/sub.sh

duration $walltime

upload -d ${dock_name} ${srec}_vs_${slig}

done
done

else
echo "A docking with this name exists already!"
fi
fi
}

analysis() {

while [ ! -z $1 ]
do
case "$1"
in

-rama) shift
cd proj/$proj_name/1_MD
for MD in $(ls); do
export MD
cd $MD/1_MD/out
if [ ! -f ${MD}_MD.pdb ]; then
gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center <<eof
1
0
eof
gmx trjconv -s md_0_1.tpr -f md_0_1_noPBC.xtc -o 5kgy_1_50ns_MD.pdb <<eof
1
eof
fi
../../../../../../tools/analysis/rama.sh
cd ../../..
done ;;

-dock) shift
adname=all
threshold=1
export threshold
while [ ! -z $1 ]; do
case "$1"
in
-t) shift; threshold=$1; shift;;
-n) shift; adname=$1; shift;;
*) shift; echo "Improper argument!"; noerror=false; break;;
esac
done
if $noerror; then
#if [ $adname = "all" ]; then
#for dock in $(ls proj/$proj_name/3_docking); do
./tools/analysis/docking_analysis.sh
#done
#else
#./tools/analysis/docking_analysis.sh $adname
#fi
fi ;;

-h) shift; usage;;
*) shift; usage;; 
# \?) shift; usage ;;
esac
done

noerror=true

}

#clear

#conbin

checktree
echo ""
read -p "Username: " username
read -p "Project: " proj_name
export proj_name
while [ -z $(ls proj | grep $proj_name) ]; do
read -p "Project \"$proj_name\" doesn't exist.
Do you want to create it? (y/n): " crproj
if [ $crproj = "y" ]; then
echo "Project name set to '${proj_name}'"
eval proj -n $proj_name
else
read -p "Project: " proj_name
fi
done

echo ""
echo "Userinput:"

control() {
local func=()
# set -x
read -a func <<< $@
case ${func[0]} in
proj) eval ${func[@]} ;;
upload) eval ${func[@]} ;;
admin_cluster) eval ${func[@]} ;;
create) eval ${func[@]} ;;
duration) eval ${func[@]} ;;
MD) eval ${func[@]} ;;
clustering) eval ${func[@]} ;;
LtoD) eval ${func[@]} ;;
dock) eval ${func[@]} ;;
input) eval ${func[@]} ;;
analysis) eval ${func[@]} ;;
checktree) shift; checktree ;;
conbin) eval ${func[@]}; shift;;
core_hours) shift; tools/orga/get_PE.sh ;;
*) echo "Improper input!"
esac
# set +x
}

input() {
input_file="todo"
while [ ! -z $1 ]
do
case "$1"
in
-d|--default) shift;
while read -a ifunc
do
echo ${ifunc[@]}
control ${ifunc[@]}
done < ./input/${proj_name}/${input_file}
;;
-f|--file) shift; input_file=$1; shift;
while read -a ifunc
do
echo ${ifunc[@]}
control ${ifunc[@]}
done < ./input/${proj_name}/${input_file}
;;
-h) shift; usage;;
*) shift; usage;;
\?) shift; usage ;;
esac
done
}

while true
do
echo ""
read -p " > " -a func
if [ ${func[0]} == "exit" ]
then
break
fi
control ${func[@]}
done

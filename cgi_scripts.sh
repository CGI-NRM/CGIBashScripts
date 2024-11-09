#!/usr/bin/env bash

# Load user settings:
if test -f "$HOME/.cgi_user_settings.sh"
then
  . "$HOME/.cgi_user_settings.sh"
else
  . "$HOME/CGIBashScripts/.cgi_user_settings.sh"
fi

# Logic:
if [ $hpc_cluster == "uppmax" ]
then
  jobtype="core"
elif [ $hpc_cluster == "dardel" ]
then
  jobtype="main"
fi

# Aliases:
alias vim="vim-nox11" # stops .vimrc bug
alias unnotate="bash ~/CGIBashScripts/subscripts/unnotate.sh" # access universal notes
alias lonotate="bash ~/CGIBashScripts/subscripts/unnotate.sh notes.txt" # create/access notes file at present location

# Functions:

## General:
cgi_help ()
{
  echo "# Information about CGIBashScripts functions #"
  echo ""
  echo "### General ###"
  echo "nrmupload : upload file to preset nrmcloud folder"
  echo "roller : loop a function"
  echo "pmocver : reverse-complement a string"
  echo "zdiff : run diff on two zipped files"
  echo "zhead : display the first 20 lines of a zipped file"
  echo ""
  echo "### HPC Specific ###"
  echo "slurm_cheat : display helpful slurm-function"
  echo "rjb : display running jobs"
  echo "outslurm : cat the most recent slurm out in current dir"
  echo "interact : start an interactive job"
}

nrmupload () # upload one file
{
  bash ~/cloudsend.sh/cloudsend.sh "$1" "$upload_link"
}

roller () # loop a function and redraw the output
{
  for i in {0..1200}
  do
    lines=$($1 | wc -l)
    $1 | head -n${lines} # print `$lines` lines
    sleep 2
    echo -e "\e[$((${lines}+1))A" # go `$lines + 1` up
  done
}

pmocver () # reverse complement a sequence
{
  if [ $1 == "-" ]
  then
    stdin=$(cat -)
    python3 ~/CGIBashScripts/subscripts/pmocver.py $stdin
  else
    python3 ~/CGIBashScripts/subscripts/pmocver.py $1
  fi
}

zdiff () # check diff between two zipped files
{
  diff <(zcat $1) <(zcat $2)
}

zhead () # print first 20 lines of a zipped file
{
  zcat $1 | head -n 20
}

## HPC:

### Dardel:

dardel_rjb ()
{
  squeue --long --user $hpc_user
}

### Uppmax:

uppmax_rjb ()
{
  echo -e "\e[4mRunning:\e[0m\e[32m";
  jobinfo -u $hpc_user | grep " R " | awk '{print $1 "\t\t" $6 "\t" $8 "\t" $11 "\t" $3} END {if(NR==0) print "No jobs currently running"}';
  echo -e "\e[0m";
  echo -e "\e[4mPending:\e[0m\e[33m";
  jobinfo -u $hpc_user | grep " PD " | awk '{print $1 "\t" $2 "\t" $7 "\t" $9 "\t\t" $10 "\t" $4} END {if(NR==0) print "No jobs currently pending"}';
  echo -e "\e[0m"
}

### Common:

slurm_cheat ()
{
  echo "sbatch <filename>"
  echo "scancel <jobid>"
  echo "squeue -u <username>"
  echo "scontrol show job <jobid>"
  echo "sstat --jobs=your_job-id --format=JobID,aveCPU,MaxRRS,NTasks"
  echo "sacct --user=<username>" --starttime=YYYY-MM-DD
  echo "sinfo"
  echo "sprio --user=<username>"
}

rjb () # print information about pending and running jobs
{
  if [ $hpc_cluster == "uppmax" ]
  then
    uppmax_rjb
  elif [ $hpc_cluster == "dardel" ]
  then
    dardel_rjb
  fi
}

outslurm () # print latest or specified slurm output file in a directory
{
  var1=$1
  if [ ${#var1} == 0 ]; then var1=1; fi
  ls | grep "slurm" | tail -$var1 | head -1 | xargs cat | sed '$q'
}

interact () # start an interactive job
{
  interactive -A $hpc_project -t 0:15:00
}

mkblast () # create a job script for blastng a fasta file
{
  if test -f "$1"
  then
    fasta_file=$1
    out_file=${1/".fa"/""}".out"
    cur_dir=`pwd`
    job_name=${1/".fa"/""}"_blast"
    slurm_script=${1/".fa"/""}"_blast_script.sh"
    slurm_script=${slurm_script/"y_"/""}
    echo "#! /bin/bash -l" > $slurm_script
    echo "#SBATCH -A $hpc_project" >> $slurm_script
    echo "#SBATCH -p $jobtype" >> $slurm_script
    echo "#SBATCH -n 20" >> $slurm_script
    echo "#SBATCH -t 6:00:00" >> $slurm_script
    echo "#SBATCH -J $job_name" >> $slurm_script
    echo "" >> $slurm_script
    echo "# go to this directory:" >> $slurm_script
    echo "cd $cur_dir" >> $slurm_script
    echo "" >> $slurm_script
    echo "# load software modules:" >> $slurm_script
    echo "module load bioinfo-tools blast" >> $slurm_script
    echo "" >> $slurm_script
    echo "# blast sequences:" >> $slurm_script
    echo "blastn -query ./$fasta_file -db nt -out ./$out_file -outfmt \"6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids sscinames scomnames\" -max_target_seqs 5 -num_threads 20" >> $slurm_script
  else
    echo "file $1 does not exist."
  fi
}

mkdownload () # create a job script for running dada2
{
  # download aws download script:
  cp ~/CGIBashScripts/subscripts/awsdownload_script.sh .
  touch input.txt # create empty input file
  cur_dir=`pwd`
  slurm_script="download_job.sh"
  echo "#! /bin/bash -l" > $slurm_script
  echo "#SBATCH -A $hpc_project" >> $slurm_script
  echo "#SBATCH -p $jobtype" >> $slurm_script
  echo "#SBATCH -n 10" >> $slurm_script
  echo "#SBATCH -t 10:00:00" >> $slurm_script
  echo "#SBATCH -J aws_download" >> $slurm_script
  echo "" >> $slurm_script
  echo "# go to this directory:" >> $slurm_script
  echo "cd $cur_dir" >> $slurm_script
  echo "" >> $slurm_script
  echo "# load software modules:" >> $slurm_script
  echo "module load bioinfo-tools" >> $slurm_script
  echo "module load awscli" >> $slurm_script
  echo "" >> $slurm_script
  echo "# start aws download (make sure to edit input.txt first):" >> $slurm_script
  echo "bash ./awsdownload_script.sh" >> $slurm_script
}

mkupload () # create a job script for uploading data
{
  if [ -d "$1" ]
  then
    target_folder=$1
    cur_dir=`pwd`
    slurm_script="upload_job.sh"
    echo "#! /bin/bash -l" > $slurm_script
    echo "#SBATCH -A $hpc_project" >> $slurm_script
    echo "#SBATCH -p $jobtype" >> $slurm_script
    echo "#SBATCH -n 10" >> $slurm_script
    echo "#SBATCH -t 10:00:00" >> $slurm_script
    echo "#SBATCH -J nrm_upload" >> $slurm_script
    echo "" >> $slurm_script
    echo "# go to this directory:" >> $slurm_script
    echo "cd $cur_dir" >> $slurm_script
    echo "" >> $slurm_script
    echo "# upload everything three levels down in the folder:" >> $slurm_script
    echo "for file in $target_folder/*/*/*/*" >> $slurm_script
    echo "do" >> $slurm_script
    echo "bash ~/cloudsend.sh/cloudsend.sh \"\$file\" \"$upload_link\"" >> $slurm_script
    echo "done" >> $slurm_script
  else
    echo "directory $1 does not exist."
  fi
}

mkdada2 () # create a job script for running dada2
{
  cp ~/CGIBashScripts/subscripts/dada2_script.r . # copy the dada2 script to this location
  mkdir -p Filtered_data # create directory to put trimmed fastq data in, if it does not exist
  cur_dir=`pwd`
  slurm_script="dada2_job.sh"
  echo "#! /bin/bash -l" > $slurm_script
  echo "#SBATCH -A $hpc_project" >> $slurm_script
  echo "#SBATCH -p $jobtype" >> $slurm_script
  echo "#SBATCH -n 1" >> $slurm_script
  echo "#SBATCH -C mem256GB " >> $slurm_script # this makes it a fat node
  echo "#SBATCH -t 2-00:00:00" >> $slurm_script
  echo "#SBATCH -J dada2_fat" >> $slurm_script
  echo "" >> $slurm_script
  echo "# go to this directory:" >> $slurm_script
  echo "cd $cur_dir" >> $slurm_script
  echo "" >> $slurm_script
  echo "# load software modules:" >> $slurm_script
  echo "module load bioinfo-tools" >> $slurm_script
  echo "module load R_packages" >> $slurm_script
  echo "" >> $slurm_script
  echo "# run dada2 script:" >> $slurm_script
  echo "Rscript ./dada2_script.r" >> $slurm_script
}

mktar () # create a job script for tar-ing a folder
{
  if test -d "$1"
  then
    folder_input=$1
    folder_output=${1/\//.tar}
    cur_dir=`pwd`
    slurm_script="tar_script.sh"
    echo "#! /bin/bash -l" > $slurm_script
    echo "#SBATCH -A $hpc_project" >> $slurm_script
    echo "#SBATCH -p $jobtype" >> $slurm_script
    echo "#SBATCH -n 20" >> $slurm_script
    echo "#SBATCH -t 6:00:00" >> $slurm_script
    echo "#SBATCH -J tar_folder" >> $slurm_script
    echo "" >> $slurm_script
    echo "# go to this directory:" >> $slurm_script
    echo "cd $cur_dir" >> $slurm_script
    echo "" >> $slurm_script
    echo "# load software modules:" >> $slurm_script
    echo "#module load bioinfo-tools" >> $slurm_script
    echo "" >> $slurm_script
    echo "# tar folder:" >> $slurm_script
    echo "tar -cvf $folder_output ./$folder_input" >> $slurm_script
  else
    echo "folder $1 does not exist."
  fi
}

lcratch () # list scratch discs of all running projects
{
  readarray -t scr_list < <(jobinfo -u $hpc_user | grep " R " | awk '{print $11 " ls -lah /scratch/" $1}')
  declare -p scr_list > /dev/null
  if [ 1 -gt ${#scr_list} ] ; then echo "You have no running jobs." ; fi
  for i in "${scr_list[@]}"
  do
    echo "${i##* }:"
    ssh $i
    echo ""
  done
}

awsout () # check status of aws downloading job
{
  outslurm | grep remaining | tail -1
}

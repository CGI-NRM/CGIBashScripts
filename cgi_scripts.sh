#!/usr/bin/env bash

# Load user settings:
. "./user_settings.sh"

# Functions:

## General:
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

## HPC:
rjb () # print information about pending and running jobs
{
  echo -e "\e[4mRunning:\e[0m\e[32m";
  jobinfo -u $hpc_user | grep " R " | awk '{print $1 "\t\t" $6 "\t" $8 "\t" $11 "\t" $3} END {if(NR==0) print "No jobs currently running"}';
  echo -e "\e[0m";
  echo -e "\e[4mPending:\e[0m\e[33m";
  jobinfo -u $hpc_user | grep " PD " | awk '{print $1 "\t" $2 "\t" $7 "\t" $9 "\t\t" $10 "\t" $4} END {if(NR==0) print "No jobs currently pending"}';
  echo -e "\e[0m"
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
    out_file=${1/.fa/.out}
    cur_dir=`pwd`
    job_name=${1/.fa/_blast}
    slurm_script=${1/.fa/_blast_script.sh}
    slurm_script=${slurm_script/y_/}
    echo "#! /bin/bash -l" > $slurm_script
    echo "#SBATCH -A $hpc_project" >> $slurm_script
    echo "#SBATCH -p core" >> $slurm_script
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

mkupload () # create a job script for uploading data
{
  if [ -d "$1" ]
  then
    target_folder=$1
    cur_dir=`pwd`
    slurm_script="upload_job.sh"
    echo "#! /bin/bash -l" > $slurm_script
    echo "#SBATCH -A $hpc_project" >> $slurm_script
    echo "#SBATCH -p core" >> $slurm_script
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
    echo "#SBATCH -p core" >> $slurm_script
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

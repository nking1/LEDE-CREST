#!/bin/bash 
#SBATCH --account=ACCT
#SBATCH --ntasks=MTDTasks
#SBATCH -N 1 
#SBATCH --mem-per-cpu=MTDMem 
#SBATCH --time=MTDTime
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=EMAIL
#SBATCH --array=1-MTDCount
#SBATCH --output=basename.out

module load StdEnv/2020 xtb/6.5.0 
export OMP_STACKSIZE=Stacksize
DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" mtd.dir) 
cd $DIR 
echo "Starting task $SLURM_ARRAY_TASK_ID in dir $DIR" 
xtb basename.xyz --md --input basename.inp -P 4 -g Solvent --chrg CHARGE > basename.out

#!/bin/bash 
#SBATCH --account=ACCT 
#SBATCH --ntasks=ScreenTasks 
#SBATCH -N 1 
#SBATCH --mem-per-cpu=ScreenMem 
#SBATCH --time=ScreenTime 
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=EMAIL 
#SBATCH --array=1-ScreenCount
#SBATCH --output=basenameScreen.out

module load StdEnv/2020 crest/2.12 
DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" screen.dir) 
cd $DIR 
echo Starting task $SLURM_ARRAY_TASK_ID in dir $DIR 
export OMP_STACKSIZE=Stacksize
for n in {1..4}
 do cat ../${DIR::1}$n/xtb.trj >> xtb.trj
 done
crest -screen xtb.trj -T 28 -g Solvent --chrg CHARGE > basename.out

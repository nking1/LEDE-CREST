#!/bin/bash
#SBATCH --account=ACCT
#SBATCH --mail-type=all
#SBATCH --mail-user=EMAIL
#SBATCH --ntasks=16
#SBATCH -N 1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=1:0:0
#SBATCH --output=CREGEN.sh

mkdir CREGEN
for ens in Cycle?/?Screen/crest_ensemble.xyz
	do cat $ens >> CREGEN/ensembles.xyz
	done
cp Cycle1/A1/basename.xyz CREGEN
module load StdEnv/2020 crest/2.12
export OMPSTACKSIZE=Stacksize
cd CREGEN
crest basename.xyz --cregen ensembles.xyz --notopo -g Solvent -T 16
cp crest_ensemble.xyz ../final_ensemble.xyz
cp crest_best.xyz ../LEDE-CREST_best.xyz

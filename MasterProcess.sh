#!/bin/bash 
#SBATCH --account=ACCT 
#SBATCH --ntasks=1 
#SBATCH --mem-per-cpu=256M 
#SBATCH --time=0-2
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=EMAIL
#SBATCH --output=basenameprocessed.out

# Load modules and set up variables

module load StdEnv/2020 crest/2.12 

# Clear previous process.sh results, if any

rm fullreport.txt all*
for d in ?Screen/ 
 do rm -r "$d"SPLIT 
 rm "$d"rmsds.txt "$d"paths.txt "$d"energies.txt "$d"relativeenergies.txt "$d"report.txt 

# Split ensemble, and modify directory names for proper sorting

 cd "$d" 
 crest -splitfile crest_ensemble.xyz 
 cd .. 
 for s in "$d"SPLIT/STRUC??/ 
  do mv "$s" "$d"SPLIT/XSTRUC"${s: -3}" 
  done 
 for s in "$d"SPLIT/STRUC???/ 
  do mv "$s" "$d"SPLIT/YSTRUC"${s: -4}" 
  done 
 for s in "$d"SPLIT/STRUC????/ 
  do mv "$s" "$d"SPLIT/ZSTRUC"${s: -5}" 
  done 

# Get RMSDs and paths

 for s in "$d"SPLIT/*/struc.xyz
  do crest -rmsd "$d"basename.xyz $s | tail -1 | awk '{print $NF}' >> "$d"rmsds.txt
  echo $s >> "$d"paths.txt
  done

# Set up variables for energies

 dos2unix A1/basename.xyz
 AtomCount=$(sed -n '1p' A1/basename.xyz)
 LinesPerMol=$(echo 2+$AtomCount | bc -l)

# Get energies
# i.e. get each:  2nd line for every structure in the ensemble.xyz file

 awk "NR % $LinesPerMol == 2" "$d"crest_ensemble.xyz | awk '{print $NF}' >> "$d"energies.txt

# Combine into one text file
 
 paste "$d"paths.txt "$d"rmsds.txt "$d"energies.txt > "$d"conflist.txt

done

# Set up ScreenArray variable

for r in ?Screen/conflist.txt
 do ScreenArray+=("$r")
 done

# Merge conformer lists from all screenings

sort -m -o ConfListSorted.txt -k 3n ${ScreenArray[*]}

awk '{print $1}' ConfListSorted.txt > PathsSorted.txt
awk '{print $2}' ConfListSorted.txt > RMSDSSorted.txt
awk '{print $3}' ConfListSorted.txt > EnergiesSorted.txt

# read each file into its own array, all files have the same length and index

readarray -t energyarr < EnergiesSorted.txt
readarray -t rmsdarr < RMSDSSorted.txt
readarray -t filearr < PathsSorted.txt

# Record best energy

echo ${energyarr[0]} > BestEnergy.txt

# get the length of energyarr, will be same for all arrays

LENGTH=${#energyarr[@]}

# Compute relative energies, in Eh

for (( i=0; i<=$((LENGTH-1)); i++ ))
 do tmp=$(echo "${energyarr[$i]} - ${energyarr[0]}" | bc -l)
 echo $tmp >> relativeenergies.txt
 done
 
# Convert to kcal/mol

readarray -t relativeenergyarr < relativeenergies.txt

for (( i=0; i<=$((LENGTH-1)); i++ ))
 do tmp=$(echo "scale=6; ${relativeenergyarr[$i]}*627.5" | bc -l)
 echo $tmp >> ScaledEnergies.txt
 done
 
# Compute ratios
 
readarray -t relativekcalenergyarr < ScaledEnergies.txt

for (( i=0; i<=$((LENGTH-1)); i++ ))
 do tmp=$(echo "scale=4; ${relativekcalenergyarr[$i]}/${rmsdarr[$i]}" | bc -l)
 echo $tmp >> ratios.txt
 done

readarray -t ratioarr < ratios.txt

# Generate full report

paste PathsSorted.txt RMSDSSorted.txt EnergiesSorted.txt ScaledEnergies.txt ratios.txt > fullreport.txt

# Set up candidate arrays

declare -a candidatefilearr=()
declare -a candidateenergyarr=()


ATOMS=$(sed -n '1p' AScreen/crest_ensemble.xyz)
ATOMS=$( echo "$ATOMS" | xargs )
ATOMS=$((ATOMS+2))

LENGTH=${#energyarr[@]}

# compare rmsd ONLY IF ratio less than 0.5
RATIOTHRESHOLD=PassQuotient

# add conformer if different by more than 1.0 A
RMSDTHRESHOLD=MinRMSD


# ALWAYS include the lowest energy conformer
candidatefilearr+=(${filearr[0]})
candidateenergyarr+=(${energyarr[0]})
echo ${filearr[0]} > backupcandidateslist.txt


for (( i=1; i<=$((LENGTH-1)); i++ )); do
	
	#make sure below 0.5 ratio
	if (( $(echo "${ratioarr[$i]} < $RATIOTHRESHOLD" | bc -l ) )); then
	
		#inner loop to test each pair
		CANDIDATELENGTH=${#candidatefilearr[@]}
		if (( $CANDIDATELENGTH < MaxConfCount )); then
			for (( j=0; j<=$((CANDIDATELENGTH-1)); j++ )); do
					
				flag=true
		
				tmp=$(crest -rmsd ${filearr[$i]} ${candidatefilearr[$j]} | tail -1 | awk '{print $NF}')
				
			
				if (( $(echo "$tmp < $RMSDTHRESHOLD" | bc -l ) )); then
					flag=false
					break
				fi	
			done
			
			if $flag; then
				for struc in ../Cycle?/?1/basename.xyz; do
					flag=true
					tmp=$(crest -rmsd ${filearr[$i]} $struc | tail -1 | awk '{print $NF}')
					
					if (( $(echo "$tmp < $RMSDTHRESHOLD" | bc -l ) )); then
						flag=false
						break
					fi
				done
				
				if $flag; then
					candidatefilearr+=(${filearr[$i]})
          candidateenergyarr+=(${energyarr[$i]})
				fi
			fi		
		fi
	fi

done

printf "%s\n" "${candidatefilearr[@]}" > allcandidatefilesSORTED.txt
printf "%s\n" "${candidateenergyarr[@]}" > allcandidateenergiessSORTED.txt

echo "done"



#!/bin/bash
#SBATCH --account=ACCT
#SBATCH --mail-type=all
#SBATCH --mail-user=EMAIL
#SBATCH --ntasks=1
#SBATCH --time=1:0
#SBATCH --output=NextCycle.out

#Set up Cycle variables

CycleCount=$( cat cyclecount.txt)
NextCycle=$( echo "$CycleCount+1" | bc -l )
ConfCount=$( wc -l < allcandidatefilesSORTED.txt )

#Determine whether to terminate

Best=$( cat BestEnergy.txt)
PrevPrevCycleCount=$( echo "$CycleCount-2" | bc -l )
PrevBest=$( cat ../Cycle$PrevPrevCycleCount/BestEnergy.txt )
Difference=$( echo "$PrevBest - $Best" | bc -l )


if [ $CycleCount -gt 2 ]; then
	if (( $(echo "$Difference < 0.000016" | bc -l) )); then
		cd ..
		sbatch CREGEN.sh
		exit
	fi
elif [ $CycleCount == MaxCycles ]; then
	echo "Not converged in MaxCycles cycles"
	exit
fi

#Create new cycle

if [ $CycleCount -lt 3 ] || (( $(echo "$Difference > 0.000016" | bc -l) )); then
	if [ $CycleCount != MaxCycles ]; then
		mkdir ../Cycle$NextCycle
		cd ../Cycle$NextCycle
		echo $NextCycle > cyclecount.txt

#Copy in Scripts

		sed "s/MTDCount/$( echo "$ConfCount*4" | bc -l)/g" ../TemplateMTD.sh > MTD.sh
		sed "s/ScreenCount/$ConfCount/g" ../TemplateScreen.sh > Screen.sh
		cp ../TemplateProcess.sh Process.sh
		cp ../TemplateNextCycle.sh NextCycle.sh

		rm *.dir

#Set up MTD and Screen directories and directory lists and copy in conformers

		if [ $ConfCount == 1 ]; then
			for n in {1..4}
				do mkdir A$n
				echo A$n >> mtd.dir
				done
			mkdir AScreen
			echo AScreen > screen.dir
  
			for d in A*
		  		do cp ../Cycle$CycleCount/$( cat ../Cycle$CycleCount/allcandidatefilesSORTED.txt ) $d/basename.xyz
				done
		
		else
			for val in $( eval echo "{1..$ConfCount}" )
				do
				Code=$( echo "$val+64" | bc -l )
				ConfLett=$( printf "\x$(printf %x $Code)" )
				for n in {1..4}
					do mkdir $ConfLett$n
					echo $ConfLett$n >> mtd.dir
					done
				mkdir "$ConfLett"Screen
				echo "$ConfLett"Screen >> screen.dir
				for d in "$ConfLett"*
					do cp ../Cycle$CycleCount/$( sed -n "$val"p ../Cycle$CycleCount/allcandidatefilesSORTED.txt ) $d/basename.xyz
					done
				done
  
		fi

		for d in ?1/
			do cp ../Cycle1/A1/basename.inp $d
			done

		for d in ?2/
			do cp ../Cycle1/A2/basename.inp $d
			done

		for d in ?3/
			do cp ../Cycle1/A3/basename.inp $d
			done

		for d in ?4/
			do cp ../Cycle1/A4/basename.inp $d
			done

		sbatch --job-name=basename MTD.sh
		sbatch --job-name=basename -d singleton Screen.sh
		sbatch --job-name=basename -d singleton Process.sh
		sbatch --job-name=basename -d singleton NextCycle.sh
	fi
fi

#!/bin/bash
#SBATCH --account=def-browna
#SBATCH --mail-type=all
#SBATCH --mail-user=nking1@ualberta.ca
#SBATCH --ntasks=1
#SBATCH --time=1:0
#SBATCH --output=initialization.out

basename=
account=
email=
Solvent=
KPush1=0.05
KPush2=0.015
Alp1=1.3
Alp2=3.1
SimLength=30
MTDTasks=4
MTDMem=512M
MTDTime=0-3
Stacksize=2G
ScreenTasks=28
ScreenMem=256M
ScreenTime=0-12
MaxConfCount=12
PassQuotient=0.5
MinRMSD=1.0
MaxCycles=10

#Set up scripts

sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Solvent/$Solvent/g; s/MaxCycles/$MaxCycles/g" MasterNextCycle.sh > TemplateNextCycle.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/MTDTasks/$MTDTasks/g; s/MTDMem/$MTDMem/g; s/MTDTime/$MTDTime/g; s/Stacksize/$Stacksize/g; s/Solvent/$Solvent/g" MasterMTD.sh > TemplateMTD.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Solvent/$Solvent/g; s/Stacksize/$Stacksize/g; s/ScreenTasks/$ScreenTasks/g; s/ScreenMem/$ScreenMem/g; s/ScreenTime/$ScreenTime/g" MasterScreen.sh > TemplateScreen.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/MaxConfCount/$MaxConfCount/g; s/PassQuotient/$PassQuotient/g; s/MinRMSD/$MinRMSD/g" MasterProcess.sh > TemplateProcess.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Stacksize/$Stacksize/g; s/Solvent/$Solvent/g" MasterCREGEN.sh > CREGEN.sh

#Make initial Cycle directory

mkdir Cycle1
cd Cycle1

# Establish cycle count

echo 1 > cyclecount.txt

#Copy in Scripts

sed "s/MTDCount/4/g" ../TemplateMTD.sh > MTD.sh
sed "s/ScreenCount/1/g" ../TemplateScreen.sh > Screen.sh
cp ../TemplateProcess.sh Process.sh
cp ../TemplateNextCycle.sh NextCycle.sh

#Set up MTD and Screen directories and directory lists

for n in {1..4}
 do mkdir A$n
 echo A$n >> mtd.dir
 done
mkdir AScreen
echo AScreen > screen.dir

#Set up MTD input files

for d in ?1/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush1" >> $d/$basename.inp
    echo "alp=$Alp1" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?2/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush2" >> $d/$basename.inp
    echo "alp=$Alp1" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?3/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush1" >> $d/$basename.inp
    echo "alp=$Alp2" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?4/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush2" >> $d/$basename.inp
    echo "alp=$Alp2" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

#Copy in starting structure

for d in A*/
 do cp ../$basename.xyz "$d"
 done

#Submit scripts

sbatch --job-name=$basename MTD.sh
sbatch --job-name=$basename -d singleton Screen.sh
sbatch --job-name=$basename -d singleton Process.sh
sbatch --job-name=$basename -d singleton NextCycle.sh

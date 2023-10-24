Welcome to LEDE-CREST!

LEDE-CREST (Low-Energy, Diversity-Enhanced variant on the Conformer-Rotamer Ensemble
Sampling Tool) is a series of scripts designed to run on Unix clusters with SLURM schedulers,
and with CREST v. 2.12 and xtb v. 6.5.0 installed. Tweaking of the line including the command
"module load" in the MasterMTD.sh, MasterScreen.sh, MasterProcess.sh, and CREGEN.sh scripts
may be necessary if the prerequisites to those modules is different on your cluster than on
clusters run by the Digital Research Alliance of Canada. LEDE-CREST is an adaptation of the
CREST algorithm for geometry exploration and conformer ensemble generation in the case of
non-covalent clusters of flexible molecules.

LEDE-CREST uses the same RMSD-biased metadynamics as CREST does, but with less energetic
settings. LEDE-CREST requires a single structure in xyz format as input. As with any 
metadynamics in xtb, it is recommended that this structure be preoptimized using xtb. The
first cycle will run on just the provided conformer. Subsequent cycles will run on a selection
of up to 12 conformers generated in the previous cycle. These conformers are selected for
small values of the ratio of their relative energy (kcal/mol above the best conformer found
yet) vs their structural RMSD from the conformer which was used as the seed in the run from
which they originate. This selection is subject to the additional constraint that any selected
conformer must have an RMSD of at least 1 Angstrom from any previously selected conformer,
with the exception that the lowest energy conformer found in a cycle is carried forward,
regardless of proximity to previously selected conformers. When at least three cycles have
been completed, and the lowest-energy conformer found has not been improved on for at least
two cycles, LEDE-CREST will collect all conformers found into a single sorted ensemble and
will then terminate.

Usage:

To use LEDE-CREST, one must place the six scripts (LEDE-CREST.sh, MasterMTD.sh,
MasterScreen.sh, MasterProcess.sh, MasterNextCycle.sh, and MasterCREGEN.sh) in a single
directory along with a starting structure in xyz format. Next, one must edit the variable
definitions in the LEDE-CREST script, and then submit LEDE-CREST.sh to the slurm queue. The
variables available for editing are:

basename - This should match the name of your structure file, without extension. That is, if
you are starting from Structure1.xyz, basename should be set to Structure1.

account - Your slurm account name on the cluster.

email - Your email address for notifications (optional).

Solvent - Select a solvent name for gbsa solvation. If none is desired, enter "none".

CHARGE - electronic charge of system. Default is 0, but may be adjusted if desired.

KPush1 - Default is 0.05, but may be adjusted if desired.

KPush2 - Default is 0.015, but may be adjusted if desired.

Alp1 - Default is 1.3, but may be adjusted if desired.

Alp2 - Default is 3.1, but may be adjusted if desired.

SimLength - Simulation length in picoseconds. Default is 30. May be adjusted if desired.

MTDTasks - Set the number of threads for MTD simulations. Default is 4. May be adjusted if
desired.

MTDMem - Memory per core for MTD simulations. Default is 512 MiB. May be adjusted if desired.

MTDTime - Time limit for MTD simulations, in dd-hh, or dd-hh:mm, or hh:mm:ss, or mm:ss.

Stacksize - Memory limit internal to xtb. If simulations or screening of large systems
crash, try increasing this value.

ScreenTasks - Set the number of threads for CREST screening. Default is 28. May be adjusted if
desired.

ScreenMem - Memory per core for CREST screening. Default is 256 MiB. May be adjusted if
desired.

ScreenTime - Time limit for CREST screening, with same formatting as MTDTime.

MaxConfCount - Maximum number of conformers to carry forward each cycle. Default is 12. May be
adjusted if desired. Do not set higher than 26.

PassQuotient - Maximum value of RelEnergy/RMSD for a conformer to be carried forward to the
next cycle. Default is 0.5 (kcal/(mol*Ang)). May be adjusted if desired.

MinRMSD - Minimum RMSD between selected conformers, in Angstrom. Default 1.0. May be adjusted
if desired.

MaxCycles - Maximum number of cycles before terminating. Default 10. May be adjusted if
desired.


If one wants to run a default run, the only values which must be provided are those for
basename, account, Solvent, and, optionally, email. At this time, there is no variable to
adjust the number of metadynamics simulations per cycle, but this could be achieved by editing
the body of the LEDE-CREST and nextcycle scripts.

When LEDE-CREST terminates, the final ensemble and best structure are copied to the main
directory.


Function of scripts:

The LEDE-CREST.sh script initializes the procedure, creates the Cycle1 directory and its
subdirectories, adjusts the other five scripts based on the variables provided, and submits
them to the queue with singleton dependency, such that they will execute in series. (The Master
versions of the scripts are not changed by LEDE-CREST. Instead, new Template versions are
created by LEDE-CREST in the main directory, and are then copied into each Cycle directory as
needed, with further editing based on the number of conformers being carried forward to each
cycle.)

The MTD.sh script executes the metadynamics simulations using xtb v. 6.5.0. The various
metadynamics simulations within each cycle are submitted in parallel as a slurm array job.

The Screen.sh script starts by compiling the trajectories from the MTD jobs. Each starting
conformer is used in four metadynamics runs with different biasing settings, and Screen.sh
compiles these four trajectories together. Each set of four compiled trajectories is then
screened using the --screen option of CREST. The different screen jobs, one for each starting
conformer, are submitted in parallel as a slurm array job.

The Process.sh script takes the ensembles generated by Screen.sh, and splits each into its
individual conformers. For each conformer, it computes RMSD relative to the starting conformer
for that metadynamics run. All the conformers for a cycle are then collected together and
sorted by energy. Process.sh then computes relative energy for each conformer, in kcal/mol,
and the quotient of relative energy divided by RMSD. The filepath, RMSD, absolute energy (in
Hartree), relative energy, and quotient for each conformer are compiled in fullreport.txt.
Process.sh then identifies up to 12 (or other maximum, if the variable MaxConfCount has been
changed) conformers which have a quotient below 0.5 (or other maximum, if the variable
PassQuotient has been changed), and are at least 1 Angstrom away (or other minimum, if the
variable MinRMSD has been changed) from each other and any conformers selected in previous
cycles. The lowest-energy conformer in a cycle is always selected, even if it is close to a
previously-selected one. The filepath to each of these conformers is then written to
allcandidatefilesSORTED.txt.

The NextCycle.sh script first checks how many cycles have completed. If more than two have,
then it checks whether the energy has improved over the last two cycles. If it has not, then
NextCycle.sh calls the CREGEN.sh script. If the energy has improved over the previous
two cycles, and the maximum number of cycles (default 10) has not been reached, then
NextCycle.sh creates the next Cycle directory, reads the number of conformers from the
allcandidatefilesSORTED.txt file, adjusts the copies of MTD.sh and Screen.sh that it copies
into the next directory accordingly, follows the filepaths in allcandidatefilesSORTED.txt to
copy the appropriate structures into the new subdirectories, and submits new copies of
MTD.sh, Screen.sh, Process.sh, and NextCycle.sh in the next Cycle directory. If the maximum
number of cycles has been reached, NextCycle.sh prints "Not converged in 10 cycles," and 
terminates LEDE-CREST.

The CREGEN.sh script creates the CREGEN directory, collects all the ensembles generated over the
course of the run of LEDE-CREST there, and uses the --cregen function of CREST to sort them
into a single ensemble. CREGEN.sh then copies the final ensemble and best structure to
the main directory, and terminates LEDE-CREST.

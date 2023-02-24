#
# MIT License
#
# Copyright (c) 2011-2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"

source $DIR_SCRIPT/const.sh

#===============================================================================

#
# Replaces strings recursively.
#
function replace
{
	dir=$1
	oldstr=$2
	newstr=$3

	cecho $GREEN "[+] Replacing \"$oldstr\" -> \"$newstr\""

	find $dir \( -type d -name .git -prune \) -o -type f -print0 \
		| xargs -0 $SED -i "s/$oldstr/$newstr/g"
}

#
# Turns on/off add-ons.
#
function switchAddons
{
	srcdir=$1
	on=$2
	off=$3
	curdir=$PWD

	cecho $GREEN "[+] Switching Addons"

	cd $srcdir

		replace . $off $on

	cd $curdir
}

#
# Change repository.
#
function changeRepository
{
	mode=$1

	cecho $GREEN "[+] Changing Repository"

	case $mode in
		baseline)
			cecho $GREEN "   [+] Configuring baseline mode"
			COMMIT=$BASELINE_COMMIT
			HASH=$BASELINE_HASH
			OUTDIR=$DIR_RESULTS_RAW/$HASH-baseline
			;;

		comm)
			cecho $GREEN "   [+] Configuring comm mode"
			COMMIT=$BASELINE_COMMIT
			HASH=$BASELINE_HASH
			OUTDIR=$DIR_RESULTS_RAW/$HASH-comm
			;;

		daemons)
			cecho $GREEN "   [+] Configuring daemons mode"
			COMMIT=$TASK_COMMIT
			HASH=$TASK_HASH
			OUTDIR=$DIR_RESULTS_RAW/$HASH-task
			;;

		*)
			cecho $RED "unknown mode"
			exit 1
	esac
}

#
# Checkout source code.
#
function checkout
{
	srcdir=$1
	commit=$2
	curdir=$PWD

	cecho $GREEN "[+] Checkout Repository"

	cd $srcdir

		git checkout $commit
		git submodule update --recursive

	cd $curdir
}

#
# Populate base dir on remote.
#
function configureRemote
{
	cecho $GREEN "[+] Configuring Remote"

	platform=$1
	scripts=$2
	basedir=$3

	ssh $platform "rm -rf $basedir/* ; \
		mkdir $basedir/benchmarks"

	$UPLOAD $scripts/arch/$platform/* $platform:$basedir
}

#
# Upload source code.
#
function upload
{
	platform=$1
	destdir=$2
	srcdir=$3

	cecho $GREEN "[+] Uploading"

	ssh $platform "rm -rf $destdir/*"
	$UPLOAD $srcdir/* $platform:$destdir
}

#
# Download results.
#
function download
{
	platform=$1
	remotedir=$2
	localdir=$3
	localfile=$4

	cecho $GREEN "[+] Downloading"

	scp "$platform:$remotedir/$localfile" $localdir/$localfile
	scp "$platform:$remotedir/profile-*" $localdir
}

#
# Download results.
#
function clean_logs
{
	platform=$1
	remotedir=$2
	localfile=$4

	cecho $GREEN "[+] Cleaning logs"

	ssh $platform "rm -f $remotedir/*-nanvix-cluster-*"
}

#
# Run experiment.
#
function compile_and_run
{
	platform=$1
	remotedir=$2
	srcdir=$3
	commit=$4
	img=$5
	exp=$6
	it=$7
	localdir=$8
	runlog=$9
	runlogfile=$exp-$runlog-$it
	lwmpi=${10}
	map=${11}

	cecho $BLUE "[+] Running $runlogfile ($lwmpi, $map)"

	#echo "$ADDONS_ON"

	# checkout $srcdir $commit
	#switchAddons $srcdir $ADDONS_ON $ADDONS_OFF

	upload $platform $remotedir $srcdir
	ssh $platform "cd $remotedir    &&
		$COMPILE_AND_RUN $remotedir img/$img $lwmpi $map &&
		cat $runlog* > $runlogfile &&
		cat board_0_DDR0_POWER  > profile-ddr0-power-$runlogfile &&
		cat board_0_DDR1_POWER  > profile-ddr1-power-$runlogfile &&
		cat board_0_MPPA0_POWER > profile-mppa-power-$runlogfile &&
		cat board_0_MPPA0_TEMP  > profile-mppa-temp-$runlogfile &&
		cat board_0_PLX_TEMP    > profile-plx-tmp-$runlogfile"
	download $platform $remotedir $localdir "$runlogfile"
}

#
# Run experiment.
#
function just_run
{
	platform=$1
	remotedir=$2
	srcdir=$3
	commit=$4
	img=$5
	exp=$6
	it=$7
	localdir=$8
	runlog=$9
	runlogfile=$exp-$runlog-$it
	lwmpi=${10}
	map=${11}

	cecho $BLUE "[+] Running $runlogfile ($lwmpi, $map)"

	#echo "$ADDONS_ON"

	# checkout $srcdir $commit
	#switchAddons $srcdir $ADDONS_ON $ADDONS_OFF

	clean_logs $platform $remotedir "$runlogfile"
	ssh $platform "cd $remotedir    &&
		$JUST_RUN $remotedir img/$img $lwmpi $map &&
		cat $runlog* > $runlogfile &&
		cat board_0_DDR0_POWER  > profile-ddr0-power-$runlogfile &&
		cat board_0_DDR1_POWER  > profile-ddr1-power-$runlogfile &&
		cat board_0_MPPA0_POWER > profile-mppa-power-$runlogfile &&
		cat board_0_MPPA0_TEMP  > profile-mppa-temp-$runlogfile &&
		cat board_0_PLX_TEMP    > profile-plx-tmp-$runlogfile"
	download $platform $remotedir $localdir "$runlogfile"
}

#
# Run experiment.
#
function run_download_result
{
	platform=$1
	remotedir=$2
	srcdir=$3
	commit=$4
	img=$5
	exp=$6
	it=$7
	localdir=$8
	runlog=$9
	runlogfile=$exp-$runlog-$it
	lwmpi=${10}
	map=${11}

	cecho $BLUE "[+] Running $runlogfile ($lwmpi, $map)"

	#echo "$ADDONS_ON"

	# checkout $srcdir $commit
	#switchAddons $srcdir $ADDONS_ON $ADDONS_OFF

	#upload $platform $remotedir $srcdir
	ssh $platform "cd $remotedir    &&
		cat $runlog* > $runlogfile &&
		cat board_0_DDR0_POWER  > profile-ddr0-power-$runlogfile &&
		cat board_0_DDR1_POWER  > profile-ddr1-power-$runlogfile &&
		cat board_0_MPPA0_POWER > profile-mppa-power-$runlogfile &&
		cat board_0_MPPA0_TEMP  > profile-mppa-temp-$runlogfile &&
		cat board_0_PLX_TEMP    > profile-plx-tmp-$runlogfile"
	download $platform $remotedir $localdir "$runlogfile"
}

function parse_outputs
{
	platform=$1
	remotedir=$2
	srcdir=$3
	commit=$4
	img=$5
	exp=$6
	it=$7
	localdir=$8
	runlog=$9
	runlogfile=$exp-$runlog-$it
	lwmpi=${10}
	map=${11}

	return 0
}

#===============================================================================

function run_compile
{
	local failed='failed|FAILED|Failed'
	local success='false'
	while [[ $success == false ]];
	do
		echo "$outdir - $exp - $it" >> executions.log

		if [[ $1 -eq 4 ]];
		then
			compile_and_run   \
				$PLATFORM     \
				$DIR_REMOTE   \
				$DIR_SOURCE   \
				$COMMIT       \
				$IMG          \
				$exp          \
				$it           \
				$outdir       \
				$FILE_RUNLOG  \
				$lwmpi        \
				$map
		else
			just_run          \
				$PLATFORM     \
				$DIR_REMOTE   \
				$DIR_SOURCE   \
				$COMMIT       \
				$IMG          \
				$exp          \
				$it           \
				$outdir       \
				$FILE_RUNLOG  \
				$lwmpi        \
				$map
		fi

		runlogfile=$outdir/$exp-$FILE_RUNLOG-$it

		while read -r line;
		do
			if [[ $line =~ $failed ]];
			then
				break
			fi

			if [[ $line = *"IODDR0@0.0: RM 0: [hal] powering off"* ]];
			then
				success='true'
			fi
		done < "$runlogfile"

		if [[ $success == true ]];
		then
			echo "Succeed !" >> executions.log
		else
			echo "Failed !" >> executions.log
		fi
	done
}

function run_processes
{
	exp=$1

	lwmpi=1
	map=1

	old_procs_nr="MPI_PROCESSES_NR 192"

	img_dest=mppa256-capbench-$exp.img

	for nprocs in 96; # 12,24,48
	do
		new_procs_nr="MPI_PROCESSES_NR $nprocs"

		replace $DIR_SOURCE "$old_procs_nr" "$new_procs_nr"

		for (( it=4; it<5; it++ ));
		do
			outdir=$OUTDIR-procs-$nprocs

			mkdir -p $outdir

			IMG=$img_dest

			run_compile $it

			old_procs_nr="$new_procs_nr"
		done
	done

	new_procs_nr="MPI_PROCESSES_NR 192"
	replace $DIR_SOURCE "$old_procs_nr" "$new_procs_nr"
}

function run_download
{
	exp=$1

	lwmpi=1
	map=2

	img_dest=mppa256-capbench-$exp.img

	it=4
	nprocs=96

	outdir=$OUTDIR-procs-$nprocs

	mkdir -p $outdir

	IMG=$img_dest
	run_download_result \
		$PLATFORM     \
		$DIR_REMOTE   \
		$DIR_SOURCE   \
		$COMMIT       \
		$IMG          \
		$exp          \
		$it           \
		$outdir       \
		$FILE_RUNLOG  \
		$lwmpi        \
		$map
}

function run_capbench
{
	# Communication options
	comm_task_enable="__NANVIX_USE_COMM_WITH_TASKS 1"
	comm_task_disable="__NANVIX_USE_COMM_WITH_TASKS 0"

	# LWMPI options
	lwmpi_default="export ADDONS ?="
	lwmpi_scatter="export ADDONS = -D__NANVIX_USES_LWMPI=1 -D__LWMPI_PROC_MAP=1"
	lwmpi_compact="export ADDONS = -D__NANVIX_USES_LWMPI=1 -D__LWMPI_PROC_MAP=2"

	# Setup lwmpi
	#replace $DIR_SOURCE "$lwmpi_default" "$lwmpi_compact"

	for exp in fast;
	do
	# Baseline
		cecho $BLUE "!BASELINE"

		changeRepository baseline

		checkout $DIR_SOURCE $COMMIT

		# Disable comm with tasks
		replace $DIR_SOURCE "$comm_task_enable" "$comm_task_disable"

		run_processes $exp

		# Enable comm with tasks
		replace $DIR_SOURCE "$comm_task_disable" "$comm_task_enable"

	# Comm with tasks
		cecho $BLUE "!COMM"

		changeRepository comm

		checkout $DIR_SOURCE $COMMIT

		#run_processes $exp

	# Daemons with tasks
		cecho $BLUE "!DAEMONS"

		changeRepository daemons

		checkout $DIR_SOURCE $COMMIT

		#run_processes $exp
	done

	#replace $DIR_SOURCE "$lwmpi_compact" "$lwmpi_default"
}

#===============================================================================

case $1 in
	*)
		configureRemote $PLATFORM $DIR_SCRIPTS $BASEDIR_REMOTE
		run_capbench
		;;
esac


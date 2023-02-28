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
# Populate base dir on remote.
#
function configureRemote
{
	cecho $GREEN "[+] Configuring Remote"

	platform=$1
	scripts=$2
	basedir=$3

	ssh $platform "rm -rf $basedir/* ; \
		mkdir $basedir/libnanvix"

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

	mkdir -p $localdir

	scp "$platform:$remotedir/$localfile" $localdir/$localfile
	# scp "$platform:$remotedir/profile-*" $localdir
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

	ssh $platform "rm -f $remotedir/*nanvix-cluster*"
}

#
# Run experiment.
#
function compile_and_run
{
	platform=$1
	remotedir=$2
	srcdir=$3
	img=$4
	it=$5
	localdir=$6
	runlog=$7

	runlogfile=$runlog-$it

	cecho $BLUE "[+] Running $runlogfile ($it)"
	
	upload $platform $remotedir $srcdir
	ssh $platform "cd $remotedir    &&
		$COMPILE_AND_RUN $remotedir img/$img &&
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
	img=$4
	it=$5
	localdir=$6
	runlog=$7

	runlogfile=$runlog-$it
	cecho $BLUE "[+] Running $runlogfile ($it)"

	clean_logs $platform $remotedir "$runlogfile"
	ssh $platform "cd $remotedir    &&
		$JUST_RUN $remotedir img/$img &&
		cat $runlog* > $runlogfile &&
		cat board_0_DDR0_POWER  > profile-ddr0-power-$runlogfile &&
		cat board_0_DDR1_POWER  > profile-ddr1-power-$runlogfile &&
		cat board_0_MPPA0_POWER > profile-mppa-power-$runlogfile &&
		cat board_0_MPPA0_TEMP  > profile-mppa-temp-$runlogfile &&
		cat board_0_PLX_TEMP    > profile-plx-tmp-$runlogfile"
	download $platform $remotedir $localdir "$runlogfile"
}

function run_replications
{
	img=$1
	exp=$2
	
	it=0
	outdir="$DIR_RESULTS_RAW/$exp"

	# platform=$1
	# remotedir=$2
	# srcdir=$3
	# img=$4
	# it=$5
	# localdir=$6
	# runlog=$7
	compile_and_run   \
		$PLATFORM     \
		$DIR_REMOTE   \
		$DIR_SOURCE   \
		$img          \
		$it           \
		$outdir       \
		$FILE_RUNLOG
	
	for i in {1..19}
	do
		just_run          \
			$PLATFORM     \
			$DIR_REMOTE   \
			$DIR_SOURCE   \
			$img          \
			$i            \
			$outdir       \
			$FILE_RUNLOG
	done
}

function run_experiments
{
	nthreads_macro="#define TESTS_NTHREADS"
	npages_macro="#define NPAGES"
	nnodes_macro="#define NR_NODES"

	nthreads_default="$nthreads_macro 0"
	npages_default="$npages_macro 0"
	nnodes_default="$nnodes_macro 0"

	parallel_activate="#define TEST_PARALLEL_MIGRATION 1"
	parallel_deactivate="#define TEST_PARALLEL_MIGRATION 0"

	multiple_threads_activate="#define TEST_MULTIPLE_THREADS 1"
	multiple_threads_deactivate="#define TEST_MULTIPLE_THREADS 0"
	

	# Multiple Threads tests
	img="mppa256-migration-multiple-threads.img"
	exp_prefix="multiple-threads"

	replace $DIR_SOURCE "$nnodes_default" "$nnodes_macro 3"
	replace $DIR_SOURCE "$multiple_threads_deactivate" "$multiple_threads_activate"
	for curr_nthreads in 0 1 2 4 8 16;
	do
		replace $DIR_SOURCE "$nthreads_default" "$nthreads_macro $curr_nthreads"
		for curr_npages in 0 1 2 4 8 16 32;
		do
			replace $DIR_SOURCE "$npages_default" "$npages_macro $curr_npages"

			run_replications $img "$exp_prefix-$curr_nthreads-$curr_npages"

			replace $DIR_SOURCE "$npages_macro $curr_npages" "$npages_default"

		done
		replace $DIR_SOURCE "$nthreads_macro $curr_nthreads" "$nthreads_default"
	done
	replace $DIR_SOURCE "$nnodes_macro 3" "$nnodes_default"
	replace $DIR_SOURCE "$multiple_threads_activate" "$multiple_threads_deactivate"


	# Parallel tests
	imgprefix="mppa256-migration-parallel"
	exp_prefix="parallel"
	replace $DIR_SOURCE "$nthreads_default" "$nthreads_macro 16"
	replace $DIR_SOURCE "$npages_default" "$npages_macro 32"
	replace $DIR_SOURCE "$parallel_deactivate" "$parallel_activate"
	for curr_clusters in 2 4 8 16
	do
		replace $DIR_SOURCE "$nnodes_default" "$nnodes_macro $(($curr_clusters+1))"
		img="$imgprefix-$curr_clusters.img"

		run_replications $img "$exp_prefix-$curr_clusters"

		replace $DIR_SOURCE "$nnodes_macro $(($curr_clusters+1))" "$nnodes_default"
	done
	replace $DIR_SOURCE "$parallel_activate" "$parallel_deactivate"
	replace $DIR_SOURCE "$nthreads_macro 16" "$nthreads_default"
	replace $DIR_SOURCE "$npages_macro 32" "$npages_default"
}

#===============================================================================


configureRemote $PLATFORM $DIR_SCRIPTS $BASEDIR_REMOTE
run_experiments

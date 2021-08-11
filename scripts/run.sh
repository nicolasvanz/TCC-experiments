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

ADDONS_OFF="export ADDONS ?="
ADDONS_ON="export ADDONS ?= -D__NANVIX_MICROKERNEL_STATIC_SCHED=1"

# Current version
if [ "$1" == "--baseline" ] || [ "$2" == "--baseline" ];
then
	OUTDIR=$DIR_RESULTS_RAW/$HASH-baseline
else
	OUTDIR=$DIR_RESULTS_RAW/$HASH
fi

echo "[+] Build Output"
mkdir -p $OUTDIR

#===============================================================================

#
# Replaces strings recursively.
#
function replace
{
	dir=$1
	oldstr=$2
	newstr=$3

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

	cd $srcdir

		replace . $off $on

	cd $curdir
}

#
# Checkout source code.
#
function checkout
{
	srcdir=$1
	commit=$2
	curdir=$PWD

	echo "[+] Checking out the $srcdir repository to $commit commit"

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
	platform=$1
	scripts=$2
	basedir=$3
	runfile=$4

	echo "[+] Configuring remote"

	ssh $platform "rm -rf $basedir/* ; mkdir $basedir/benchmarks"
	$UPLOAD $scripts/arch/$platform/$runfile.sh $platform:$basedir
}

#
# Upload source code.
#
function upload
{
	platform=$1
	destdir=$2
	srcdir=$3

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

	scp "$platform:$remotedir/$localfile" $localdir/$localfile
	scp "$platform:$remotedir/profile-*" $localdir
}

#
# Run experiment.
#
function run
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

	echo "[+] Running $runlogfile"

	# checkout $srcdir $commit

	switchAddons $srcdir $ADDONS_ON $ADDONS_OFF

	upload $platform $remotedir $srcdir

	ssh $platform "cd $remotedir    &&
		$RUN $remotedir img/$img    &&
		cat $runlog-* > $runlogfile &&
		cat board_0_DDR0_POWER  > profile-ddr0-power-$runlogfile &&
		cat board_0_DDR1_POWER  > profile-ddr1-power-$runlogfile &&
		cat board_0_MPPA0_POWER > profile-mppa-power-$runlogfile &&
		cat board_0_MPPA0_TEMP  > profile-mppa-temp-$runlogfile &&
		cat board_0_PLX_TEMP    > profile-plx-tmp-$runlogfile"

	download $platform $remotedir $localdir "$runlogfile"

	switchAddons $srcdir $ADDONS_OFF $ADDONS_ON
}

#===============================================================================

function run_benchs
{
	for exp in noise fork-join;
	do
		img=mppa256-$exp.img

		for (( it=0; it<$NITERATIONS; it++ ));
		do
			run               \
				$PLATFORM     \
				$DIR_REMOTE   \
				$DIR_SOURCE   \
				$COMMIT       \
				$img          \
				$exp          \
				$it           \
				$OUTDIR       \
				$FILE_RUNLOG
		done
	done
}

#===============================================================================

configureRemote $PLATFORM $DIR_SCRIPTS $BASEDIR_REMOTE run

#===============================================================================

run_benchs

#===============================================================================


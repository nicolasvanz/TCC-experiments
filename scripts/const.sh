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

#===============================================================================
# Utilities
#===============================================================================

UPLOAD="rsync -avz --delete-after --exclude='*.o' --exclude='.git' --exclude='*.swp' --exclude='doc'"
COMPILE_AND_RUN="bash ../compile_and_run.sh"
JUST_RUN="bash ../just_run.sh"
RUN="bash ../run.sh"
if [[ "$OSTYPE" == "darwin"* ]]; then
	SED="gsed"
else
	SED="sed"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

function cecho
{
	echo -e "$1$2$NC"
}

#===============================================================================
# Directories
#===============================================================================

DIR_CURRENT=$PWD
DIR_PLOTS="$DIR_CURRENT/results/plots"
DIR_RESULTS_BASE="$DIR_CURRENT/results"
DIR_RESULTS_EXPSET="$DIR_RESULTS_BASE"
DIR_RESULTS_RAW="$DIR_RESULTS_EXPSET/raw"
DIR_RESULTS_COOKED="$DIR_RESULTS_EXPSET/cooked"
DIR_RSCRIPTS="$DIR_CURRENT/rscripts"
DIR_SCRIPTS="$DIR_CURRENT/scripts"
BASEDIR_REMOTE="~/souto"

#===============================================================================
# Files
#===============================================================================

FILE_RUNLOG="nanvix-cluster"

#===============================================================================
# Experiment
#===============================================================================

NITERATIONS=3
PLATFORM="mppa"

# Benchmark folders
BENCHMARK_DIR_REMOTE="$BASEDIR_REMOTE/benchmarks"
BENCHMARK_DIR_SOURCE="$DIR_CURRENT/code/benchmarks"

# Baseline version
BASELINE_COMMIT="0cc2b9df818cb83fd80023cb124ade6632816ce7"
BASELINE_HASH="0cc2b9d"

# Baseline version
TASK_COMMIT="a9640c87924ae1fe4c42ccd01d07c49845036951"
TASK_HASH="a9640c8"

# Current version
DIR_REMOTE=$BENCHMARK_DIR_REMOTE
DIR_SOURCE=$BENCHMARK_DIR_SOURCE
COMMIT=$TASK_COMMIT
HASH=$TASK_HASH
OUTDIR=$DIR_RESULTS_RAW/$HASH

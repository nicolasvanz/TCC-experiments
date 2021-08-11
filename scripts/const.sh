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
RUN="bash ../run.sh"
if [[ "$OSTYPE" == "darwin"* ]]; then
	SED="gsed"
else
	SED="sed"
fi

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
BASEDIR_REMOTE="~/nanvix"

#===============================================================================
# Files
#===============================================================================

FILE_RUNLOG="nanvix-cluster"

#===============================================================================
# Experiment
#===============================================================================

NITERATIONS=10
PLATFORM="mppa"

# Benchmark folders
DIR_REMOTE="$BASEDIR_REMOTE/benchmarks"
DIR_SOURCE="$DIR_CURRENT/code/benchmarks"

# Benchmark versions
COMMIT="4ef39d30cd70289559d0c49bcf59f6de5e40aa9d"
HASH="4ef39d3"


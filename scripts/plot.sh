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

function plot() {
	category=$1
	script=$2
	exp=$3
	power_it=$3

	cecho $BLUE "plotting $exp ..."

	Rscript --vanilla $DIR_RSCRIPTS/$script.R  \
		$DIR_RESULTS_COOKED/$category/$exp.csv \
		$DIR_PLOTS/$category                   \
		$exp                                   \
		$power_it
}

mkdir -p $DIR_PLOTS/capbench
mkdir -p $DIR_PLOTS/services
mkdir -p $DIR_PLOTS/microbenchmarks

# Category
for args in fn,1 gf,1 km,1;
do
	#=======================================================================
	# Separates parameters: Experiment + Iteration used in the calculation of
	# energy consumption
	#=======================================================================
	IFS=","
	set -- $args

	exp=$1
	power_it=$2
	#=======================================================================

	plot capbench capbench $exp $power_it
done

# Services
plot services services services 0

# Services
plot services sizes sizes 0

# Category
for args in core-usage,0 syscalls,1 create-wait,1;
do
	#=======================================================================
	# Separates parameters: Experiment + Iteration used in the calculation of
	# energy consumption
	#=======================================================================
	IFS=","
	set -- $args

	exp=$1
	power_it=$2
	#=======================================================================

	plot microbenchmarks $exp $exp $power_it
done

rm Rplots.pdf
#mv *.pdf $DIR_PLOTS


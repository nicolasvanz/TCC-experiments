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
# Concatenates run logs.
#
function concatenate {
	runlogs=$1

	cat $runlogs-*
}

#
# Filter raw results.
#
function filter {
	exp=$1
	col=$2

	grep "\[$exp\]" | \
	cut -d " " -f $col-
}

#
# Formats raw results.
#
function format {
	$SED -e "s/ /;/g"
}

#
# parse power logs
#
function parse_powerlog {
	dir=$1
	hash=$2
	middle=$3
	nprocs=$4
	exp=$5
	outfile=$6
	version=$7

	# Clean up long names
	for it in {0..4};
	do
		for component in mppa-power;
		do
			powerlogfile=$dir/$hash-procs-$middle$nprocs/profile-$component-$exp-nanvix-cluster-$it

			if [ ! -e $powerlogfile ];
			then
				echo "Missing $it execution of $exp ($version) : $powerlogfile"
				continue
			fi

			cat $powerlogfile                                   | \
				$SED "$ d"                                      | \
				format                                          | \
				$SED -e "s/^/$version;$component;$nprocs;$it;/"   \
			>> $outfile
		done
	done

	# Clean up long names
	$SED -i -e "s/mppa-power/power/g" $outfile
}

#
# parse power logs
#
function parse_powerlog_services {
	dir=$1
	hash=$2
	nprocs=$3
	exp=$4
	outfile=$5
	version=$6

	# Clean up long names
	#for it in 0;
	#do
		for component in mppa-power;
		do
			powerlogfile=$dir/$hash-$exp/profile-$component-$exp-nanvix-cluster-$nprocs

			if [ ! -e $powerlogfile ];
			then
				echo "Missing $nprocs execution of $exp ($version) : $powerlogfile"
				continue
			fi

			cat $powerlogfile                                      | \
				$SED "$ d"                                         | \
				format                                             | \
				$SED -e "s/^/$exp;$version;$component;$nprocs;0;/"   \
			>> $outfile
		done
	#done

	# Clean up long names
	$SED -i -e "s/mppa-power/power/g" $outfile
}

: << END

#================================================================================

baseline_hash=$BASELINE_HASH-baseline
comm_hash=$BASELINE_HASH-comm
task_hash=$TASK_HASH-task

mkdir -p $DIR_RESULTS_COOKED/capbench/

for exp in fast is lu;
do
	echo "parsing $exp ..."

	csvfile=$DIR_RESULTS_COOKED/capbench/$exp.csv
	powerfile=$DIR_RESULTS_COOKED/capbench/$exp-profile.csv
	raw_dir=$DIR_RESULTS_RAW

	# Write header.
	echo "exp;api;nprocs;time" > $csvfile
	echo "version;component;nprocs;it;time;power" > $powerfile

	for nprocs in {12,24,48,96,192};
	do
		for versions in baseline,$baseline_hash comm,$comm_hash daemons,$task_hash;
		do
			IFS=","
			set -- $versions

			version=$1
			hash=$2

			cat $raw_dir/$hash-procs-$nprocs/$exp-nanvix-cluster-* | \
				grep "total time"                                  | \
				sed -E "s/[[:space:]]+/ /g"                        | \
				cut -d" " -f 9                                     | \
				sed -E "s/^/$exp;$version;$nprocs;/g"                \
			>> $csvfile

			parse_powerlog $raw_dir $hash "" $nprocs $exp $powerfile "$version"
		done
	done
done

baseline_hash=$BASELINE_HASH-baseline
comm_hash=$BASELINE_HASH-comm
task_hash=$TASK_HASH-task

mkdir -p $DIR_RESULTS_COOKED/detail

for exp in gf;
do
	echo "parsing $exp ..."

	csvfile=$DIR_RESULTS_COOKED/detail/$exp.csv
	powerfile=$DIR_RESULTS_COOKED/detail/$exp-profile.csv
	raw_dir=$DIR_RESULTS_RAW

	# Write header.
	echo "variant;cluster;type;id;cycle;amount" > $csvfile

	for nprocs in {12,24,48,96,192};
	do
		for versions in baseline,$baseline_hash;
		do
			IFS=","
			set -- $versions

			variant=$1
			hash=$2

			cat $raw_dir/$hash-procs-$nprocs/$exp-nanvix-cluster-* | \
				grep "detail"                                      | \
				sed -E "s/[[:space:]]+/ /g"                        | \
				cut -d" " -f 7-                                    | \
				sed -E "s/[[:space:]]+/;/g"                        | \
				sed -E "s/^/$variant;$nprocs;/g"                     \
			>> $csvfile
		done
	done
done

END

cat results/raw/bottleneck-detail \
  | grep "bottleneck" \
  |  sed -E "s/[[:space:]]+/ /g" \
  |  cut -d" " -f 9 \
  |  sed -E "s/^/it;tasks;size;unit;total;for/g" \
  >> results/cooked/bottleneck


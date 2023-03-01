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

experiments=(multiple-threads parallel)
mt_pages=(0 1 2 4 8 16 32)
mt_threads=(0 1 2 4 8 16)
p_clusters=(2 4 8 16)


parsed_result_dir_mt_thread=$DIR_RESULTS_PARSED/multiple_threads
parsed_result_dir_mt_parallel=$DIR_RESULTS_PARSED/parallel

mkdir -p $DIR_RESULTS_PARSED
mkdir -p $parsed_result_dir_mt_thread
mkdir -p $parsed_result_dir_mt_parallel
# Multiple threads
for mt_page in ${mt_pages[@]}; do
	for mt_thread in ${mt_threads[@]}; do
		raw_result_dir=$DIR_RESULTS_RAW/multiple-threads-$mt_thread-$mt_page
		parsed_result=$parsed_result_dir_mt_thread/multiple-threads-$mt_thread-$mt_page.csv
		echo "time" > $parsed_result
		cat $raw_result_dir/$FILE_RUNLOG* | grep "time" | cut -d " " -f 5 >> $parsed_result
	done
done

# Parallel
for p_cluster in ${p_clusters[@]}; do
	raw_result_dir=$DIR_RESULTS_RAW/parallel-$p_cluster
	parsed_result=$parsed_result_dir_mt_parallel/parallel-$p_cluster.csv
	echo "time" > $parsed_result
	cat $raw_result_dir/$FILE_RUNLOG* | grep "time" | cut -d " " -f 5 >> $parsed_result
done





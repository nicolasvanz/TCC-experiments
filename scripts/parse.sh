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
	from=$1
	to=$2

	$SED -E -e "s/$from/$to/g"
}

#
# parse run logs
#
function parse_runlog {
	dir=$1
	hash=$2
	exp=$3
	outfile=$4

	runlogfile=$dir/$hash/$exp

	concatenate $runlogfile   | \
		filter "benchmarks" 6 | \
		format "\[|\]" " "    | \
		format "  " " "       | \
		cut -d " " -f 3-      | \
		format " "  ";"         \
	>> $outfile
}

#
# parse power logs
#
function parse_powerlog {
	dir=$1
	hash=$2
	exp=$3
	outfile=$4
	version=$5

	# Clean up long names
	for it in {0..9};
	do
		for component in mppa-power; # ddr0-power ddr1-power mppa-temp plx-tmp
		do
			powerlogfile=$dir/$hash/profiles/profile-$component-$exp-nanvix-cluster-$it

			if [ ! -e $powerlogfile ];
			then
				echo "Missing $it execution of $exp ($version) : $powerlogfile"
				break
			fi

			cat $powerlogfile                         | \
				$SED "$ d"                            | \
				format " " ";"                        | \
				format "^" "$version;$component;$it;"   \
			>> $outfile
		done
	done

	# Clean up long names
	$SED -i -e "s/ddr0-power/ddr0/g" $outfile
	$SED -i -e "s/ddr1-power/ddr1/g" $outfile
	$SED -i -e "s/mppa-power/power/g" $outfile
	$SED -i -e "s/mppa-temp/temp/g" $outfile
	$SED -i -e "s/plx-tmp/plx/g" $outfile
}

#===============================================================================
# Thread vs Dispatch
#===============================================================================

hash="08af852"
mkdir -p $DIR_RESULTS_COOKED/$hash/

csvfile=$DIR_RESULTS_COOKED/$hash/fork-dispatch.csv
powerfile=$DIR_RESULTS_COOKED/$hash/fork-dispatch-profile.csv

# Write header.
echo "kernel;core;it;operation;amount;dtlb;itlb;reg;branch;dcache;icache;cycles" > $csvfile
echo "version;component;it;time;power" > $powerfile

# Populate csv.
for exp in fork-join dispatch-wait;
do
	echo "[+] Parsing $exp"
	parse_runlog $DIR_RESULTS_RAW $hash $exp $csvfile
done

parse_powerlog $DIR_RESULTS_RAW $hash fork-join $powerfile baseline
parse_powerlog $DIR_RESULTS_RAW $hash dispatch-wait $powerfile task


#===============================================================================
# Master core usage
#===============================================================================

hash0="4ef39d3"
hash1="$hash0-baseline"

echo "[+] Parsing Core Usage"

mkdir -p $DIR_RESULTS_COOKED/$hash0/
csvfile=$DIR_RESULTS_COOKED/$hash0/heartbeat-core-usage.csv
powerfile=$DIR_RESULTS_COOKED/$hash0/heartbeat-core-usage-profile.csv

# Write header.
echo "version;service;it;mtime;dtime;utime;total;kerror;cerror" > $csvfile
echo "version;component;it;time;power" > $powerfile

# Task
for exp in heartbeat-core-usage;
do
	runlogfile=$DIR_RESULTS_RAW/$hash0/$exp

	concatenate $runlogfile     | \
		filter "benchmarks" 6   | \
		format "\[|\]" " "      | \
		format "  " " "         | \
		cut -d " " -f 3-        | \
		format " " ";"          | \
		format "-core-usage" "" | \
		format "^" "task;"        \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash0 $exp $powerfile task
done

# Baseline
for exp in heartbeat-core-usage;
do
	runlogfile=$DIR_RESULTS_RAW/$hash1/$exp

	concatenate $runlogfile         | \
		filter "benchmarks" 6       | \
		format "\[|\]" " "          | \
		format "  " " "             | \
		cut -d " " -f 3-            | \
		format " " ";"              | \
		format "-core-usage" "" | \
		format "^" "baseline;"        \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile baseline
done

mkdir -p $DIR_RESULTS_COOKED/$hash0/
csvfile=$DIR_RESULTS_COOKED/$hash0/lookup-core-usage.csv
powerfile=$DIR_RESULTS_COOKED/$hash0/lookup-core-usage-profile.csv

# Write header.
echo "version;service;it;mtime;dtime;utime;total;kerror;cerror" > $csvfile
echo "version;component;it;time;power" > $powerfile

# Task
for exp in lookup-core-usage;
do
	runlogfile=$DIR_RESULTS_RAW/$hash0/$exp

	concatenate $runlogfile     | \
		filter "benchmarks" 6   | \
		format "\[|\]" " "      | \
		format "  " " "         | \
		cut -d " " -f 3-        | \
		format " " ";"          | \
		format "-core-usage" "" | \
		format "^" "task;"        \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash0 $exp $powerfile task
done

# Baseline
for exp in lookup-core-usage;
do
	runlogfile=$DIR_RESULTS_RAW/$hash1/$exp

	concatenate $runlogfile         | \
		filter "benchmarks" 6       | \
		format "\[|\]" " "          | \
		format "  " " "             | \
		cut -d " " -f 3-            | \
		format " " ";"              | \
		format "-core-usage" "" | \
		format "^" "baseline;"        \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile baseline
done

#===============================================================================
# Syscalls
#===============================================================================

hash="4ef39d3"
mkdir -p $DIR_RESULTS_COOKED/$hash/

csvfile=$DIR_RESULTS_COOKED/$hash/syscalls.csv
powerfile=$DIR_RESULTS_COOKED/$hash/syscalls-profile.csv

echo "type;it;noperations;nusers;ntaskers;cycles" > $csvfile
echo "version;component;it;time;power" > $powerfile

for exp in syscall;
do
	echo "[+] Parsing $exp"

	parse_runlog $DIR_RESULTS_RAW $hash $exp $csvfile
	$SED -i -e "s/-syscall//g" $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash $exp $powerfile baseline
	parse_powerlog $DIR_RESULTS_RAW $hash $exp $powerfile task
done

: << END

#===============================================================================
# Noise
#===============================================================================

hash="173c9d4"
mkdir -p $DIR_RESULTS_COOKED/$hash/

csvfile=$DIR_RESULTS_COOKED/$hash/noise.csv

# Write header.
echo "name;type;it;nworkers;nkcalls;nios;noperations;cycles;icache;dcache;branch;reg;itlb;dtlb" > $csvfile

for exp in noise;
do
	echo "[+] Parsing $exp"
	parse_runlog $DIR_RESULTS_RAW $hash $exp $csvfile
done

#===============================================================================
# Services
#===============================================================================

hash0="8a71137"
hash1="8a71137-baseline"
mkdir -p $DIR_RESULTS_COOKED/$hash0/

csvfile=$DIR_RESULTS_COOKED/$hash0/services.csv
powerfile=$DIR_RESULTS_COOKED/$hash0/services-profile.csv

echo "[+] Parsing services (task)"

# Write header.
echo "version;service;cycles" > $csvfile
echo "version;component;it;time;power" > $powerfile

for exp in heartbeat lookup;
do
	runlogfile=$DIR_RESULTS_RAW/$hash0/$exp

	concatenate $runlogfile   | \
		filter "benchmarks" 6 | \
		format "\[|\]" " "    | \
		format "  " " "       | \
		cut -d " " -f 3-      | \
		format " "  ";"       | \
		format "^" "task;"      \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash0 $exp $powerfile task
done

runlogfile=$DIR_RESULTS_RAW/$hash0/pgfetch
concatenate $runlogfile       | \
	filter "benchmarks" 6     | \
	format "\[|\]" " "        | \
	format "  " " "           | \
	cut -d " " -f 3 -f 6      | \
	format "pfetch" "pgfetch" | \
	format " "  ";"           | \
	format "^" "task;"          \
>> $csvfile

parse_powerlog $DIR_RESULTS_RAW $hash0 pgfetch $powerfile task

runlogfile=$DIR_RESULTS_RAW/$hash0/pginval
concatenate $runlogfile       | \
	filter "benchmarks" 6     | \
	format "\[|\]" " "        | \
	format "  " " "           | \
	cut -d " " -f 3-4         | \
	format " "  ";"           | \
	format "^" "task;"          \
>> $csvfile

parse_powerlog $DIR_RESULTS_RAW $hash0 pginval $powerfile task

echo "[+] Parsing services (baseline)"

for exp in heartbeat lookup;
do
	runlogfile=$DIR_RESULTS_RAW/$hash1/$exp

	concatenate $runlogfile    | \
		filter "benchmarks" 6  | \
		format "\[|\]" " "     | \
		format "  " " "        | \
		cut -d " " -f 3-       | \
		format " "  ";"        | \
		format "^" "baseline;"   \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile baseline
done

runlogfile=$DIR_RESULTS_RAW/$hash1/pgfetch
concatenate $runlogfile       | \
	filter "benchmarks" 6     | \
	format "\[|\]" " "        | \
	format "  " " "           | \
	cut -d " " -f 3 -f 6      | \
	format "pfetch" "pgfetch" | \
	format " "  ";"           | \
	format "^" "baseline;"      \
>> $csvfile

parse_powerlog $DIR_RESULTS_RAW $hash1 pgfetch $powerfile baseline

runlogfile=$DIR_RESULTS_RAW/$hash1/pginval
concatenate $runlogfile       | \
	filter "benchmarks" 6     | \
	format "\[|\]" " "        | \
	format "  " " "           | \
	cut -d " " -f 3-4         | \
	format " "  ";"           | \
	format "^" "baseline;"      \
>> $csvfile

parse_powerlog $DIR_RESULTS_RAW $hash1 pginval $powerfile baseline

#===============================================================================

END

#===============================================================================
# Services
#===============================================================================

hash0="4ef39d3"
hash1="$hash0-baseline"
mkdir -p $DIR_RESULTS_COOKED/$hash0/

csvfile=$DIR_RESULTS_COOKED/$hash0/services.csv
powerfile=$DIR_RESULTS_COOKED/$hash0/services-profile.csv

echo "[+] Parsing services (task)"

# Write header.
echo "version;cycles" > $csvfile
echo "version;component;it;time;power" > $powerfile

for exp in services-dispatcher;
do
	runlogfile=$DIR_RESULTS_RAW/$hash0/$exp

	concatenate $runlogfile   | \
		filter "benchmarks" 6 | \
		format "\[|\]" " "    | \
		format "  " " "       | \
		cut -d " " -f 4-      | \
		format " "  ";"         \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash0 $exp $powerfile $exp
done

for exp in services-thread services-user;
do
	runlogfile=$DIR_RESULTS_RAW/$hash1/$exp

	concatenate $runlogfile   | \
		filter "benchmarks" 6 | \
		format "\[|\]" " "    | \
		format "  " " "       | \
		cut -d " " -f 4-      | \
		format " "  ";"         \
	>> $csvfile

	parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile $exp

done

$SED -i -e "s/services-//g" $csvfile
$SED -i -e "s/services-//g" $powerfile

#===============================================================================


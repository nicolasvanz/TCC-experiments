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
			powerlogfile=$dir/$hash/profile-$component-$exp-nanvix-cluster-$it

			if [ ! -e $powerlogfile ];
			then
				echo "Missing $it execution of $exp ($version) : $powerlogfile"
				continue
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
# Services
#===============================================================================

hash0=$NEW_HASH
hash1="$OLD_HASH-baseline"
mkdir -p $DIR_RESULTS_COOKED/



echo "[+] Parsing services (task)"

# Write header.

for exp in fork-join;
do
	csvfile=$DIR_RESULTS_COOKED/$exp.csv
	powerfile=$DIR_RESULTS_COOKED/$exp-profile.csv

	echo "version;type;it;operation;amount;dtlb;itlb;reg;branch;dcache;icache;cycles" > $csvfile
	echo "version;component;it;time;power" > $powerfile

	for h in $hash0 $hash1;
	do
		runlogfile=$DIR_RESULTS_RAW/$h/$exp
		if [ $h == $NEW_HASH ];
		then
			version="new"
		else
			version="old"
		fi

		concatenate $runlogfile   | \
			filter "benchmarks" 6 | \
			format "\[|\]" " "    | \
			format "  " " "       | \
			cut -d " " -f 4-      | \
			format " "  ";"       | \
			format "^"  "$version;" \
		>> $csvfile

		parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile $version
	done
done


for exp in noise;
do
	csvfile=$DIR_RESULTS_COOKED/$exp.csv
	powerfile=$DIR_RESULTS_COOKED/$exp-profile.csv

	echo "version;it;noise;nworkers;nidle;cycles;icache;dcache;branch;reg;itlb;dtlb" > $csvfile
	echo "version;component;it;time;power" > $powerfile

	for h in $hash0 $hash1;
	do
		runlogfile=$DIR_RESULTS_RAW/$h/$exp
		if [ $h == $NEW_HASH ];
		then
			version="new"
		else
			version="old"
		fi

		concatenate $runlogfile   | \
			filter "benchmarks" 6 | \
			format "\[|\]" " "    | \
			format "  " " "       | \
			cut -d " " -f 4-      | \
			format " "  ";"       | \
			format "^"  "$version;" \
		>> $csvfile

		parse_powerlog $DIR_RESULTS_RAW $hash1 $exp $powerfile $version
	done
done

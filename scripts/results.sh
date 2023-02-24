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

function compact {
	filename=$1

	for hash in $BASELINE_HASH $TASK_HASH;
	do
		for exp in fn gf km;
		do
			for f in results/raw/$hash*/$exp*;
			do
				cat $f | grep -E "capbench" > $f-temp;
				mv $f-temp $f;
			done
		done;
	done

	today=`date +"%Y-%m-%d"`
	tar -czvf $filename-$BASELINE_HASH-$TASK_HASH-$today.tar.gz raw
}

#===============================================================================

function extract {
	filename=$1

	if [ -f "$filename" ]; then
		echo "$FILE exists."
	fi

	tar -xzvf $filename results/raw
}

#================================================================================

	echo "Null operation";
	return 256
fi
case $1
	compact|extract)
		if [[ -z "$2" ]]; then
			echo "Empty filename"
		else
			$1 $2
		fi
		;;
	*)
		echo "Please use one of the parameters: compact/extract filename"
		;;
esac

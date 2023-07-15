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


if [ -d "$DIR_VENV" ];
then
    cecho $GREEN "[+] Virtual environment already installed. Running plots"
else
    cecho $GREEN "[+] Installing virtual environment"
    python3 -m virtualenv $DIR_VENV
    $VENV_PIP install -r $DIR_PYTHONSCRIPTS/requirements.txt
fi

mkdir -p $DIR_PLOTS

mppa_freq=$((400*10**6))

cecho $GREEN "[+] Plotting results"
$VENV_RUN $DIR_PYTHONSCRIPTS/plt_parallel.py $DIR_RESULTS_PARSED/parallel $DIR_PLOTS/parallel.pdf $mppa_freq
# $VENV_RUN $DIR_PYTHONSCRIPTS/plt_multiple_threads.py $DIR_RESULTS_PARSED/multiple_threads $DIR_PLOTS/multiple_threads.pdf $mppa_freq
$VENV_RUN $DIR_PYTHONSCRIPTS/plt_multiple_threads2.py $DIR_RESULTS_PARSED/multiple_threads $DIR_PLOTS/multiple_threads.pdf $mppa_freq



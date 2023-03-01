DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"

source $DIR_SCRIPT/const.sh

cecho $RED "[+] Cleaning up python virtual environment"
rm -rf $DIR_VENV
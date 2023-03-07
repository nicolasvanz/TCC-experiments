DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"

source $DIR_SCRIPT/const.sh

cecho $RED "[+] Cleaning up python cache"
find . | grep -E "(/__pycache__)" | xargs rm -rf

cecho $RED "[+] Cleaning up python virtual environment"
rm -rf $DIR_VENV
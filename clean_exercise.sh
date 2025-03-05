#!/bin/bash

##############################################################################
#  fit_todoman
#  Some simple exercise tracking / adding scripts using todoman
#  This script is to clean undone exercises from a todo list; it is intended to be 
#  run at midnight.  Hopefully making a cronjob doesn't bork it.
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

##############################################################################
# Variables
##############################################################################
VERSION="0.1.0"
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=1
DAYOFWEEK=$(date +%A)
DATE=$(date +%Y-%m-%d)
LIST=""
INIFILE=""

function loud() {
##############################################################################
# loud outputs on stderr 
##############################################################################    
    if [ $LOUD -eq 1 ];then
        echo "$@" 1>&2
    fi
}



if [ -z "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
    export XDG_CONFIG_HOME="${HOME}/.config"
    export XDG_CACHE_HOME="${HOME}/.cache"
fi

if [ ! -d "${XDG_CONFIG_HOME}" ];then
    loud "Your XDG_CONFIG_HOME variable is not properly set and does not exist."
    exit 99
fi

if [ -f "${XDG_CONFIG_HOME}/fit_todoman.ini" ];then
    INIFILE="${XDG_CONFIG_HOME}/fit_todoman.ini"
else 
    if [ -f "${SCRIPT_DIR}/fit_todoman.ini" ];then
        INIFILE="${SCRIPT_DIR}/fit_todoman.ini"
    else
        loud "Config file does not exist in ${XDG_CONFIG_HOME} or ${SCRIPT_DIR}!"
        exit 99
    fi
fi

# get list to use from INI
LIST=$(grep "LIST_TO_USE" "${INIFILE}" | grep -ve "^#" | awk -F '=' '{print $2}')
TODO_BIN=$(grep "TODO_BIN" "${INIFILE}" | grep -ve "^#" | awk -F '=' '{print $2}')
if [ "$LIST" != "" ];then
    TheTasks=$("${TODO_BIN}" list --grep @exercise \"${LIST}\")
else
    TheTasks=$("${TODO_BIN}" list --grep @exercise)
fi

# Get today's date in YYYY-MM-DD format
current_date=$(date +%F)


# Loop through each line and check the date
echo "$TheTasks" | while IFS= read -r line; do
  # Extract the task number and the date
  task_number=$(echo "$line" | awk '{print $2}')
  task_date=$(echo "$line" | awk '{print $3}')

  # Compare the dates
  if [[ "$task_date" < "$current_date" ]]; then
    loud "$task_number was before today: ${line}"
    # "${TODO_BIN}" delete "$task_number"
  fi
done

#!/bin/bash

##############################################################################
#  fit_todoman
#  Some simple exercise tracking / adding scripts using todoman
#  This script is to add exercises to a todo list; it is intended to be 
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

display_help(){
##############################################################################
# Show the Help
##############################################################################    
    echo "###################################################################"
    echo "# Standalone: /path/to/FILENAME.sh [options]"
    echo "# Info ############################################################"
    echo "# --help:  show help "
    echo "# --readme: display the README on the console"
    echo "# Usage ###########################################################"    
    echo "###################################################################"
}


###############################################################################
# Establishing XDG directories, or creating them if needed.
# Find config ini file
############################################################################### 


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


found=0
while IFS= read -r line; do
    if [[ $found -eq 0 ]]; then
        # find day of week heading
        # Check if the line contains DAYOFWEEK
        if echo "$line" | grep -q "$DAYOFWEEK"; then
            found=1
            loud "Found $DAYOFWEEK in $line"
            loud "Now to read in exercises for $DAYOFWEEK"
        fi
    else
        # If a line starts with [ then break out of the loop.
        if [[ $line =~ ^\[ ]]; then
            break
        fi
        # It's an exercise line.
        # each line is an exercise formatted
        # exercise description and stuff;HH:MM
        # Note separator is a semicolon
        # if HHMM is empty, substitute 00:00
        # run it at midnight, add each line as a task
        exercise_description=$(echo "${line}" | awk -F ';' '{ print $1 }' | sed 's|["]|“|g' | sed 's|['\'']|’|g' | detox --inline)
            #extra sed to unsmarten stray quotes, also detox            
        exercise_time=$(echo "${line}" | awk -F ';' '{ print $2 }')
        if [[ $exercise_time =~ ^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            loud "Valid time format"
        else
            loud "Invalid time format, using 20:00 (8pm)"
            exercise_time="20:00"
        fi
        if [ "$LIST" != "" ];then
            "${TODO_BIN}" new \""${exercise_description}" @exercise \" -d $DATE $exercise_time --list \"${LIST}\"  
        else
            #no special list used
            exec_string=$(printf "%s new \"%s\" @exercise -d %s %s" "${TODO_BIN}" "${exercise_description}" "${DATE}" "${exercise_time}")
            echo "$exec_string" 
            if [ $LOUD -eq 1 ];then 
                eval "$exec_string" 
            else
                eval "$exec_string" 2>/dev/null 1>/dev/null
            fi
        fi
        
    fi
done < "${INIFILE}"


 


#!/bin/bash

##############################################################################
#  fit_todoman
#  Some simple exercise tracking / adding scripts using todoman
#  This script is to record your weight in a simple CSV file
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
TIME=$(date +%H:%M)
UNITS=""
WEIGHT=""

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

if [ ! -d "${XDG_DATA_HOME}" ];then
    loud "Your XDG_DATA_HOME variable is not properly set and does not exist."
    exit 99
fi

#Just create the recording file if it doesn't exist
if [ ! -d "${XDG_DATA_HOME}/fit_todoman" ];then
    mkdir -p "${XDG_DATA_HOME}/fit_todoman"
    touch "${XDG_DATA_HOME}/fit_todoman/weight.csv"
else
    if [ ! -f "${XDG_DATA_HOME}/fit_todoman/weight.csv" ];then
        touch "${XDG_DATA_HOME}/fit_todoman/weight.csv"
    fi
fi
RECORDFILE="${XDG_DATA_HOME}/fit_todoman/weight.csv"

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

UNITS=$(grep "UNITS" "${INIFILE}" | grep -ve "^#" | awk -F '=' '{print $2}')
if [ "$UNITS" == "" ];then
    UNITS=LB
fi

# Display a YAD form with fields for Weight, Time, and Date.
result=$(yad --form \
    --title="Enter Data" \
    --text="Please enter your weight (in $UNITS), time (24h clock), and date:" \
    --field="Weight" "" \
    --field="Time" "$TIME" \
    --field="Date" "$DATE" \
    --width=400 --height=200)

# Check if the user pressed OK (exit status 0)
if [ $? -eq 0 ]; then
    # YAD returns the field values separated by '|'
    IFS="|" read -r WEIGHT time date <<< "$result"
    echo "Weight: $WEIGHT"
    if [ "$WEIGHT" == "" ];then 
        loud "Error: Weight not entered."
        exit 98
    fi
    # Re-saving these in case they were edited by the user if non-zero
    if [ "$TIME" != "" ];then
        TIME="$time"
    fi
    if [ "$DATE" != "" ];then
        DATE="$date"
    fi
    EPOCH=$(date -d "$DATE $TIME" +%s)
    # record in CSV
    # format - EPOCH,WEIGHT,DATE,TIME
    printf "%s,%s,%s,%s" $EPOCH $WEIGHT $DATE $TIME >> "${RECORDFILE}"
else
    echo "Operation cancelled by the user."
fi





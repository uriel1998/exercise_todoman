#!/bin/bash

##############################################################################
#  fit_todoman
#  Some simple exercise tracking / adding scripts using todoman
#  This script is to show your weight progress using gnuplot
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
TEMPFILE=$(mktemp)
DURATION=""

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

if [ ! -f "${XDG_DATA_HOME}/fit_todoman/weight.csv" ];then
    loud "No record file found, exiting"
    exit 99
else
    RECORDFILE="${XDG_DATA_HOME}/fit_todoman/weight.csv"
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

UNITS=$(grep "UNITS" "${INIFILE}" | grep -ve "^#" | awk -F '=' '{print $2}')
if [ "$UNITS" == "" ];then
    UNITS=LB
fi

#How many records back
#Default of 30 records (assuming 1 a day)
# command line switch of -d [number] for number of days back
# determine EPOCH time of DURATION days back as EPOCHBACK
# readlines, if $line's epoch date > $EPOCHBACK, copy to tempfile
# determine # of lines in tempfile for use in gnuplot template




    
    
    
    
    # loud "Creating table for $hours_count."
    out_datafile="${DATA_DIR}"/"${hours_count}".csv
    out_image="${OUT_DIR}"/"${hours_count}"_hours.png
    echo "date,metric,lat,long,alt" > "${out_datafile}"
    tail -${lines} "${INFILE}" | awk -F ',' '{print $1"@"$2","$3","$4","$5}' | sed 's/\./\:/' >> "${out_datafile}"
    loud "Creating Gnuplot for ${hours_count}"
    cat "${SCRIPT_DIR}"/plot_gnuplot_stub.txt > "${SCRIPT_DIR}"/plot_me.gnuplot
    printf "set output \'%s\'\n" "${out_image}" >> "${SCRIPT_DIR}"/plot_me.gnuplot
    printf "plot \"%s\" using 1:2 with lines ls 101\n" "${out_datafile}" >> "${SCRIPT_DIR}"/plot_me.gnuplot
    loud "Creating graph for ${hours_count}"
    gnuplot -p "${SCRIPT_DIR}"/plot_me.gnuplot
    out_image=""
    out_datafile=""

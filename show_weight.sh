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
BACKTIME=""
DATALINES=""

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

if [ "${1}" == "-d" ];then
    BACKTIME="${2}"
else
    BACKTIME="30"
fi
STARTTIME=$(date --date="$BACKTIME days ago" +%s)

echo "date,weight" > "${TEMPFILE}"

while IFS=, read -r column1 rest; do
    if [[ "$column1" -gt "${STARTTIME}" ]]; then
        echo "$rest" | awk -F ',' '{print $2"@"$3","$4"}' >> "${TEMPFILE}"
    fi
done < "${RECORDFILE}"

DATALINES=$(cat "${TEMPFILE}" | wc -l)
# needed for gnuplot template

#set up GNUPLOT template
OUTFILE="${XDG_DATA_HOME}/fit_todoman/weight_graph.png"
GNUPLOT="${XDG_CONFIG_HOME}/fit_todoman/plot_weight.gnuplot"
# may need to change these to printf statements
echo -e "set datafile separator ','" > "${GNUPLOT}"
echo -e "set key autotitle columnhead" >> "${GNUPLOT}"
echo -e "set xdata time" >> "${GNUPLOT}"
echo -e "set timefmt \"%m-%d-%Y@%H:%M\"" >> "${GNUPLOT}"
echo -e "set format x \"%m-%d\"" >> "${GNUPLOT}"
echo -e "set ylabel \"Weight ($UNITS)\"" >> "${GNUPLOT}"
echo -e "set xlabel 'Time'" >> "${GNUPLOT}"
echo -e "set style line 101 lw 3 lt rgb \"#859900\"" >> "${GNUPLOT}"
echo -e "set xtics rotate" >> "${GNUPLOT}"
echo -e "set terminal pngcairo size 400,300 enhanced font 'Segoe UI,10'" >> "${GNUPLOT}"

# do we need to put something in here to limit data due to lines?
printf "set output \'%s\'\n" "${OUTFILE}" >> "${GNUPLOT}"
printf "plot \"%s\" using 1:2 with lines ls 101\n" "${TEMPFILE}" >> "${GNUPLOT}"
    
loud "Creating graph for ${BACKTIME} days"
gnuplot -p "${GNUPLOT}"

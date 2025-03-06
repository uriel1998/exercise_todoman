This is meant to be a series of scripts to function as a pretty simple exercise 
adder and tracker, as well as recording one's weight.

Leverages todoman for the tasks https://github.com/pimutils/todoman

* `add_exercise.sh` - adds exercises listed in ini file as tasks for the day
* `clean_exercise.sh` - removes uncompleted exercises from before today
* `record_weight.sh` - YAD dialog to record your weight
* `show_weight.sh` - Plots your weight using gnuplot

Stuff you need

grep sed awk detox
dirname
readline
XDG directories appropriately configured
date
gnuplot

TODO: 
Convert on input from 12hr if checkbox marked
show_exercise
test cronjob for reminders?

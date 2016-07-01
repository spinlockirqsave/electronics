#!/bin/sh
# This script will display the current time as known
# by your computer on the 4 LED display.
# Copy (install) the command udpcom to /usr/bin before you run
# this script.
#
# Change this to the IP addess of your display:
ip_of_display="10.0.0.29"
#--------do not change anything below this line
curr_time=`date "+%H:%M"`
prev_time=""
trap 'udpcom "n=----" $ip_of_display; exit' SIGINT SIGQUIT SIGTERM
while true; do
	if [ "$curr_time" != "$prev_time" ]; then
		udpcom "n=$curr_time" $ip_of_display
		prev_time="$curr_time";
	fi
	sleep 1  # block loop for one sec then check again
	curr_time=`date "+%H:%M"`
done


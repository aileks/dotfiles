#!/bin/env sh

update_cpu () { 
    	read -r cpu a b c previdle rest < /proc/stat
	prevtotal=$((a+b+c+previdle))
	sleep 0.5
	read -r cpu a b c idle rest < /proc/stat
	total=$((a+b+c+idle))
	cpu=" 󰻠 $((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))%"
}

update_memory () { 
	memory="  $(free --giga -h | sed -n "2s/\([^ ]* *\)\{2\}\([^ ]*\).*/\2/p")"
}

update_time () { 
	time="  $(date "+%a %b %d %I:%M %P")"
}

update_bat () { 
	read -r bat_capacity </sys/class/power_supply/BAT1/capacity
	bat="󰁹 $bat_capacity%"
}

update_vol () { 
	vol="  $(pamixer --get-volume-human)"
}

display () { 
	xsetroot -name " $bat  | $cpu  | $memory  | $vol  | $time "
}

trap "update_vol;display" "RTMIN"
trap "update_bat;display" "RTMIN+2"

while true
do
    sleep 1 & wait && { 
	# to update item every n seconds with a offset of m
	## [ $((sec % n)) -eq m ] && udpate_item
	[ $((sec % 1 )) -eq 0 ] && update_cpu
	[ $((sec % 5 )) -eq 0 ] && update_memory
	[ $((sec % 60 )) -eq 0 ] && update_time
	[ $((sec % 5 )) -eq 0 ] && update_vol
	[ $((sec % 60)) -eq 0 ] && update_bat
	[ $((sec % 5 )) -eq 0 ] && display
	sec=$((sec + 1))
    }
done 

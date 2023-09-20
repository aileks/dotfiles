#!/bin/env sh

update_cpu () { 
	cpu=" 󰻠  $(top -bn 1 | grep '%Cpu' | tr -d 'usy,' | awk '{print $2} ' )"
}

update_memory () { 
	memory="   $(free --giga -h | sed -n "2s/\([^ ]* *\)\{2\}\([^ ]*\).*/\2/p")"
}

update_time () { 
	time="   $(date "+%a %b %d %I:%M %P")"
}

update_bat () { 
	read -r bat_capacity </sys/class/power_supply/BAT1/capacity
	bat="󰁹 $bat_capacity%"
}

update_vol () { 
	vol="   $(pamixer --get-volume-human)"
}

display () { 
	xsetroot -name " $bat $cpu $memory $vol $time "
}

trap "update_vol;display" "RTMIN"
trap "update_bat;display" "RTMIN+2"

while true
do
	sleep 1 & wait && { 
		# to update item ever n seconds with a offset of m
		## [ $((sec % n)) -eq m ] && udpate_item
		[ $((sec % 1 )) -eq 0 ] && update_cpu
		[ $((sec % 5 )) -eq 0 ] && update_memory
		[ $((sec % 30 )) -eq 0 ] && update_time
		[ $((sec % 5 )) -eq 0 ] && update_vol
		[ $((sec % 60)) -eq 0 ] && update_bat
		[ $((sec % 5 )) -eq 0 ] && display
		sec=$((sec + 1))
	}
done 


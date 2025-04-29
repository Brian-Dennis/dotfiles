#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait for the processes to close
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar on each connected monitor (using Hyprland info)
hyprctl monitors -j | jq -c '.[]' | while read -r monitor; do
  monitor_name=$(echo "$monitor" | jq -r .name)
  MONITOR="$monitor_name" polybar toph --config=/home/bd/dotfiles1/polybar/.config/polybar/config.ini --reload &
done

#!/bin/bash
export XDG_CONFIG_HOME="$HOME/.config_hyprland/waybar"
waybar -c "$XDG_CONFIG_HOME/config.jsonc" -s "$XDG_CONFIG_HOME/style.css" &

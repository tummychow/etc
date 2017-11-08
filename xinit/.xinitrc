#!/bin/bash
set -e

xrandr --output eDP-1 --primary --auto
xrandr --output HDMI-1 --same-as eDP-1

sxhkd &
dunst &

# TODO: this hack to find the wlan interface name is super gross
wpa_cli -p /run/wpa_supplicant -i "$(cd /run/wpa_supplicant && echo wlp*)" -a "${HOME}/bin/bin/wpa-notify" &

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32
EOF

xset s off
xset dpms 0 0 900

xsetroot -cursor_name left_ptr

exec bspwm

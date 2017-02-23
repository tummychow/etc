#!/bin/bash
set -e

xrandr --output eDP-1 --primary --auto
xrandr --output HDMI-2 --same-as eDP-1

sxhkd &
dunst &

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32
EOF

xset s off
xset dpms 0 0 900
xset r rate 200 33

xsetroot -cursor_name left_ptr

exec bspwm

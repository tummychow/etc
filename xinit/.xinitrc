#!/bin/bash
set -e

xrandr --output eDP-1 --primary --auto
xrandr --output HDMI-1 --same-as eDP-1

sxhkd &
dunst &

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32
EOF

xset s off
xset dpms 0 0 900

xsetroot -cursor_name left_ptr

exec bspwm

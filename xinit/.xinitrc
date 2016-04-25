#!/bin/bash
set -e

sxhkd -f 25 &

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32
EOF

xset s off
xset dpms 0 0 900
xset r rate 200 33

xsetroot -cursor_name left_ptr

exec bspwm

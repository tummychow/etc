#!/bin/bash
set -e

xsetroot -cursor_name left_ptr
xset r rate 250 25

sxhkd &
exec bspwm

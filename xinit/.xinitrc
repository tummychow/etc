#!/bin/bash
set -e

if [[ -d "/etc/X11/xinit/xinitrc.d" ]] ; then
  for F in /etc/X11/xinit/xinitrc.d/*.sh ; do
    source "${F}"
  done
fi

xrandr --output eDP-1 --primary --auto
xrandr --output HDMI-1 --same-as eDP-1

sxhkd &
dunst &

# launch a notifier for every wireless interface supervised by wpa_supplicant
for IF in /run/wpa_supplicant/* ; do
  IF="${IF##*/}"
  # wpa_supplicant control sockets do not correspond one-to-one with interfaces (eg "p2p-dev-wlp3s0")
  # however, the ones we want will have an 802.11 phy, which can be found in sysfs
  # TODO: this terminates if you restart wpa_supplicant, since the socket gets recreated
  if [[ -d "/sys/class/net/${IF}/phy80211" ]] ; then
    wpa_cli -p /run/wpa_supplicant -i "${IF}" -a "${HOME}/bin/bin/wpa-notify" &
  fi
done

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32
EOF

xset s off
xset dpms 0 0 900

xsetroot -cursor_name left_ptr

dex -a

exec bspwm

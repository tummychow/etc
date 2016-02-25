#!/bin/bash
set -e

sxhkd -f 25 &

xrdb -merge <<EOF
Xcursor.theme: Adwaita
Xcursor.size: 32

rofi.modi: run,window,pass:rofi-pass
rofi.terminal: st
rofi.fuzzy: true
rofi.sidebar-mode: true
rofi.font: Input 10
rofi.lines: 20
rofi.fixed-num-lines: true
rofi.line-margin: 0
rofi.separator-style: solid
rofi.padding: 0
rofi.bw: 2

rofi.color-enabled: true
rofi.color-normal: #202020, #b0b0b0, #303030, #b0b0b0, #202020
rofi.color-active: #202020, #40a0ff, #303030, #0070c4, #ffffff
rofi.color-urgent: #202020, #ff4040, #303030, #b03030, #ffffff
rofi.color-window: #202020, #b0b0b0

rofi.kb-primary-paste:
rofi.kb-secondary-paste: Control+v
rofi.kb-clear-line: Control+u
rofi.kb-move-front: Control+a
rofi.kb-move-end: Control+e
rofi.kb-move-word-back:
rofi.kb-move-word-forward:
rofi.kb-move-char-back: Left
rofi.kb-move-char-forward: Right
rofi.kb-remove-word-back:
rofi.kb-remove-word-forward:
rofi.kb-remove-char-forward:         Delete
rofi.kb-remove-char-back: BackSpace
rofi.kb-accept-entry: Return
rofi.kb-accept-custom: Control+Return
rofi.kb-accept-entry-continue: Shift+Return
rofi.kb-mode-next: Tab
rofi.kb-mode-previous: Shift+Tab
rofi.kb-toggle-case-sensitivity:
rofi.kb-delete-entry: Shift+Delete
rofi.kb-row-left:
rofi.kb-row-right:
rofi.kb-row-up: Up
rofi.kb-row-down: Down
rofi.kb-row-tab:
rofi.kb-page-prev: Page_Up
rofi.kb-page-next: Page_Down
rofi.kb-row-first: Home
rofi.kb-row-last: End
rofi.kb-row-select: Control+space
rofi.kb-cancel: Escape
rofi.kb-custom-1: Alt+1
rofi.kb-custom-2: Alt+2
rofi.kb-custom-3: Alt+3
rofi.kb-custom-4: Alt+4
rofi.kb-custom-5: Alt+5
rofi.kb-custom-6: Alt+6
rofi.kb-custom-7: Alt+7
rofi.kb-custom-8: Alt+8
rofi.kb-custom-9: Alt+9
rofi.kb-custom-10: Alt+0
rofi.kb-custom-11: Alt+Shift+1
rofi.kb-custom-12: Alt+Shift+2
rofi.kb-custom-13: Alt+Shift+3
rofi.kb-custom-14: Alt+Shift+4
rofi.kb-custom-15: Alt+Shift+5
rofi.kb-custom-16: Alt+Shift+6
rofi.kb-custom-17: Alt+Shift+7
rofi.kb-custom-18: Alt+Shift+8
rofi.kb-custom-19: Alt+Shift+9
EOF

xset s off
xset dpms 0 0 900
xset r rate 200 33

xsetroot -cursor_name left_ptr

exec bspwm

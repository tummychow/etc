# do nothing unless interactive
[[ $- != *i* ]] && return

# modify the PATH here

[[ -r ~/.bashrc ]] && source ~/.bashrc

[[ -z $DISPLAY && $XDG_VTNR == 1 ]] && exec startx

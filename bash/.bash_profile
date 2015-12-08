# do nothing unless interactive
[[ $- != *i* ]] && return

# modify the PATH here
[[ -d ~/bin ]] && export PATH=~/bin:$PATH

[[ -r ~/.bashrc ]] && source ~/.bashrc

if [[ -z $DISPLAY && $XDG_VTNR == 1 && -r ~/.xinitrc ]] ; then
  startx
fi

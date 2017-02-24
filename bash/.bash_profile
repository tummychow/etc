# do nothing unless interactive
[[ $- != *i* ]] && return

# modify the PATH here
[[ -d ~/bin ]] && export PATH=~/bin:$PATH
[[ -d "$GOPATH/bin" ]] && export PATH=$PATH:"$GOPATH/bin"

[[ -r ~/.bashrc ]] && source ~/.bashrc

if [[ -z $DISPLAY && $XDG_VTNR == 1 && -r ~/.xinitrc ]] ; then
  startx -- -ardelay 200 -arinterval 30
fi

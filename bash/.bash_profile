# do nothing unless interactive
[[ $- != *i* ]] && return

# set any other useful envars
export PASSWORD_STORE_CLIP_TIME=5
export EDITOR=nvim
export GOPATH=~/code/go
# for mpc
export MPD_HOST=~/.local/share/mpd/socket

# modify the PATH here
[[ -d ~/bin ]] && export PATH=~/bin:$PATH
[[ -d "$GOPATH/bin" ]] && export PATH=$PATH:"$GOPATH/bin"

[[ -r ~/.bashrc ]] && source ~/.bashrc

if [[ -z $DISPLAY && $XDG_VTNR == 1 && -r ~/.xinitrc ]] ; then
  startx -- -ardelay 200 -arinterval 30
fi

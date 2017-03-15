# do nothing unless interactive
[[ "${-}" != *i* ]] && return

# modify the PATH here
if [[ -d ~/bin ]] ; then
  for bindir in ~/bin/*/ ; do
    PATH="${bindir:0:-1}:${PATH}"
  done
fi
[[ -n "${GOPATH}" && -d "${GOPATH}/bin" ]] && PATH="${PATH}:${GOPATH}/bin"
[[ -n "${CARGO_HOME}" && -d "${CARGO_HOME}/bin" ]] && PATH="${PATH}:${CARGO_HOME}/bin"
export PATH

[[ -r ~/.bashrc ]] && source ~/.bashrc

if [[ -z "${DISPLAY}" && "${XDG_VTNR}" == 1 && -r ~/.xinitrc ]] ; then
  startx -- -ardelay 200 -arinterval 30
fi

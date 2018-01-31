# do nothing unless interactive
[[ "${-}" != *i* ]] && return

# modify the PATH here
if [[ -d ~/bin ]] ; then
  for bindir in ~/bin/*/ ; do
    PATH="${bindir:0:-1}:${PATH}"
  done
fi
if [[ -n "${GOPATH}" && -d "${GOPATH}/bin" ]] ; then
  PATH="${PATH}:${GOPATH}/bin"
fi
if [[ -n "${CARGO_HOME}" && -d "${CARGO_HOME}/bin" ]] ; then
  PATH="${PATH}:${CARGO_HOME}/bin"
fi
export PATH

if [[ -r ~/.bash_profile_private ]] ; then
  source ~/.bash_profile_private
fi
if [[ -r ~/.bashrc ]] ; then
  source ~/.bashrc
fi

if [[ -z "${DISPLAY}" && "${XDG_VTNR}" == 1 && -r ~/.xinitrc ]] ; then
  startx
fi

# do nothing unless interactive
[[ "${-}" != *i* ]] && return

if [[ "$(uname)" == Linux ]] ; then
  # eval is required to preserve quoting in the show-environment output
  eval export $(systemctl --user show-environment)
else
  # TODO: parse sd-env instead
  export EDITOR=nvim
  export RANGER_LOAD_DEFAULT_RC=FALSE
  export LESS=-RS
  export LESSHISTFILE=-
fi

# modify the PATH here
# TODO: has to happen after sd-env, better to move it into sd-env entirely
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

if [[ -f ~/.bash_profile_private ]] ; then
  source ~/.bash_profile_private
fi
if [[ -f ~/.bashrc ]] ; then
  source ~/.bashrc
fi

if [[ -z "${DISPLAY}" && "${XDG_VTNR}" == 1 && -f ~/.xinitrc ]] ; then
  startx
fi

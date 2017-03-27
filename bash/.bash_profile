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
  # we already set the rate params in xinitrc, but we also need to
  # set the defaults here
  # https://bugzilla.redhat.com/show_bug.cgi?id=601853
  # when udev detects a new keyboard, the xserver will add it to the
  # input list, which resets the rate params back to their default
  # values
  # so if we didn't have this, plugging in a keyboard would cause the
  # rate params to change, discarding the effects of the xset line in
  # xinitrc
  startx -- -ardelay 200 -arinterval 30
fi

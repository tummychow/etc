# do nothing unless interactive
[[ $- != *i* ]] && return

shopt -s checkwinsize histappend globstar checkjobs cmdhist histverify

# my prompt ignores the value of $TERM because it's too much trouble
# to figure out if it means anything useful
set_ps1() {
  # this will be overwritten by subshells or the local
  # builtin, so cache it at the start
  local ret=$?

  # the \[ and \] are special characters for PS1, they indicate a nonprinting
  # sequence in the prompt
  # \e is escape (aka \033 or \x1b), this character initiates an ANSI escape
  # the square bracket indicates a multi-character escape sequence
  # \e[ is called the Control Sequence Introducer (CSI)
  # the m indicates that the escape will Set the Graphic Rendition (SGR)
  # the parameters for the "m" are a semicolon-separated list of numbers
  # the empty list defaults to 0 (return to defaults)
  # 1 means use bold (typically also induces bright colors)
  # the standard color codes are 30-37 (fg) and 40-47 (bg)
  # you can use the aixterm 90-97 (fg) and 100-107 (bg) codes to get bright colors
  # without bold fonts (nonstandard, but widely supported)
  # see ECMA-48 for more details
  local neut="\[\e[m\]"

  local sep=' '

  # is this shell inside sudo/ssh?
  if [[ -n "${SUDO_USER}" || -n "${SSH_CLIENT}" ]] ; then
    # default to green, red if root
    local usercol='\[\e[32m\]'
    # $EUID set by bash itself
    [[ "${EUID}" == 0 ]] && usercol='\[\e[31m\]'
    # $USER set by login
    printf '%b[%b%s%b' "${neut}" "${usercol}" '\u' "${neut}"

    # print hostname as well, if remote
    # $HOSTNAME set by bash itself
    if [[ -n "${SSH_CLIENT}" ]] ; then
      printf '@%b%s%b' "${usercol}" '\h' "${neut}"
    fi
    printf ']%s' "${sep}"
  fi

  # print pwd in cyan
  printf '%b[%b%s%b]%s' "${neut}" '\[\e[36m\]' '\w' "${neut}" "${sep}"

  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == 'true' ]] ; then
    # find current checkout branch
    local checkout="$(git symbolic-ref --short -q HEAD)"
    # no branch? try tag
    [[ -z "${checkout}" ]] && checkout="$(git describe --tags --exact-match HEAD 2>/dev/null)"
    # no tag? try raw commit sha
    [[ -z "${checkout}" ]] && checkout="$(git rev-parse --verify --short -q HEAD^{commit})"
    # no raw commit sha? abnormal error condition
    [[ -z "${checkout}" ]] && checkout='ERROR'

    # parse the null-separated output of git status
    local -i unstaged=0 uncommitted=0 untracked=0 unresolved=0
    local statuscode skipnext
    while read -rd '' ; do
      [[ -n "${skipnext}" ]] && skipnext= && continue
      statuscode="${REPLY:0:2}"
      [[ "${statuscode}" == '??' ]] && let untracked++
      # remember, bash regexes in the =~ operator cannot be quoted
      [[ "${statuscode}" =~ \ [MDARC]|[\ MARC][MD] ]] && let unstaged++
      [[ "${statuscode}" =~ [MARC][MD\ ]|D[M\ ] ]] && let uncommitted++
      [[ "${statuscode}" =~ U|DD|AA ]] && let unresolved++
      # if the file was renamed, then git will have the new name on this line
      # and the old name on the next line; we want to skip that old name since
      # it could be mis-parsed as a status code
      [[ "${statuscode}" =~ R ]] && skipnext=true
    done < <(git status -z)

    # hack to check the number of stashes
    local stash="$(git rev-list --walk-reflogs --count refs/stash -- 2>/dev/null)"
    [[ -z "${stash}" ]] && stash=0

    # print the checkout itself in yellow
    printf '%b[%b%s' "${neut}" "\[\e[93m\]" "${checkout}"
    if (( unstaged + uncommitted + untracked + unresolved + stash )) ; then
      printf '%b|' "${neut}"
      (( unresolved )) && printf '%b=%s' '\[\e[35m\]' "${unresolved}" # purple
      (( untracked )) && printf '%b?%s' '\[\e[33m\]' "${untracked}" # brown
      (( unstaged )) && printf '%bx%s' '\[\e[31m\]' "${unstaged}" # red
      (( uncommitted )) && printf '%b^%s' '\[\e[32m\]' "${uncommitted}" # green
      (( stash )) && printf '%b+%s' '\[\e[34m\]' "${stash}" # cyan
    fi
    printf '%b]%s' "${neut}" "${sep}"
  fi

  # set the color of the prompt character
  if (( ret )) ; then
    # last command exited nonzero, use bold red
    printf '%b' '\[\e[1;91m\]'
  else
    if [[ "${#TTYLVL[@]}" != 0 ]] ; then
      # we have an interactive ancestor PID, use bold cyan
      printf '%b' '\[\e[1;96m\]'
    else
      # stick to the standard bold white
      printf '%b' '\[\e[1;97m\]'
    fi
  fi

  # then print the prompt character itself
  if [[ -n "$(jobs -ps)" ]] ; then
    # we have sleeping jobs, print an &
    printf '&'
  elif (( ret )) ; then
    # last command exited nonzero, print X
    printf 'X'
  else
    # print $ (or # if root)
    printf '%s' '\$'
  fi

  printf '%b ' "${neut}"

  # set the title of the terminal
  # \e] initiates an Operating System Command (OSC), whose interpretation is
  # system-dependent
  # \a is alert (aka bell, \007 or \x07), it terminates the OSC string
  # xterm interprets the string as a semicolon-separated list, it will set the
  # icon name and title when the first argument is 0
  # (you can use 2 to set the title only, however st treats 0/1/2 equivalently,
  # and some terminals, like iterm2, will only answer to a 0)
  # the second argument is the string that shall be the title; we can use the
  # special \w escape since we are in PS1
  printf '%b%s%b' '\[\e]0;' '\w' '\a\]'
}
PROMPT_COMMAND='PS1=$(set_ps1)'
PS2='> '
PS3='> '
PS4='+'

# we want to draw the prompt character in cyan if we have an interactive ancestor
# process, so that we remember not to close this entire terminal window
# you could hack this with $SHLVL or $BASH_SUBSHELL, but a better way is to check
# who's using the same tty device as you
# TODO: does this behave well if inside a terminal multiplexer or ssh?
declare -a ttypids
# first we have to use lsof to find programs holding an fd on our tty, we use the
# tty command to get the tty's path
# TODO: can we also use fuser -f? (http://pubs.opengroup.org/onlinepubs/9699919799/utilities/fuser.html)
# TODO: can we use lsof -p ^ to exclude this shell's pid and lsof's own pid?
# the tty command uses the ttyname function to return the path to the tty of
# its stdin fd (you can also find the tty from procfs but that's linux-only)
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/tty.html
# then we lsof to find processes holding that tty, excluding lsof itself (-c ^lsof)
# and listing only their pids (-t)
# note that if we invoke this inside a subshell it will cause more PIDs to be
# listed, so we have to do it early
# the exact subtleties of when extra subshells get listed depends a lot on how you
# invoke it, whether you pipe it into something, etc, so this is the safest and
# most predictable approach
lsofout="$(lsof -c ^lsof -t -- "$(tty)")"
# now we build up an array whose indices are the pids holding our tty, excluding
# ourselves
while read -r ; do
  if [[ "${REPLY}" != "${$}" ]] ; then
    ttypids["${REPLY}"]=true
  fi
done <<< "${lsofout}"
unset -v lsofout
# this variable will remain declared throughout the shell session
# to remember how deeply nested the tty is
declare -a TTYLVL
# in most cases, there will be no pids holding our terminal besides our own
# we want to bail out early there instead of invoking ps
if [[ "${#ttypids[@]}" != 0 ]] ; then
  # now we compute a table mapping pids to their parents using ps
  # ps invocations and output vary significantly from platform to platform, so we're
  # trying to stick to a posix-compatible invocation
  # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ps.html
  # ps has no easy way to filter to "ancestors of pid", so we just have to list all
  # pids on the system
  declare -a pidtable
  while read -r pid ppid ; do
    pidtable["${pid}"]="${ppid}"
  done < <(ps -A -o pid= -o ppid=)

  # now we go up the process tree from our current pid, looking for pids that land
  # in the lsof output
  nextparent="${pidtable["${$}"]}"
  while [[ -n "${nextparent}" && "${nextparent}" != 0 ]] ; do
    # we have not yet reached the root of the process tree, does this ancestor
    # have our tty open?
    if [[ -n "${ttypids["${nextparent}"]}" ]] ; then
      TTYLVL+=("${nextparent}")
    fi
    nextparent="${pidtable["${nextparent}"]}"
  done
  unset -v nextparent
  unset -v pidtable
fi
unset -v ttypids

# posix-portable
alias mv='mv -i' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mv.html
alias mkdir='mkdir -p' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html

# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html
# -la is posix-portable
# -h is not posix-portable, but both bsd and gnu ls support it
alias ll='ls -lha'
# there is no posix-portable way to enable color
# there is also no posix-portable way to detect version, so we hack it
if [[ "$(uname)" == Linux ]] ; then
  alias ls='ls --quoting-style=literal --color=auto'
  if which dircolors >/dev/null ; then
    if [[ -f "${HOME}/.dir_colors" ]] ; then
      eval $(dircolors -b "${HOME}/.dir_colors")
    elif [[ -f '/etc/DIR_COLORS' ]] ; then
      eval $(dircolors -b /etc/DIR_COLORS)
    fi
  fi
else
  # you can export CLICOLOR instead of defining this alias
  alias ls='ls -G'
  # TODO: do not export in bashrc, delegate to bash_profile instead
  export LSCOLORS=ExGxFxFxCxDxDxBABAEAEA
fi

# i like using -i to prompt for overwrites
# however, you cannot use -f to skip the prompt, and this restriction is posix-mandated
# i stopped using this alias as a result
# alias cp='cp -i' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html

# mkdir for each argument, then cd into the last argument
mcd () { mkdir -p "$@" && eval cd "\"\$$#\"" ; }

alias dir='dir --color=auto'
alias grep='grep --color=auto'
alias dmesg='dmesg --color'
alias cower='cower --color=auto'

HISTSIZE=-1
HISTCONTROL=ignoreboth:erasedups

if [[ -f /usr/share/bash-completion/bash_completion ]] ; then
  source /usr/share/bash-completion/bash_completion
elif [[ -f /usr/local/share/bash-completion/bash_completion ]] ; then
  # alternative path, eg for homebrew on osx
  source /usr/local/share/bash-completion/bash_completion
fi

if [[ -f ~/.bashrc_private ]] ; then
  source ~/.bashrc_private
fi

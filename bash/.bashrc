# do nothing unless interactive
[[ $- != *i* ]] && return

shopt -s checkwinsize
shopt -s histappend
shopt -s globstar

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

  # is this shell inside sudo?
  # TODO: also check for $SSH_CLIENT
  if [[ -n "${SUDO_USER}" ]] ; then
    # sudo to root?
    if [[ "${EUID}" == 0 ]] ; then
      # print the user in red
      # $USER set by login
      printf '%b[%b%s%b]%s' "${neut}" '\[\e[91m\]' "${USER}" "${neut}" "${sep}"
    else
      # print the user in green
      printf '%b[%b%s%b]%s' "${neut}" '\[\e[92m\]' "${USER}" "${neut}" "${sep}"
    fi
  fi

  # print pwd in cyan
  printf '%b[%b%s%b]%s' "${neut}" '\[\e[96m\]' '\w' "${neut}" "${sep}"

  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == 'true' ]] ; then
    # find current checkout branch
    local checkout="$(git symbolic-ref HEAD --short 2>/dev/null)"
    # no branch? try tag
    [[ -z "${checkout}" ]] && checkout="$(git describe --tags --exact-match 2>/dev/null)"
    # no tag? try raw commit sha
    [[ -z "${checkout}" ]] && checkout="$(git rev-parse --short HEAD 2>/dev/null)"
    # no raw commit sha? abnormal error condition
    [[ -z "${checkout}" ]] && checkout='ERROR'

    # parse the null-separated output of git status
    local -i unstaged=0 uncommitted=0 untracked=0 unresolved=0
    local statuscode
    while read -rd '' ; do
      statuscode="${REPLY:0:2}"
      [[ "${statuscode}" == '??' ]] && let untracked++
      # remember, bash regexes in the =~ operator cannot be quoted
      [[ "${statuscode}" =~ \ [MDARC]|[\ MARC][MD] ]] && let unstaged++
      [[ "${statuscode}" =~ [MARC][MD\ ]|D[M\ ] ]] && let uncommitted++
      [[ "${statuscode}" =~ U|DD|AA ]] && let unresolved++
    done < <(git status -z)

    # hack to check the number of stashes
    local stash="$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null)"
    [[ -z "${stash}" ]] && stash=0

    # print the checkout itself in yellow
    printf '%b[%b%s' "${neut}" "\[\e[93m\]" "${checkout}"
    if (( unstaged + uncommitted + untracked + unresolved + stash )) ; then
      printf '%b|' "${neut}"
      (( unresolved )) && printf '%b=%s' '\[\e[95m\]' "${unresolved}" # purple
      (( untracked )) && printf '%b?%s' '\[\e[33m\]' "${untracked}" # brown
      (( unstaged )) && printf '%bx%s' '\[\e[31m\]' "${unstaged}" # red
      (( uncommitted )) && printf '%b^%s' '\[\e[32m\]' "${uncommitted}" # green
      (( stash )) && printf '%b+%s' '\[\e[36m\]' "${stash}" # cyan
    fi
    printf '%b]%s' "${neut}" "${sep}"
  fi

  if (( ret )) ; then
    # last command exited nonzero, print a bold red X as the final character
    printf '%b%s' '\[\e[1;31m\]' 'X'
  else
    # print the bold white $ or # (depending on uid)
    printf '%b%s' '\[\e[1;37m\]' '\$'
  fi
  printf '%b ' "${neut}"
}
PROMPT_COMMAND='PS1=$(set_ps1)'
PS2='> '
PS3='> '
PS4='+'

alias mv='mv -i'
alias rm='rm -I --one-file-system'
alias mkdir='mkdir -p'
alias ll='ls -lha'

# for some reason, 'cp -if' still prompts you, so i
# stopped using this alias
# alias cp='cp -i'

# mkdir for each argument, then cd into the last argument
mcd () { mkdir -p "$@" && eval cd "\"\$$#\"" ; }

if [[ -r '~/.dircolors' ]] ; then
  eval $(dircolors -b ~/.dircolors)
elif [[ -r '/etc/DIR_COLORS' ]] ; then
  eval $(dircolors -b /etc/DIR_COLORS)
fi

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias grep='grep --color=auto'
alias dmesg='dmesg --color'
alias cower='cower --color=auto'

HISTSIZE=100000
HISTCONTROL=ignoreboth

[[ -r /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion

# clear the return value of any nonzero tests
true

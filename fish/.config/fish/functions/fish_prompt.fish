function fish_prompt
  # commands run in prompt functions will not overwrite the external value of $status
  # however, they will still affect the value that the function itself can see
  # so we have to cache this before doing anything interesting
  set -l ret "$status"

  # is this shell inside sudo/ssh?
  if test \( -n "$SUDO_USER" \) -o \( -n "$SSH_CLIENT" \)
    # print user in green
    set -l usercol '\e[32m'
    # this variable comes from config.fish
    if test "$euid" -eq 0
      # red if root
      set usercol '\e[31m'
    end
    # this variable als comes from config.fish
    printf '%b[%b%s%b' '\e[m' "$usercol" "$user" '\e[m'

    # print hostname as well, if remote
    if test -n "$SSH_CLIENT"
      # fish does not set $HOSTNAME, and the hostname command is not posix-compliant
      # we use uname instead
      # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/uname.html
      printf '@%b%s%b' '$usercol' (uname -n) '\e[m'
    end
    printf '] '
  end

  # print pwd in cyan
  # dir shortening is disabled in config.fish
  printf '%b[%b%s%b] ' '\e[m' '\e[36m' (prompt_pwd) '\e[m'

  if test (git rev-parse --is-inside-work-tree ^/dev/null) = 'true'
    # find current branch
    set -l checkout (git symbolic-ref --short -q HEAD)
    # no branch? try tag
    if test -z "$checkout"
      set checkout (git describe --tags --exact-match HEAD ^/dev/null)
    end
    # no tag? try commit sha
    if test -z "$checkout"
      set checkout (git rev-parse --verify --short -q 'HEAD^{commit}')
    end
    # no commit sha? abnormal error condition
    if test -z "$checkout"
      set checkout ERROR
    end

    # parse the null-separated output of git status
    set -l untracked
    set -l unstaged
    set -l uncommitted
    set -l unresolved
    set -l statuscode ''
    set -l skipnext ''
    while read -zl stat
      if test -n "$skipnext"
        set skipnext ''
        continue
      end
      set statuscode (string sub -s 1 -l 2 "$stat")
      if test "$statuscode" = '??'
        set untracked $untracked "$statuscode"
      end
      if string match -qr ' [MDARC]|[ MARC][MD]' "$statuscode"
        set unstaged $unstaged "$statuscode"
      end
      if string match -qr '[MARC][MD ]|D[M ]' "$statuscode"
        set uncommitted $uncommitted "$statuscode"
      end
      if string match -qr 'U|DD|AA' "$statuscode"
        set unresolved $unresolved "$statuscode"
      end
      # if the file was renamed, then the old name will be the next line
      # we skip over that line to avoid inadvertently parsing it
      if string match -qr 'R' "$statuscode"
        set skipnext true
      end
    end < (git status -z | psub)

    # hack to check number of stashes
    # TODO: is git stash list more appropriate? set -l (git stash list)
    set -l stash (git rev-list --walk-reflogs refs/stash -- ^/dev/null)

    # print checkout in bright yellow
    printf '%b[%b%s' '\e[m' '\e[93m' "$checkout"
    # if there are any changes, print them after a pipe
    if test (count $untracked $unstaged $uncommitted $unresolved $stash) -gt 0
      printf '%b|' '\e[m'
      if test (count $unresolved) -gt 0
        printf '%b=%u' '\e[35m' (count $unresolved) # purple
      end
      if test (count $untracked) -gt 0
        printf '%b?%u' '\e[33m' (count $untracked) # brown
      end
      if test (count $unstaged) -gt 0
        printf '%bx%u' '\e[31m' (count $unstaged) # red
      end
      if test (count $uncommitted) -gt 0
        printf '%b^%u' '\e[32m' (count $uncommitted) # green
      end
      if test (count $stash) -gt 0
        printf '%b+%u' '\e[34m' (count $stash) # blue
      end
    end
    printf '%b] ' '\e[m'
  end

  # set color of prompt character
  if test "$ret" -ne 0
    # last command exited nonzero, use bold red
    printf '%b' '\e[1;91m'
  else if test (count $ttylvl) -gt 0
    # an ancestor PID has our tty open, use bold cyan
    printf '%b' '\e[1;96m'
  else
    # use bold white
    printf '%b' '\e[1;97m'
  end

  # print prompt character itself
  if jobs -p >/dev/null ^&1
    # there are sleeping jobs
    printf '&'
  else if test "$euid" -eq 0
    # we are root
    printf '#'
  else
    # nothing out of the ordinary
    printf '$'
  end
  printf '%b ' '\e[m'
end

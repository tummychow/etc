if status is-interactive
  # fish does not set $EUID like bash does
  # it does set $USER, but that variable can be mutated so it's not reliable
  # instead we use posix-compliant invocations of id
  # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/id.html
  set -g euid (id -u)
  set -g user (id -nu)

  set -g fish_prompt_pwd_dir_length 0
  set -g fish_greeting ''

  # we want to draw the prompt character in cyan if we have an interactive ancestor
  # process, so that we remember not to close this entire terminal window
  # you could hack this with $SHLVL or $BASH_SUBSHELL, but a better way is to check
  # who's using the same tty device as you
  # TODO: does this behave well if inside a terminal multiplexer or ssh?
  set -g ttylvl
  begin
    set -l ttypids
    # first we have to use lsof to find programs holding an fd on our tty, we use the
    # tty command to get the tty's path
    # TODO: can we also use fuser -f? (http://pubs.opengroup.org/onlinepubs/9699919799/utilities/fuser.html)
    # TODO: can we use lsof -p ^ to exclude this shell's pid and lsof's own pid?
    # the tty command uses the ttyname function to return the path to the tty of
    # its stdin fd (you can also find the tty from procfs but that's linux-only)
    # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/tty.html
    # then we lsof to find processes holding that tty, excluding lsof itself (-c ^lsof)
    # and listing only their pids (-t)
    # now we build up an array whose indices are the pids holding our tty, excluding
    # ourselves
    for pid in (lsof -c '^lsof' -t -- (tty))
      if test "$pid" -ne %self
        set ttypids["$pid"] true
      end
    end

    # in most cases, there will be no pids holding our terminal besides our own
    # we want to bail out early there instead of invoking ps
    if test (count $ttypids) -gt 0
      # now we compute a table mapping pids to their parents using ps
      # ps invocations and output vary significantly from platform to platform, so we're
      # trying to stick to a posix-compatible invocation
      # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ps.html
      # ps has no easy way to filter to "ancestors of pid", so we just have to list all
      # pids on the system
      set -l pidtable
      while read pid ppid
        # ps adds spaces to align the columns, which we trim off
        set pidtable[(string trim "$pid")] (string trim "$ppid")
      end < (ps -A -o pid= -o ppid= | psub)

      # now we go up the process tree from our current pid, looking for pids that land
      # in the lsof output
      set -l nextparent %self
      while test \( -n "$nextparent" \) -a \( "$nextparent" -ne 0 \)
        # we have not yet reached the root of the process tree, does this ancestor
        # have our tty open?
        if test -n "$ttypids[$nextparent]"
          set ttylvl $ttylvl "$nextparent"
        end
        set nextparent "$pidtable[$nextparent]"
      end
    end
  end

  # posix-portable
  alias mv='mv -i' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mv.html
  alias mkdir='mkdir -p' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/mkdir.html

  # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html
  # -la is posix-portable
  # -h is not posix-portable, but both bsd and gnu ls support it
  alias ll='ls -lha'
  # there is no posix-portable way to enable color
  # there is also no posix-portable way to detect version, so we hack it
  if test (uname) = 'Linux'
    alias ls='ls --quoting-style=literal --color=auto'
    # TODO: dircolors in fish?
  else
    # you can export CLICOLOR instead of defining this alias
    alias ls='ls -G'
    # TODO: do not export in bashrc, delegate to bash_profile instead
    set -x LSCOLORS ExGxFxFxCxDxDxBABAEAEA
  end

  # i like using -i to prompt for overwrites
  # however, you cannot use -f to skip the prompt, and this restriction is posix-mandated
  # i stopped using this alias as a result
  # alias cp='cp -i' # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cp.html
end

function fish_right_prompt
  set -l ret "$status"
  if test "$ret" -ne 0
    printf '%b' '\e[1;91m'
  end
  printf '%s%b (' "$ret" '\e[m'

  # this uses print, which is a gnu bc feature (not posix-compliant)
  # however, posix bc does not provide any way to print a number without a trailing newline
  echo "
  scale = 0
  ms = $CMD_DURATION
  if (ms > 1000) {
    s = ms / 1000
    ms %= 1000
    if (s > 60) {
      min = s / 60
      s %= 60
      if (min > 60) {
        hr = min / 60
        min %= 60
        print hr, \"h\"
      }
      print min, \"m\"
    }
    print s, \"s\"
  }
  print ms, \"ms)\"
  " | bc
end

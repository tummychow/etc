# dotfiles

managed with stow

passing `--no-folding` to stow is recommended. this avoids symlinking directories which end up containing other files. example: stowing `ssh` might lead to `~/.ssh` being a symlink to `etc/ssh/.ssh`. then if you generate an ssh key, it'll be in `~/.ssh/id_rsa`, which is actually `etc/ssh/.ssh/id_rsa`. then you might accidentally add the key to git, and then you would be very sad. it's tough to remember every possible thing that might need to be gitignored. using `--no-folding` ensures that only files get symlinked, so you'll never accidentally symlink a directory containing things you don't want in git.

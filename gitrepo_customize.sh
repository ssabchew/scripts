#!/usr/bin/env bash

set -e

# Run this script to set up your git development environment in any git repository.

project=$(git config --list|grep remote.origin.url|cut -d":" -f2)
defaultbranch="master"
gitconfig=".git/config"

cfg_marker_start="# # # CRN START # # #"
cfg_marker_end="# # # CRN END # # #"

# Set up user name and email address
setup_git_user() {
  read -ep "Please enter your full name, e.g. 'John E. Doe': " name
  echo "Name: '$name'"
  git config user.name "$name"
  read -ep "Please enter your email address, e.g. 'john@doe.com': " email
  echo "Email address: '$email'"
  git config user.email "$email"
}

print_info() {
    cat << EOF

    Setting up some useful git aliases for you. This can be used by typing git and
    the alias name. You can inspect all aliases in this script, or by reading
    .git/config in your clone.

        prepush          - view a short form of the commits about to be pushed,
                             relative to origin/master
        st = status
        ci = commit
        br = branch
        co = checkout
        df = diff
        dc = diff --cached
        lg = log -p
        lol = log --graph --decorate --pretty=oneline --abbrev-commit
        lola = log --graph --decorate --pretty=oneline --abbrev-commit --all
        ls = ls-files

        # Show files ignored by git:
        ign = ls-files -o -i --exclude-standard

EOF
}

clear_markers() {
    f_path="$1"

    if [ -f "$f_path" ]; then
        sed -i '/'"$cfg_marker_start"'/,/'"$cfg_marker_end"'/d' $f_path
    fi
}

loop_usersetup() {
# Infinite loop until confirmation information is correct
for (( ; ; )); do
  # Display the final user information.
  gitName=$(git config user.name)
  gitEmail=$(git config user.email)
  echo "Your commits will have the following author information:

  $gitName <$gitEmail>
"
  read -ep "Is the name and email address above correct? [Y/n] " correct
  if [ "$correct" == "n" ] || [ "$correct" == "N" ]; then
    setup_git_user
  else
    break
  fi
done

}

# Clear previously auto-generated content.
clear_markers $gitconfig
cat >> $gitconfig << EOF
$cfg_marker_start
[color]
       ui = auto
[color "branch"]
       current = yellow reverse
       local = yellow
       remote = green
[color "diff"]
       meta = yellow bold
       frag = magenta bold
       old = red bold
       new = green bold
[color "status"]
       added = yellow
       changed = green
       untracked = cyan
[alias]
       st = status
       ci = commit
       br = branch
       co = checkout
       df = diff
       dc = diff --cached
       lg = log -p
       lol = log --graph --decorate --pretty=oneline --abbrev-commit
       lola = log --graph --decorate --pretty=oneline --abbrev-commit --all
       ls = ls-files

       # Show files ignored by git:
       ign = ls-files -o -i --exclude-standard
$cfg_marker_end
EOF

setup_git_user

print_info

git config alias.prepush 'log --graph --stat origin/master'

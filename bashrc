#!/bin/bash
# My personal bashrc file.
# Copyright (C) 2013-2015 Scott Weldon

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Hard-coded Vars #
data="/mnt/data"
script="$data/scripts"

# Env Vars #
PATH="`find "$script" -name '.*' -prune -o -type d -printf '%p:'`$PATH"
PATH="$data/bin:$PATH"

# Helper Functions #
function customAlias() {
  cmd="$1"
  needsRoot=""

  case "$cmd" in
    "pdf")
      possibles=("evince" "atril")
      ;;
    "txt")
      possibles=("gedit" "pluma")
      ;;
    "doc")
      possibles=("libreoffice" "openoffice")
      ;;
    "web")
      possibles=("surf" "links" "lynx")
      ;;
    "fm")
      possibles=("nautilus" "caja" "dolphin")
      ;;
    "pkg")
      possibles=("apt-get" "yum" "pacman")
      needsRoot="sudo "
      ;;
    *)
      return 1
      ;;
  esac

  for exe in ${possibles[*]}
  do
    type -t $exe > /dev/null
    if [ $? -eq 0 ]
    then
      alias $cmd="$needsRoot$exe"
      break
    fi
  done

  unset cmd exe possibles
}

for cmd in pdf txt doc web fm pkg
do
  customAlias "$cmd"
done

unset customAlias

# Useful functions #
function chdir() {
  validArgs=("args" "dirlist")
  source loadconf "$HOME/.scott_script/bashrc" "chdir.cfg" validArgs[@] > /dev/null

  i=0
  len=${#args[*]}
  while [ $i -lt $len ]
  do
    if [ ${args[$i]} == "$1" ]
    then
      newdir=${dirlist[$i]}
      break
    fi
    i=`expr $i + 1`
  done

  if [ "$newdir" == "" ]
  then
    newdir="$1"
  fi

  cd $newdir

  unset validArgs newdir i len args dirs
}

function say {
  echo "$1" | festival --tts;
}

unset cfgdir

function stop {
  sig="STOP"
  if [ "$1" == "soft" ]
  then
    sig="TSTP"
    shift
  fi

  [ -z "$1" ] && echo "Error: missing PID to suspend." && return 1

  kill -$sig $1
}

function resume {
  [ -z "$1" ] && echo "Error: missing PID to resume." && return 1

  kill -CONT $1
}

# Custom aliases
alias dif="diff --suppress-common-lines --ignore-all-space --side-by-side"
alias ll='ls --all -l --file-type'
alias la='ls --almost-all'
alias l='ls -C --file-type'
#alias emacs="/usr/bin/emacs --no-window-system"
alias semacsd="torify emacs --daemon"
alias e="emacsclient -t"
alias ef="emacsclient -c"
alias psurf="surf -c /dev/null"
alias speedtest="wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip --report-speed=bits"
alias sspeedtest="torify wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip --report-speed=bits"
alias git-repo-authors="git ls-tree -r HEAD --name-only | xargs -I{} git blame --line-porcelain {} | sed -n 's/^author //p' | sort | uniq -c | sort -rn"
alias private-bash="HISTFILE='' torify bash -i"

# Push stashes!
function git-push-stash() {
  [ -z "$1" ] && echo 'Error: please specify a stash number to push.' && return 1
  remote=origin
  [ -z "$2" ] || remote="$2"

  echo "Pushing stash $1 to $remote."

  git push $remote stash@{$1}:refs/stashes/$(git rev-parse --short stash@{$1})
}

function git-fetch-stashes() {
  remote=origin
  [ -z "$1" ] || remote="$1"

  git fetch "$remote" refs/stashes/*:refs/stashes/*
}

function git-import-stash() {
  SHA=''
  if [ -z "$1" ]
  then
    echo 'Error: please specify a SHA to import as a stash.'
    return 1
  else
    SHA="$1"
  fi

  git stash store --message "$(git show --no-patch --format=format:%s $SHA)" $SHA
}

function git-push-all-stashes() {
  remote=origin
  [ -z "$1" ] || remote="$1"

  for i in $(seq 0 $(expr $(git rev-list --walk-reflogs --count stash) - 1))
  do
    git-push-stash $i "$remote"
  done
}

function git-import-all-stashes() {
  if [ ! -d .git/refs/stashes ]
  then
    echo 'Error: no stashes fetched or not in a Git repo.'
  fi

  for stash in $(ls .git/refs/stashes)
  do
    git-import-stash "$stash"
  done
}

# Because I'm forgetful.
alias git-stash-push='git-push-stash'
alias git-stash-import='git-import-stash'

function mktmpfs() {
  [ -z "$1" ] && echo "Error: please provide a size for ramdisk." && return 1

  [ -z "$2" ] && mount="/mnt/ramdisk" || mount="$2"

  sudo mount -t tmpfs -o size=$1 tmpfs $mount
}

# Remove unused Docker images, see https://stackoverflow.com/a/32723127/2747593
alias drmi="docker rmi \$(docker images --filter \"dangling=true\" -q --no-trunc)"

# Prompt customisation
# Default Ubuntu: \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w\$
green="\[\033[0;32m\]"
blue="\[\033[0;34m\]"
red="\[\033[0;31m\]"
end="\[\033[0m\]"
returncode="\$?"
currdir="[\w]"
time="[\t]"
user="[\u@\h]"
stats="[\!:$returncode]"
PS1="\n$green$currdir$stats\n$time$user\$$end "
[ "$TERM" == "dumb" ] && PS1='$ '

# GitHub script
type -t "hub" > /dev/null
if [ $? -eq 0 ]
then
  alias git=hub
fi

current_gopath=$GOPATH
if [ "$current_gopath" != "" ]
then
  current_gopath="$current_gopath:"
fi

export GOPATH="$current_gopath$HOME/.go"

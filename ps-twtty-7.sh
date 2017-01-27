#!/bin/bash

# ps-twtty-7.sh - Nice bash prompt and history archiver
#   by Doncho N. Gunchev <dgunchev@everbread.com>, 2009-09-30 07:00 EEST

# BASED ON
# termwide prompt with tty number  and  .bashrc_history.sh
# by Giles, 1998-11-02                  by Yaroslav Halchenko, 2005-03-10
# .../Bash-Prompt-HOWTO/x869.html       http://www.onerussian.com

# DESCRIPTION
# An attempt to seese industrial... ops, I ment an attempt to make my
# bash prompt nicer and save all my bash history ordered by date with
# exit codes for later review...

# LICENSE:
#   Released under GNU Generic Public License. You should've received it with
#   your GNU/Linux system. If not, write to the Free Software Foundation, Inc.,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# KNOWN BUGS:
# - logs the previous command again on control-break, control-quit
# - logs the last command in history on control+d (EOF) or enter
#   (could be fixed if we remember the index of the command used last time,
#   which is currently removed by 'Cmd=${Cmd:7}')
# - does not log history from within mc (midnight commander)
#   this can be viewed as a feature too :-) The problem is that mc
#   changes PROMPT_COMMAND, hurting the prompt quite bad and
#   killing the log.

if [ "$PS1" ] ; then # interactive shell detection

function prompt_command_exit() {
	trap - EXIT
	# mark the logout
	local HistFile="$HOME/bash_history/$(date '+%Y-%m/%Y-%m-%d')"
	mkdir -p "${HistFile%/*}"
	local Cmd=$(history 1)
	#Cmd=$(echo "$Cmd" | sed 's/^ *[[:digit:]][[:digit:]]* *//')
	Cmd=${Cmd:7}
	echo -e "# Logout,$USER@${HOSTNAME}:$PWD,`tty`,${SSH_CLIENT:-`who am i | cut -d ' ' -f 1`@localhost},${my_LoginTime},$(date --rfc-3339=ns)\n$Cmd" >> "$HistFile"
}

function prompt_command() {
	# Save the error code
	local E=$?

	# Date, my format
	my_D=$(date '+%Y-%m-%d %H:%M:%S')

	local HistFile="$HOME/bash_history/$(date '+%Y-%m/%Y-%m-%d')"
	mkdir -p "${HistFile%/*}"

	# Manage the history
	if [ -z "$my_LoginTime" ]; then
		my_LoginTime=$(date --rfc-3339=ns)
		echo -e "# Login,$USER@${HOSTNAME}:$PWD,`tty`,${SSH_CLIENT:-`who am i | cut -d ' ' -f 1`@localhost},${my_LoginTime},${my_LoginTime}\n" >> "$HistFile"
	else
		local Cmd=$(history 1)
		#Cmd=$(echo "$Cmd" | sed 's/^ *[[:digit:]][[:digit:]]* *//')
		Cmd=${Cmd:7}
		echo -e "# CMD,\$?=$E,$USER@${HOSTNAME}:$PWD,`tty`,${SSH_CLIENT:-`who am i | cut -d ' ' -f 1`@localhost},${my_LoginTime},$(date --rfc-3339=ns)\n$Cmd" >> "$HistFile"
	fi


	# Calculate the width of the prompt:
	my_TTY=$(tty)
	my_TTY="${my_TTY:5}"	# cut the '/dev' part -> tty/1, pts/2...
	# Add all the accessories below ...
	local prompt="--($my_D, Err $E, $my_TTY)---($PWD)--"

	local fillsize=0
	let fillsize=${COLUMNS}-${#prompt}
	my_FILL=""
	if [ $fillsize -gt 0 ]; then
		my_FILL="─"
		while [ $fillsize -gt ${#my_FILL} ]; do
			my_FILL="${my_FILL}${my_FILL}${my_FILL}${my_FILL}"
		done
		my_FILL=${my_FILL::$fillsize}
		let fillsize=0
	fi

	if [ $fillsize -lt 0 ]; then
		my_PWD="...${PWD:3-$fillsize}"
	else
		my_PWD="${PWD}"
	fi
}

function twtty {
	local GRAY="\[\033[1;30m\]"
	local LIGHT_GRAY="\[\033[0;37m\]"
	local WHITE="\[\033[1;37m\]"
	local NO_COLOUR="\[\033[0m\]"

	local LIGHT_BLUE="\[\033[1;34m\]"
	local YELLOW="\[\033[1;33m\]"
	if [ $(id -u) == 0 ]; then
		local LIGHT_BLUE="\[\033[1;33m\]" # Yellow
		local YELLOW="\[\033[1;31m\]"     # Red
	fi

	case $TERM in
		xterm*)
			TITLEBAR='\[\033]0;\u@\h:\w\007\]'
			;;
		*)
			TITLEBAR=""
			;;
	esac

	PS1="$TITLEBAR\
${YELLOW}┌${LIGHT_BLUE}─(\
${YELLOW}\${my_D}${LIGHT_BLUE}, ${YELLOW}Err ${WHITE}\$?${LIGHT_BLUE}, ${WHITE}\${my_TTY}\
${LIGHT_BLUE})─${YELLOW}─\${my_FILL}${LIGHT_BLUE}─(\
${YELLOW}\${my_PWD}\
${LIGHT_BLUE})─${YELLOW}─\
${NO_COLOUR}\n\
${YELLOW}└${LIGHT_BLUE}─(\
${YELLOW}\${USER}${LIGHT_BLUE}@${YELLOW}\${HOSTNAME%%.*}\
${LIGHT_BLUE})${WHITE}\$${NO_COLOUR} "

	PS2="${LIGHT_BLUE}─${YELLOW}─${YELLOW}─${NO_COLOUR} \[\033[K\]"
	PROMPT_COMMAND=prompt_command
	trap prompt_command_exit EXIT
	shopt -s cmdhist histappend
	# unset HISTCONTROL
	# makes MC add hundreds of commands into bash's history otherwize
	export HISTIGNORE=' cd "`printf "%b": PROMPT_COMMAND='
}

twtty
unset twtty

fi

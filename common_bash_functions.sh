#!/bin/bash
## About:       Non executable. Collecton of bash functions.
## OS   :       RHEL/CentOS / Fedora
## Version:  2015-11-17

#=== User Mgmt functions

user_add(){
## Adds system user
## Usage user_add <username> [<home_dir>]

__custom_exit(){
    echo $*
    exit 233
}

arg_mgmt $# 0 2

if getent passwd "$1" $>/dev/null ;then
    if [ $# -eq 3 ] ;then
        useradd  -r -m -d "$2" "$1"
    else
        useradd -r "$1"
    fi

else
    __custom_exit User already exist
fi
}

function mkpw() {
## Function that generates passwords
## Usage:
## $0 <passwd_lengh>
## by default password lenggt is 12

arg_mgmt $# 0 1 &</dev/null
is_number $1

__mkpwd(){
    tr -dc "[:alpha:]" < /dev/urandom | head -c $pw_len
}
#if [ -z $1 ] || ([ -z $# ] || [  $1 -lt 12 ]) ;then
if  [ -z $1 ]; then
    pw_len=12
    _mkpwd
else
    pw_len=$1
    __mkpwd
fi

}

#=== Network functions
function valid_ip(){
## Check if the passed variable is a valid v4 IP
## Returns 0 True or 1 False

    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function get_primary_nic(){
## Returns the name of primary interface

    if which ip &>/dev/null; then
        echo $(ip route | awk '/default/ { print $5 }')
    fi
}
function get_primary_nic_ip(){
## Returns the primary network interface
## that default gateway is configured
    if which ip &>/dev/null; then
        ifconfig $(ip route | awk '/default/ { print $5 }') | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'
    fi
}

function get_gw(){
## Returns the IP of default gateway

    which ip &>/dev/null && _ip=$(ip r|grep default| cut -d" " -f3)
    if valid_ip $_ip ;then
        echo $_ip
    else
        err cannot get the gw
    fi
}

function check_local_tcp_port(){
## Try to connect to local TCP or UDP port
## Exit with 0 if there is a connectoin
## Usage: check_local_tcp_port <port> <type>
## where type is either tcp or udp, tcp is used if not specified

_port=$1
_type=$2
_type="${_type:=tcp}"

(echo 1 > /dev/${_type}/127.0.0.1/${_port} ) &>/dev/null

}

function pipe_mail(){

## function that sends emails
## Shoulc be configured
## Usage: echo test | mail_f
## ( body of bash script ) | mail_f

EMAIL=
SMTP=
SUBJECT=
MAILTOS=
#REPLAYTO=

if [ -z "$EMAIL" ] ;then
    err "Please configure or export variables."
fi

(

    mail -S smtp="$SMTP" -S from="$EMAIL" -s "$SUBJECT" "$MAILTOS"
)

}

#=== FileMgmt functions

check_file_exist(){
## Check if file exists

if [ ! -f $1 ] ;then
    echo "$1 not found"
    exit 1
fi
}

check_dir_exist(){
## Check if directory exists

if [ ! -d $1 ] ;then
    echo "$1 not found"
    exit 1
fi
}


#=== Various Functions

function is_number(){
## Test if variable is a number
## If environment variable debug is set to 1,
## it will print result to stdout

if test "$debug";then
    if (( printf "%g" "$debug" &> /dev/null ) && ( [ "$debug" -eq 1 ] )) ;then
        printf "%g" "$1" &> /dev/null && echo $1 is number || echo Not a number
    fi
else
    printf "%g" "$1" &> /dev/null
fi

}

function silent() {
## Run next commad silently. Usefull for cronjobs.
## usage silent yum -y install httpd

    "$@" &> /dev/null
}

function disp() {
## function disp
## Prints scriptname and all arguments
## Usage: disp Script [$0] starting

    echo "$(basename "$0"): $*" >&2
}

function notify_syslog(){
## function notify_syslog
## Print message, script fullpath  and pid to syslog
## If 1st argument is "debug=1" then print the message
## to stdout either

if [ "$1" == "debug=1" ] ;then
    shift
    echo "[$0][$$] : $*"
fi
    /usr/bin/logger "[$0][$$] : $*"

}

function notify_desktop_simple(){
##
##
## Usage: notify_desktop message

notify-send -t 0 -i ~/bin/ibus-setup "$*"

}

function die(){
## function die
## Print all arguments and exits with code 1
    echo $*
    exit 1
}

function err() {
## function err
## Prints message, script fullpath , error code and exits with code from previous command

        ret="$?"
        trap - EXIT
        set +e
        if [ $# -gt 0 ]; then
                echo "Error: $0: $@"
        else
                echo "Error exit in [$0], error code=$ret"
        fi
        exit $ret
}

function arg_mgmt(){
## Function arg_mgmt
## Arguments Management
## Checks if number of arguments match criteria 
## for minimum number of arguments and maximum number
## Should be invoked like this:
## arg_mgmt argnum argmin argmax
## Hint: you should pass $# ( argnum ) from your script or function

argnum="$1"
argmin="$2"
argmax="$3"

is_number $argnum || err "argnum <first argument>  is not a number"
is_number $argmin || err "argmin <second argument> is not a number"
is_number $argmax || err "argmax <third argument>  is not a number"

# Debug:
##echo argnum: $argnum argmin: $argmin argmax: $argmax

# case than we want to run without arguments or with 1,2 or more arguments...
# Shall look for better solution(s)
if [ -z $# ] || ( [ $# -lt 3 ] || [ $# -gt 3 ] );then
    echo "Usage: arg_mgmt argnum argmin argmax"
    exit 1
fi
if [ $argnum == 0 ] ;then
    # will check only max
    if [ ! $argnum == $argmin -o $argnum -gt $argmax ] ;then
        err "ussage: $(basename \"$0\") <params>, where number of params shuold be from $argmin to $argmax"
    fi
else
    if [ "$argnum" -lt $argmin -o $argnum -gt $argmax ] ;then
        err "ussage: $(basename \"$0\") <params>, where number of params shuold be from $argmin to $argmax"
    fi
fi

}

function time_date(){
## function time_date
## Returns different time formats
## ts as seconds in unix time
## now as YYYY-MM-DD
## nowts as  YYYY-MM-DD-HH-MM-SS
## y as YYYY
## m as MM
## d as DD

ts=$(date +"%s")
now=$(date '+%Y-%m-%d')
nowts=$(date "+%Y-%m-%d-%H-%M-%S")
y=$(date '+%Y')
m=$(date '+%m')
d=$(date '+%d')

}

function showcolors (){
    local t='gYw';
    local fgs;
    local bg;
    echo -e "\n                 40m     41m     42m     43m     44m     45m     46m     47m";
    for fgs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' '  36m' '1;36m' '  37m' '1;37m';
    do
        fg=${fgs// /};
        echo -en " $fgs \e[$fg  $t  ";
        for bg in 40m 41m 42m 43m 44m 45m 46m 47m;
        do
            echo -en "$EINS \e[$fg\e[$bg  $t  \e[0m";
        done;
        echo;
    done;
    echo
}

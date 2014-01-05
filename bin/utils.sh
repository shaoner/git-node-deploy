#! /bin/sh

# Colors
C_RESET='\e[0m'
C_BLACK='\e[0;30m'
C_BBLACK='\e[1;30m'
C_RED='\e[0;31m'
C_BRED='\e[1;31m'
C_GREEN='\e[0;32m'
C_BGREEN='\e[1;32m'
C_YELLOW='\e[0;33m'
C_BYELLOW='\e[1;33m'
C_BLUE='\e[0;34m'
C_BBLUE='\e[1;34m'
C_PURPLE='\e[0;35m'
C_BPURPLE='\e[1;35m'
C_CYAN='\e[0;36m'
C_BCYAN='\e[1;36m'
C_WHITE='\e[0;37m'
C_BWHITE='\e[1;37m'

display_info()
{
	echo -e "${C_BWHITE}[${C_BLUE}info${C_BWHITE}]${C_RESET} $*" >&2
}

display_warn()
{
	echo -e "${C_BWHITE}[${C_YELLOW}warn${C_BWHITE}]${C_RESET} $*" >&2
}

display_error()
{
	echo -e "${C_BWHITE}[${C_RED}error${C_BWHITE}]${C_RESET} $*" >&2
	return 2
}

waiting_msg()
{
	local TIMEWAIT=$2
	local i=0
	echo -en "${C_BWHITE}[${C_BLUE}info${C_BWHITE}]${C_RESET} $1 "
	while [ $i -lt "$TIMEWAIT" ]
	do
		sleep 1
		echo -n "."
		i=$(($i + 1))
	done
	echo
}

dir_exists()
{
	test -d "$1" || (display_error "$1: No such file or directory" ; return 1)
	return 0
}

file_exists()
{
	test -f "$1" || (display_error "$1: No such file or directory" ; return 1)
	return 0
}

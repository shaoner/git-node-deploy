#! /bin/sh

CUR_DIR=$(dirname $0)
source "$CUR_DIR/utils.sh"

if [ $# -ne 3 ]
then
	display_error "$0: Arguments missing"
	exit 1
fi

ACTION=$1
INSTANCE=$2
SERVER_NAME=$3

start_app()
{
	display_info "Starting $INSTANCE - $SERVER_NAME"
	start $INSTANCE SERVER="$SERVER_NAME" || return 2
	waiting_msg "Checking if $INSTANCE-$SERVER_NAME is alive" 6
	status $INSTANCE SERVER="$SERVER_NAME" || display_error "$INSTANCE-$SERVER_NAME died" || return 3
	return 0
}

stop_app()
{
	display_info "Stopping $INSTANCE - $SERVER_NAME"
	stop $INSTANCE SERVER="$SERVER_NAME"
	return 0
}

restart_app()
{
	stop_app
	start_app
	return 0
}

RET=0
case $ACTION in
	start)
		start_app
		RET=$?
		break
		;;
	stop)
		stop_app
		RET=$?
		break
		;;
	restart)
		restart_app
		RET=$?
		break
		;;
	*)
		display_error "No such action $ACTION"
		RET=1
		;;
esac

exit $RET

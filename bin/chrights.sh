#! /bin/sh

CUR_DIR=$(dirname $0)
source "$CUR_DIR/utils.sh"

if [ $# -ne 3 ]
then
	display_error "$0: Arguments missing"
	exit 1
fi

ACTION=$1
RIGHT=$2
FILEDIR=$3

if [ "${FILEDIR##/srv/http/}" = "$FILEDIR" ]
then
	display_error "Path $FILEDIR forbidden"
	exit 2
fi

change_own_rec()
{
	display_info "Recursively change owner to $RIGHT on $FILEDIR"
	chown -R "$RIGHT" "$FILEDIR" || return 1
	return 0
}

change_own()
{
	display_info "Change owner to $RIGHT on $FILEDIR"
	chown "$RIGHT" "$FILEDIR" || return 1
	return 0
}

change_mod_rec_dirs()
{
	display_info "Recursively change mod to $RIGHT on $FILEDIR subdirectories"
	find "$FILEDIR" -type d -exec chmod "$RIGHT" {} \; || return 1
	return 0
}

change_mod_rec_files()
{
	display_info "Recursively change mod to $RIGHT on $FILEDIR subfiles"
	find "$FILEDIR" \! -type d -exec chmod "$RIGHT" {} \; || return 1
	return 0
}

change_mod_rec()
{
	display_info "Recursively change mod to $RIGHT on $FILEDIR"
	chmod -R "$RIGHT" "$FILEDIR" || return 1
	return 0
}

change_mod()
{
	display_info "Change mod to $RIGHT on $FILEDIR"
	chmod "$RIGHT" "$FILEDIR" || return 1
	return 0
}

RET=0
case $ACTION in
	own_rec)
		change_own_rec
		RET=$?
		break
		;;
	own)
		change_own
		RET=$?
		break
		;;
	mod_rec_dirs)
		change_mod_rec_dirs
		RET=$?
		break
		;;
	mod_rec_files)
		change_mod_rec_files
		RET=$?
		break
		;;
	mod_rec)
		change_mod_rec
		RET=$?
		break
		;;
	mod)
		change_mod
		RET=$?
		break
		;;
	*)
		display_error "No such action $ACTION"
		RET=1
		;;
esac

exit $RET

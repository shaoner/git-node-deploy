#! /bin/sh

CUR_DIR=$(dirname $0)
source "$CUR_DIR/utils.sh"

if [ $# -ne 2 ]
then
	display_error "$0: Arguments missing"
	exit 1
fi

BRANCH=$1
NODE_APP=$2
NODE_APP_ROOT="/srv/http/$NODE_APP/app"
UPINSTANCE=${NODE_APP}_node
LOG=/tmp/git-node-deploy.$NODE_APP.$(date +'%Y%m%d%H%M%S').log

update_app()
{
	local SERVER_NAME=$1
	local APP_DIR="$NODE_APP_ROOT/$SERVER_NAME"

	# Get new changes from the branch
	dir_exists "$APP_DIR" || return 1
	export GIT_WORK_TREE=$APP_DIR
	cd "$APP_DIR"
	display_info "Update app"
	unset GIT_DIR
	git fetch origin 2>&1 >> $LOG
	git reset --hard origin/$BRANCH 2>&1 >> $LOG

	# Update packages
	display_info "Update bower packages"
	bower update --silent 2>&1 >> $LOG || display_error "Issue installing bower packages" || return 2
	display_info "Update node packages"
	npm install --silent 2>&1 >> $LOG || display_error "Issue installing node packages" || return 2
	npm update --silent 2>&1 >> $LOG || display_error "Issue updating node packages" || return 2
	# Rights in app dir
	display_info "Restore rights in $APP_DIR"
	chown -R node:node $APP_DIR
	# Generates new static files
	display_info "Build static files"
	sudo -u node NODE_CONFIG="/etc/node/$NODE_APP/$SERVER_NAME.json" grunt build-prod 2>&1 >> $LOG || display_error "Issue building static files" || return 4

	# OK
	display_info "Successfully updated $NODE_APP - $SERVER_NAME"
	return 0
}

restart_app()
{
	local SERVER_NAME=$1
	display_info "Stopping $NODE_APP - $SERVER_NAME"
	stop $UPINSTANCE SERVER="$SERVER_NAME"
	update_app "$SERVER_NAME" || return 1
	display_info "Starting $NODE_APP - $SERVER_NAME"
	start $UPINSTANCE SERVER="$SERVER_NAME" || return 2
	waiting_msg "Checking if $NODE_APP-$SERVER_NAME is alive" 6
	status $UPINSTANCE SERVER="$SERVER_NAME" || display_error "$NODE_APP-$SERVER_NAME died" || return 3
	return 0
}

deploy_prod()
{
	# stop staging
	stop $UPINSTANCE SERVER="staging" || display_warn "$NODE_APP - staging server was not running"
	# 1. Restart and update main
	restart_app "main" || return 1
	# 2. Restart and update spare
	restart_app "spare" || return 2
	display_info "$NODE_APP - Production server is ready"
	return 0
}

deploy_staging()
{
	restart_app "staging" || return $?
	display_info "$NODE_APP - Staging server is ready"
	return 0
}

case $BRANCH in
	master)
		deploy_prod || exit $?
		;;
	staging)
		deploy_staging || exit $?
		;;
esac

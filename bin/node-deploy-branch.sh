#! /bin/sh

CUR_DIR=$(dirname $0)
source "$CUR_DIR/utils.sh"

if [ $# -ne 2 ]
then
	display_error "$0: Arguments missing"
	exit 1
fi

NODE_MANAGER=$GL_BINDIR/node-app-manager.sh
CHRIGHT=$GL_BINDIR/chrights.sh
BRANCH=$1
NODE_APP=$2
NODE_APP_ROOT="/srv/http/$NODE_APP/app"
STATIC_ROOT_DIR="/srv/http/$NODE_APP/static"
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


	# Generates new static files
	display_info "Build static files"
	NODE_CONFIG="/etc/node/$NODE_APP/$SERVER_NAME.json" grunt build-prod 2>&1 >> $LOG || display_error "Issue building static files" || return 4

	# Rights in app dir
	display_info "Restore rights in $APP_DIR"
	sudo $CHRIGHT mod_rec_dirs 775 "$APP_DIR" || display_error "Cannot restore rights in $APP_DIR" || return 3
	sudo $CHRIGHT mod_rec_files 664 "$APP_DIR" || display_error "Cannot restore rights in $APP_DIR" || return 3
	sudo $CHRIGHT own_rec "node:node" "$APP_DIR" || display_error "Cannot restore rights in $APP_DIR" || return 3

	# Rights in static app dir
	display_info "Restore rights in $STATIC_ROOT_DIR"

	sudo $CHRIGHT own_rec "www-data:node" "$STATIC_ROOT_DIR" || display_error "Cannot restore rights in $STATIC_ROOT_DIR" || return 5
	sudo $CHRIGHT mod_rec_dirs 775 "$STATIC_ROOT_DIR" || display_error "Cannot restore rights in $STATIC_ROOT_DIR" || return 5
	sudo $CHRIGHT mod_rec_files 664 "$STATIC_ROOT_DIR" || display_error "Cannot restore rights in $STATIC_ROOT_DIR" || return 5

	# OK
	display_info "Successfully updated $NODE_APP - $SERVER_NAME"
	return 0
}

restart_app()
{
	local SERVER_NAME=$1
	sudo $NODE_MANAGER stop "$UPINSTANCE" "$SERVER_NAME" || return $?
	update_app "$SERVER_NAME" || return $?
	sudo $NODE_MANAGER start "$UPINSTANCE" "$SERVER_NAME" || return $?
	return 0
}

deploy_prod()
{
	# stop staging
	sudo stop $NODE_MANAGER "$UPINSTANCE" "staging" || display_warn "$NODE_APP - staging server was not running"
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

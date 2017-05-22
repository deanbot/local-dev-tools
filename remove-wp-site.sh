#!/bin/sh
# ------------------------------------------------------------------
# [Dean] remove wordpress site files and database
#	
# Deps:
# 	global vars used in var definition section must be defined:
#		$WEB_DIR
#		source dv/bash-utils/io-utils.sh
#		requires wp-cli with ~/.wp-cli/config.yml (see wp-cli.template.yml)
# ------------------------------------------------------------------

function remove_wp_site() {
	if [[ "$1" ]]; then
		eval local __domain="$1"
	else
		eval local __domain=$(non_null_val "Enter domain name of the site to remove (ie: mysite.dev): ")
	fi

	echo "..."
	echo "Please start web server (apache/mysql)."
	echo "Press [Enter] when finished."
	echo "..."
	read blank

	eval wp db drop --yes --path=$WEB_DIR$__domain/wordpress;
	rm -rf $WEB_DIR$__domain
	echo "Removed $WEB_DIR$__domain"
}
export -f remove_wp_site
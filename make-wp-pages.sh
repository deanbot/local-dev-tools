#!/bin/sh
# ------------------------------------------------------------------
# [Dean]  Make wordpress site pages
# 	at prompt makes a comma separated list of pages
#	
# Deps:
# 	global vars used in var definition section must be defined:
#		$WEB_DIR
#		source dv/bash-utils/io-utils.sh
#		requires wp-cli with ~/.wp-cli/config.yml (see wp-cli.template.yml)
# ------------------------------------------------------------------

function make_wp_pages() {
	if [[ "$1" ]]; then
		eval local __domain="$1"
	else
		eval local __domain=$(non_null_val "Enter domain name site to add pages to (ie: mysite.dev): ")
	fi

	echo "..."
	echo "Please start web server (apache/mysql)."
	echo "Press [Enter] when finished."
	echo "..."
	read blank

	# prompt for list of dbs
	eval local __allpages=$(non_null_val "Add Pages (i.e. About, Team, Contact Us): ")

	# create all of the pages
	# set internal field separator
	export IFS=","
	for page in $__allpages; do
	  eval wp post create --post_type=page --post_status=publish --post_author=1 --path=$WEB_DIR$__domain/wordpress --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')" 
	done
}
export -f make_wp_pages
#!/bin/sh
# ------------------------------------------------------------------
# [Dean] local wordpress site setup wizard
#	adds specified domain to hosts file, sets up vhost config, prompts for server restart
#	
# Deps:
# 	global vars used in var definition section must be defined:
#		$HOSTS, $VHOSTS, $WEB_DIR,  $SQL_USER, $SQL_PASS
#		source dv/bash-utils/io-utils.sh
#		requires wp-cli with ~/.wp-cli/config.yml (see wp-cli.template.yml)
#		requires mod_rewrite apache model turned on
# ------------------------------------------------------------------

function setup_wp() {
	if [[ "$1" ]]; then
		eval local __domain="$1"
	else
		eval local __domain=$(non_null_val "Enter domain name of the dev site (ie: mysite.dev): ")
	fi

	if [[ "$2" ]]; then
		eval local __sitename=$2
	else
		:
	fi
	
	echo "================================================================="
	echo "Awesome WordPress Installer!!"
	echo "================================================================="

	setup_web "$__domain" / setupresult

	if [ $setupresult -eq 0 ]; then

		# prompt for input
		if [[ "$__sitename" ]]; then
			:
		else
			eval local __site_name=$(non_null_val "Enter Title of site (i.e. My\ Site): ")
		fi
		local __db_name=$(non_null_val "Enter DB Name (i.e. dev_mysite): ")
		local __db_prefix=$(non_null_val "Enter DB Prefix (i.e. wp_): " "wp_")
		stty -echo
		local __admin_pass=$(non_null_val "Enter Admin User Password: ")
		stty echo
		echo

		# prompt to exit if web directory exists
		#if [ -d "$WEB_DIR$__domain" ]; then
	  #	local exit_response=$(y_or_n_val "Domain Directory already exists. Do you want to quit? [y/n]: ")
		#  if [[ $exit_response =~ ^([yY])$ ]]; then
		#  	exit
		#  fi
		#fi

		# double check mysql is running
		echo "..."
		echo "Wait. Is MySQL running yet?"
		echo "Press [Enter] to Continue"
		echo "..."
		read blank

		cd $WEB_DIR$domain

		# add index.php in site directory
		printf "%s" "<?php
/**
 * Front to the WordPress application. This file doesn't do anything, but loads
 * wp-blog-header.php which does and tells WordPress to load the theme.
 *
 * @package WordPress
 */

/**
 * Tells WordPress to load the WordPress theme and output it.
 *
 * @var bool
 */
define('WP_USE_THEMES', true);

/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wordpress/wp-blog-header.php' );" > index.php

		# download wp
		if [ ! -d "wordpress/wp-includes" ]; then
			eval wp core download --path=wordpress
		else
			echo "WP files found. Skipping download."
		fi

		# create wp config file
		#echo "creating wp-config.php"
		if [ -e "wordpress/wp-config.php" ]; then
		  eval local __overwrite_response=$(y_or_n_val "wp-config.php file exists. Overwrite config? [y/n]: ")
		  if [[ $__overwrite_response =~ ^([yY])$ ]]; then
		    rm wordpress/wp-config.php
		    eval wp core config --path=wordpress --dbname=$__db_name --dbuser=$SQL_USER --dbprefix=$__db_prefix --skip-check=true
		  fi
		else
		  eval wp core config --dbname=$__db_name --dbuser=$SQL_USER --dbprefix=$__db_prefix --skip-check=true
		fi

		# create db
		if $(mysql -u root -e "use $__db_name"); then 
			echo "DB exists." 
		else
			eval wp db create --path=wordpress
		fi

		if [ $? -ne 0 ]; then
		  eval local __exit_response=$(y_or_n_val "Database Creation Error. Do you want to quit? [y/n]: ")
		  if [[ $__exit_response =~ ^([yY])$ ]]; then
		    exit
		  else
		    eval local __retry_response=$(y_or_n_val "Retry (i.e. post change and mysql restart? [y/n]: ")
		    if [[ $__retry_response =~ ^([yY])$ ]]; then
		      eval wb db create --path=wordpress
		    fi
		  fi
		fi

		# install wp
		eval wp core install --url=$__domain --title="$__site_name" --admin_password=$__admin_pass

		# update siteurl
		eval wp option update siteurl http://$__domain/wordpress --path=wordpress

		# discourage search engines
		eval wp option update blog_public 0 --path=wordpress

		# update posts per page
		eval wp option update posts_per_page 6 --path=wordpress

		# create home page
		eval wp post create --post_type=page --post_title=Home --post_status=publish --post_author=1 --path=wordpress

		# set homepage as front page
		eval wp option update show_on_front 'page' --path=wordpress
		eval wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids) --path=wordpress

		# set pretty urls
		# requires mod_rewrite apache model turned on (in c/xampp/apache/conf/httpd.conf)
		eval wp rewrite structure '/%postname%/' --hard --path=wordpress
		eval wp rewrite flush --hard --path=wordpress

		# delete hello plugin
		eval wp plugin delete hello --path=wordpress

		# catsay
		catsay "All done!"

		# open in editor
		#local __editor_response=$(y_or_n_val "Do you want to open the project in sublime? [y/n] ")
		#if [[ $__editor_response =~ ^([yY])$ ]]; then
		# 	"${EDITOR:-vi}" wordpress/wp-content/themes/
		#fi

	else
		echo "Hosting setup failed. Ending wp setup."
	fi
}
export -f setup_wp 
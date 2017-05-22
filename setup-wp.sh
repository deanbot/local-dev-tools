#!/bin/sh
# ------------------------------------------------------------------
# [Dean] local wordpress site setup wizard
#	adds specified domain to hosts file, sets up vhost config, prompts for server restart
#	
# Deps:
# 	global vars used in var definition section must be defined
#		source dv/bash-utils/io-utils.sh
# ------------------------------------------------------------------

function setupwp() {
	local $__domain=$1
	setupweb "$__domain" /
}
export -fsetupwp 
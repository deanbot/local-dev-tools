#!/bin/sh
# ------------------------------------------------------------------
# [Dean] local web sitesetup wizard
#	adds specified domain to hosts file, sets up vhost config, prompts for server restart
#	
# Deps:
# 	global vars used in var definition section must be defined
#		source deanbot/bash-utils/io-utils.sh
# ------------------------------------------------------------------

## var definitition 

#plugable vars
hosts=$HOSTS
vhosts=$VHOSTS
webdir=$WEB_DIR
sql_user=$SQL_USER
sql_pass=$SQL_PASS

#app constants
SUCCESS=0
TRUE=1
FALSE=0
MSG_PERMISSION_DENIED="Permission Denied. Run as admin and try again."

#app vars
domain=
status=
hostsline=
serve=
formattedwebdir=${webdir///c/C:}

## start

# test for write access on hosts file
echo "Testing write access to hosts file..."
bash -c "printf \"%s\" \"\" >> \"$hosts\""
if [ $? -eq $SUCCESS ]; then
  echo "Success: hosts file can be editted."
else
  echo $MSG_PERMISSION_DENIED
  status=$FAILURE
  exit $status
fi

if [ $# -eq 0 ]; then
  # prompt for domain
  domain=$(non_null_val "Enter domain name of the dev site (ie: mysite.dev): ")
  serve=$(non_null_val "Add directory to serve (i.e. /dist): " "/")
else
  domain=$@

  #for var in "$@"; do
  #  if [ ! -z "$allpages" ]; then
  #    allpages="${allpages}, ${var}"
  #  else
  #    allpages=$var
  #  fi
  #done
fi

# add line to hosts file
hostsline="127.0.0.1 $domain"
# echo "Checking hosts file for domain..."
grep -q "$domain" "$hosts"  # -q is for quiet. Shhh...
if [ $? -eq $SUCCESS ]; then
	echo "Notice: $domain found in hosts file."
else
  bash -c "printf \"\n%s\" \"$hostsline\" >> \"$hosts\""
  if [ $? -eq $SUCCESS  ]
  then
    echo "Sucess: $domain added to hosts file."
  else
    echo $MSG_PERMISSION_DENIED
    # set status to failure
    status=$FAILURE
    exit $status
  fi
fi

# setup web directory
if [ ! -d "$webdir$domain" ]; then
  mkdir $webdir$domain
  echo "Success: web directory created"
else
  echo "Notice: web directory already exists"
fi

# add virtual host config
# echo "Checking virtual hosts file for domain..."
grep -q "$domain" "$vhosts"
if [ $? -eq $SUCCESS ]; then
	echo "Notice: $domain found in virtual hosts file."
else
	printf "\n\n%s" "<VirtualHost *:80>
	ServerName $domain
	DocumentRoot \"$formattedwebdir$domain$serve\"
</VirtualHost>" >> "$vhosts";
	echo "Success: virtual host config added."
fi

# prompt to restart server
echo "..."
echo "Please restart web server."
echo "Press [Enter] when finished."
echo "..."
read blank

catsay "All Done!"
exit $status
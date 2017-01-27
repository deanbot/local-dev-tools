#!/bin/sh
# ------------------------------------------------------------------
# [Dean] local web sitesetup wizard
#	adds specified domain to hosts file, sets up vhost config, prompts for server restart
#	global vars used in var definition section must be defined
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
formattedwebdir=${webdir///c/C:}

## method definition

# accepts any non-empty input
non_null_val () {
  local __prompt="$1"
  local __default="$2"
  while true; do
    if [ ! -z "$__default" ]; then
      read -e -p "$__prompt" -i "$__default" val
    else
      read -e -p "$__prompt" val
    fi
    if [ ! -z "$val" ]; then
      break
    fi
  done
  echo "$val"
}

# accepts only inputs: yYnN
y_or_n_val () {
  local __prompt="$1"
  local __default="$2"
  while true; do
    if [ ! -z "$__default" ]; then
      read -e -p "$__prompt" -i "$__default" val
    else
      read -e -p "$__prompt" val
    fi
    if [ ! -z "$val" ]; then
      if [[ "$val" =~ ^([yY]|[nN])$ ]]; then
        break
      fi
    fi
  done
  echo "$val"
}

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
	DocumentRoot \"$formattedwebdir$domain\"
</VirtualHost>" >> "$vhosts";
	echo "Success: virtual host config added."
fi

# prompt to restart server
echo "..."
echo "Please restart web server."
echo "Press [Enter] when finished."
echo "..."
read blank

echo -n $'\E[0m'
echo $''
echo $''
echo $'       /\\__/\\'
echo $'      /`    \'\\'
echo $'    === 0  0 ==='
echo $'      \  --  /'
echo $'     /        \\'
echo $'    /          \\'
echo $'   |            |'
echo $'    \\  ||  ||  /'
echo $'     \\_oo__oo_/#######o'
echo $''
echo $'      All done!'
echo $''
exit $status
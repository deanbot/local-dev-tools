#!/bin/sh
# ------------------------------------------------------------------
# [Dean] local web sitesetup wizard
#	adds specified domain to hosts file, sets up vhost config, prompts for server restart
#	
# Deps:
# 	global vars used in var definition section must be defined
#		source dv/bash-utils/io-utils.sh
# ------------------------------------------------------------------

# add line in hosts file that ties localhost to the passed domain name
function writetohosts()
{
  local __domain=$1
  local __returnvar=$2
  local __hostsline="127.0.0.1 $__domain"

  # echo "Checking hosts file for domain..."
  grep -q "$__domain" "$HOSTS"  # -q is for quiet. Shhh...
  if [ $? -eq 0 ]; then
    echo "Notice: $__domain found in hosts file."
    eval $__returnvar="2"
  else
    bash -c "printf \"\n%s\" \"$__hostsline\" >> \"$HOSTS\""
    eval $__returnvar=$?
  fi
}

# add virtual host config
function writetovhosts()
{
  local __domain=$1
  local __serve=$2
  local __returnvar=$3

  # echo "Checking virtual hosts file for domain..."
  grep -q "$__domain" "$VHOSTS"
  if [ $? -eq 0 ]; then
    echo "Notice: $__domain found in virtual hosts file."
    eval $__returnvar="2"
  else
    local __formattedwebdir=${WEB_DIR///c/C:}
    printf "\n\n%s" "<VirtualHost *:80>
ServerName $__domain
DocumentRoot \"$__formattedwebdir$__domain$__serve\"
</VirtualHost>" >> "$VHOSTS";
    eval $__returnvar=$?
  fi
}

function setup_web() {
  local __domain=$1
  local __serve=$2
  local __returnvar=$3

  # test write access
  testwrite $HOSTS writeaccess

  if [ $writeaccess -eq 1 ]; then
    # no write access
    echo "Permission Denied. Run as admin and try again."
    eval $__returnvar="1"
  else

    # get inputs if necessary
    if [[ "$__domain" ]]; then
      # domain passed as first argument
      #echo "using domain: $__domain."
      :
    else
      __domain=$(non_null_val "Enter domain name of the dev site (ie: mysite.dev): ")
    fi
    if [[ "$__serve" ]]; then
      # serve directory passed as second argument
      #echo "using serve directory: $__serve."
      :
    else
      __serve=$(non_null_val "Add directory to serve (i.e. /dist): " "/")
    fi

    # add line in hosts file that ties localhost to the passed domain name
    writetohosts "$__domain" hostsresult
    if [ $hostsresult -eq 2 ]; then
      :
    elif [ $hostsresult -eq 0 ]; then
      echo "Sucess: $__domain added to hosts file."
    else
      echo "Failed to write to hosts file."
    fi

    # setup web directory
    if [ ! -d "$WEB_DIR$__domain" ]; then
      mkdir $WEB_DIR$__domain
      echo "Success: web directory created."
    else
      echo "Notice: web directory already exists."
    fi

    writetovhosts "$__domain" "$__serve" vhostsresult
    if [ $vhostsresult -eq 2 ]; then
      :
    elif [ $vhostsresult -eq 0 ]; then
      echo "Success: virtual host config added."
    else
      echo "Failed to write to vhosts file."
    fi

    # prompt to restart server
    echo "..."
    echo "Please restart web server."
    echo "Press [Enter] when finished."
    echo "..."
    read blank
    eval $__returnvar=0

  fi
}
export -f setup_web
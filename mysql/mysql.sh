#! /bin/bash

if [ $(id -u) != 0 ]; then
  echo "This script must be run as root!"
  exit 42
fi

script_folder=$(pwd)
hostname=$(hostname)

result_folder=$script_folder/results-$hostname

executable=`basename $0`
executable_name=$script_folder/mysql.sh
full_sql_commands=$script_folder/mysql_5_full.sql
specific_sql_commands=$script_folder/mysql_5.sql

SOPTS="hcob"
LOPTS="help,conf,out,bin"

BLUE="\033[34m"
LBLUE="\033[34;1m"
RED="\033[31m"
LRED="\033[31;1m"
YELLOW="\033[33m"
LYELLOW="\033[33;1m"
GREEN="\033[32m"
LGREEN="\033[32;1m"
RST="\033[0m"

usage()
{
  cat << EOF
Usage: ./`basename $executable_name` [options] [arguments]

Options:
  -h, --help    display this help
  -c, --conf    <configuration-folder>
  -o, --out     <result-folder>
  -b, --bin     <mysql-binary-path>

Arguments:
  None

EOF

  exit 42
}

begin()
{
  handle-args $@
  pre-actions $@
}

handle-args()
{
  if $(getopt -T >/dev/null 2>&1) ; [ $? = 4 ] ; then
    OPTS=$(getopt -o $SOPTS --long $LOPTS -n "$executable" -- "$@")
  else
    OPTS=$(getopt $SOPTS "$@")
  fi
  eval set -- "$OPTS"
  while [ $# -gt 0 ]; do
    case $1 in
      -h|--help) usage; exit;;
      -c|--conf) conf_folder=$4; shift;;
      -o|--out) result_folder=$4/results; shift;;
      -b|--bin) mysql_bin=$4; shift;;
      --) break;;
      *) echo -e "${RED}Error: Invalid argument $1${RST}"; exit 1;;
    esac
  done
}

pre-actions()
{
  mysql_bin=$(which mysql)
  mysql_result_folder=$result_folder/mysql-$hostname
  mysql_result_conf_folder=$mysql_result_folder/conf
  mysql_result_command_folder=$mysql_result_folder/commands
  mysql_result_data_folder=$mysql_result_folder/data

  echo "Using MySQL command files:"
  echo "    $full_sql_commands"
  echo "    $specific_sql_commands"
  echo
  read -p "What is the name of MySQL super user (default to root) ? " mysql_username
  if test -z $mysql_username; then mysql_username="root"; fi
  read -s -p "What is the password of the MySQL super user (leave empty if no password) ? " password
  echo "\nUsing MySQL user : $mysql_username"
  echo "Using MySQL bin  : $mysql_bin"
  if [ ! -z $conf_folder ]; then echo "Using MySQL conf : $conf_folder"; fi
  echo "Using results folder  : $mysql_result_folder"
  echo
  read -p "Start ? [y/n]: " go
  if test $go != 'y'; then exit 42; fi

  mkdir -p $result_folder
  mkdir -p $mysql_result_conf_folder
  mkdir -p $mysql_result_data_folder
  mkdir -p $mysql_result_command_folder
}

# Self-destruct
post-actions()
{
  exit 0
}

# Get output from command and put it in a file
lscat()
{
  $1 > $2
}

begin $@

###########################################################################
######################## CONFIGURATION FILES ##############################
###########################################################################
echo "[*] Copying configuration files"

cp /etc/mysql/my.cnf $mysql_result_conf_folder/my.cnf
cp -r /etc/mysql/conf.d $mysql_result_conf_folder/conf.d

if [ -d $conf_folder ] && [ "$conf_folder" != "" ]; then
  cp $conf_folder/my.cnf $mysql_result_conf_folder/my.cnf
  cp -r $conf_folder/conf.d $mysql_result_conf_folder/conf.d
fi

###########################################################################
#################### MySQL COMMON FILES ##############################
###########################################################################
echo "[*] Copying mysql common files"

cp /etc/mysql/debian.cnf $mysql_result_folder/debian.cnf 2>/dev/null
cp /etc/mysql/debian-start $mysql_result_folder/debian-start 2>/dev/null

if [ -d $conf_folder ] && [ "$conf_folder" != "" ]; then
  cp $conf_folder/debian.cnf $mysql_result_conf_folder/debian.cnf
  cp $conf_folder/debian-start $mysql_result_conf_folder/debian-start
fi

###########################################################################
####################### DATABASE CONFIG DUMP ##############################
###########################################################################
echo "[*] Dumping database informations"

echo "  [-] Executing: chown -R $mysql_username:$mysql_username $script_folder"
chown -R $mysql_username:$mysql_username $script_folder

if test -z $password; then
  cmd="$mysql_bin"
else
  cmd="$mysql_bin -p$password"
fi

echo "  [-] Executing: su $mysql_username -c \"$mysql_bin < $(basename $full_sql_commands)\" > full_sql_commands.txt"
full_commands=$(su $mysql_username -c "$cmd < $full_sql_commands" > $mysql_result_command_folder/full_sql_commands.txt)

echo "  [-] Executing: su $mysql_username -c \"$mysql_bin < $(basename $specific_sql_commands)\" > specific_sql_commands.txt"
full_commands=$(su $mysql_username -c "$cmd < $specific_sql_commands" > $mysql_result_command_folder/specific_sql_commands.txt)

echo "[*] Making tarball..."
cd $script_folder && tar jcf mysql-$(hostname).tar.bz2 results-$hostname/mysql-$hostname && cd - &>/dev/null

echo "[*] Done!"
post-actions

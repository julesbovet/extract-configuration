#! /bin/bash

if [ $(id -u) != 0 ]; then
  echo "This script must be run as root!"
  exit 42
fi

script_folder=$(pwd)
hostname=$(hostname)

result_folder=$script_folder/results-$hostname

executable=`basename $0`
executable_name=$script_folder/postgresql.sh
full_sql_commands=$script_folder/postgresql_9_full.sql
specific_sql_commands=$script_folder/postgresql_9.sql

pg_versions="8.1 8.2 8.3 8.4 9.0 9.1 9.2 9.3 9.4 9.5"
pg_version_in_use=

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
  -b, --bin     <psql-binary-path>

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
      -b|--bin) psql_bin=$4; shift;;
      --) break;;
      *) echo -e "${RED}Error: Invalid argument $1${RST}"; exit 1;;
    esac
  done
}

pre-actions()
{
  psql_bin=$(which psql)
  pgsql_result_folder=$result_folder/postgresql-$hostname
  pgsql_result_conf_folder=$pgsql_result_folder/conf
  pgsql_result_command_folder=$pgsql_result_folder/commands
  pgsql_result_data_folder=$pgsql_result_folder/data

  echo "Using PostgreSQL command files:"
  echo "    $full_sql_commands"
  echo "    $specific_sql_commands"
  echo
  read -p "What is the name of PostgreSQL super user (default to postgres) ? " pgsql_username
  if test -z $pgsql_username; then pgsql_username="postgres"; fi
  echo "Using PostgreSQL user : $pgsql_username"
  echo "Using PostgreSQL bin  : $psql_bin"
  if [ ! -z $conf_folder ]; then echo "Using PostgreSQL conf : $conf_folder"; fi
  echo "Using results folder  : $pgsql_result_folder"
  echo
  read -p "Start ? [y/n]: " go
  if test $go != 'y'; then exit 42; fi

  mkdir -p $result_folder
  mkdir -p $pgsql_result_conf_folder
  mkdir -p $pgsql_result_data_folder
  mkdir -p $pgsql_result_command_folder
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

for v in $pg_versions; do
  if [ ! -d "/etc/postgresql/$v" ]; then
    continue
  fi

  pg_version_in_use=$v
  echo "  [-] Found version $pg_version_in_use"
  mkdir -p $pgsql_result_conf_folder/$pg_version_in_use
  cp /etc/postgresql/$pg_version_in_use/main/postgresql.conf $pgsql_result_conf_folder/$pg_version_in_use/postgresql.conf
  cp /etc/postgresql/$pg_version_in_use/main/pg_hba.conf $pgsql_result_conf_folder/$pg_version_in_use/pg_hba.conf
  cp /etc/postgresql/$pg_version_in_use/main/pg_ident.conf $pgsql_result_conf_folder/$pg_version_in_use/pg_ident.conf
  cp /etc/postgresql/$pg_version_in_use/main/start.conf $pgsql_result_conf_folder/$pg_version_in_use/start.conf
  cp /etc/postgresql/$pg_version_in_use/main/pg_ctl.conf $pgsql_result_conf_folder/$pg_version_in_use/pg_ctl.conf
  cp /etc/postgresql/$pg_version_in_use/main/environment $pgsql_result_conf_folder/$pg_version_in_use/environment
done

if [ -d $conf_folder ] && [ "$conf_folder" != "" ]; then
  cp $conf_folder/postgresql.conf $pgsql_result_conf_folder/X.X/postgresql.conf
  cp $conf_folder/pg_hba.conf $pgsql_result_conf_folder/X.X/pg_hba.conf
  cp $conf_folder/pg_ident.conf $pgsql_result_conf_folder/X.X/pg_ident.conf
  cp $conf_folder/start.conf $pgsql_result_conf_folder/X.X/start.conf
  cp $conf_folder/pg_ctl.conf $pgsql_result_conf_folder/X.X/pg_ctl.conf
  cp $conf_folder/environment $pgsql_result_conf_folder/X.X/environment
elif [ -z $pg_version_in_use ]; then
  read -p "Could not find postgresql configuration files. Exit ? [y/n]" do_exit
  if [ $do_exit != "n" ]; then
    exit 42
  fi
fi

###########################################################################
#################### POSTGRESQL-COMMON FILES ##############################
###########################################################################
echo "[*] Copying postgresql-common files"

cp /etc/postgresql-common/user_clusters $pgsql_result_folder/user_clusters 2>/dev/null
cp /etc/postgresql-common/root.crt $pgsql_result_folder/root.crt 2>/dev/null
cp /etc/postgresql-common/root.crl $pgsql_result_folder/root.crl 2>/dev/null
cp -r /etc/postgresql-common/pg_upgradecluster.d $pgsql_result_folder/pg_upgradecluster.d 2>/dev/null


###########################################################################
########################## DATA FILES #####################################
###########################################################################
echo "[*] Copying data files"

pg_data_directory=`cat $pgsql_result_conf_folder/$pg_version_in_use/postgresql.conf | grep "data_directory" | cut -d ' ' -f 3 | tr -d "'" | tr -d '\t' | tr -d '#'`
pg_run_directory=`cat $pgsql_result_conf_folder/$pg_version_in_use/postgresql.conf | grep "unix_socket_directory" | cut -d ' ' -f 3 | tr -d "'" | tr -d '\t' | tr -d '#'`
space_used=`du -hs $pg_data_directory`
total_space=`df $pg_data_directory`
echo "$space_used\n\n$total_space" > $pgsql_result_folder/data-space-used.txt

lscat "ls -lah $pg_data_directory" "$pgsql_result_folder/data_files_access_rights.txt"
lscat "ls -lah $pg_data_directory/pg_xlog" "$pgsql_result_data_folder/wal-list.txt"
lscat "ls -lah $pg_run_directory" "$pgsql_result_folder/run_files_access_rights.txt"

cp $pg_data_directory/server.crt $pgsql_result_data_folder/server.crt 2>/dev/null
cp $pg_data_directory/server.key $pgsql_result_data_folder/server.key 2>/dev/null
cp $pg_data_directory/root.crt $pgsql_result_data_folder/root.crt 2>/dev/null
cp $pg_data_directory/root.crl $pgsql_result_data_folder/root.crl 2>/dev/null

# Postgresql user rights on configuration files
lscat "ls -l /etc/postgresql/$pg_version_in_use/main/" "$pgsql_result_folder/conf_files_access_rights.txt"


###########################################################################
####################### DATABASE CONFIG DUMP ##############################
###########################################################################
echo "[*] Dumping database informations"

echo "  [-] Executing: chown -R $pgsql_username:$pgsql_username $script_folder"
chown -R $pgsql_username:$pgsql_username $script_folder

echo "  [-] Executing: su $pgsql_username -c \"$psql_bin -U $pgsql_username -a -f $(basename $full_sql_commands)\" > full_sql_commands.txt"
full_commands=$(su $pgsql_username -c "$psql_bin -U $pgsql_username -a -f $full_sql_commands" > $pgsql_result_command_folder/full_sql_commands.txt)

echo "  [-] Executing: su $pgsql_username -c \"$psql_bin -U $pgsql_username -a -f $(basename $specific_sql_commands)\" > specific_sql_commands.txt"
specific_commands=$(su $pgsql_username -c "$psql_bin -U $pgsql_username -a -f $specific_sql_commands" > $pgsql_result_command_folder/specific_sql_commands.txt)

# AWK <3
specific_problems=$(cat $pgsql_result_command_folder/specific_sql_commands.txt | awk '/(0 rows)/{for(x=NR-4;x<=NR;x++)d[x];}{a[NR]=$0}END{for(i=1;i<=NR;i++)if(!(i in d))print a[i]}' > $pgsql_result_command_folder/specific_problems.txt)

echo "[*] Making tarball..."
cd $script_folder && tar jcf postgresql-$(hostname).tar.bz2 results-$hostname/postgresql-$hostname && cd - &>/dev/null

echo "[*] Done!"
post-actions

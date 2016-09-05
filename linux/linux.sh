#! /bin/bash

set -o nounset

readonly SOPTS="hol"
readonly LOPTS="help,out,skip-lynis"

readonly BLUE="\033[34m"
readonly LBLUE="\033[34;1m"
readonly RED="\033[31m"
readonly LRED="\033[31;1m"
readonly YELLOW="\033[33m"
readonly LYELLOW="\033[33;1m"
readonly GREEN="\033[32m"
readonly LGREEN="\033[32;1m"
readonly RST="\033[0m"

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root to fully work!"
  read -p "Continue without root? [y/n]: " noroot
  if test "$noroot" = 'n'; then exit 42; fi
fi

script_folder="$(pwd)"
result_folder_base="linux-$(hostname)"
result_folder="$script_folder/results/$result_folder_base"

executable=$(basename "$0")
executable_name="$script_folder/linux.sh"


usage()
{
  cat << EOF
  Usage: ./$(basename "$executable_name") [options] [arguments]

Options:
  -h, --help          display this help
  -o, --out           path to output folder

Arguments:
  None

Default behavior is copying system files

EOF

  exit 42
}

main()
{
  cmdline "$@"
  pre-actions
  post-actions
}

cmdline()
{
  if getopt -T >/dev/null 2>&1 ; [ $? = 4 ] ; then
    OPTS=$(getopt -o "$SOPTS" --long "$LOPTS" -n "$executable" -- "$@")
  else
    OPTS=$(getopt "$SOPTS" "$@")
  fi
  eval set -- "$OPTS"
  while [ $# -gt 0 ]; do
    case $1 in
      -h|--help) usage; exit;;
      -o|--out) result_folder=$4/results; shift;;
      --) break;;
      *) echo -e "${RED}Error: Invalid argument $1${RST}"; exit 1;;
    esac
  done
}

pre-actions()
{
  echo "Using results folder  : $result_folder"

  read -p "Start ? [y/n]: " go
  if test "$go" != 'y'; then exit 42; fi

  mkdir -p "$result_folder"

  # Setup stderr logging
  exec 2> linux.log
}

post-actions()
{
  cd "$script_folder"
}

main "$@"

###########################################################################
######################### SYSTEM INFORMATION ##############################
###########################################################################
echo "[*] System information"
mkdir -p "$result_folder"
cd "$result_folder"

mkdir common
cd common
date > date.txt
uptime > uptime.txt
id -a > id.txt
uname -a > uname.txt
uname -mrs >> uname.txt
sysctl -a > sysctl-a.txt
mount -v > mount-v.txt
lsb_release -a > lsb_release-a.txt
cat /etc/motd > motd.txt
cat /etc/issue > issue.txt
cat /etc/issue.net > issue.net.txt
cat /etc/*-release > release.txt
getent group > group.txt
awk -F: '($3 == "0") {print}' /etc/passwd > super_user.txt
cat /etc/sudoers > sudoers.txt
cd ..

# Important directories
mkdir important-directories
cd important-directories
ls -alh ~ > ~.txt
ls -alh /tmp > tmp.txt
ls -alh /media/ > media.txt
ls -alh /mnt/ > mnt.txt
ls -alh /etc/ > etc.txt
ls -alh /home/ > home.txt
ls -alh /root > root.txt
cd ..

# Proc/kernel information
mkdir proc-kernel-information
cd proc-kernel-information
cat /proc/version > proc-version.txt
cat /proc/cpuinfo > proc-cpuinfo.txt
cat /proc/meminfo > proc-meminfo.txt
cat /proc/partitions > proc-partitions.txt
cat /proc/swaps > proc-swaps.txt
cat /proc/devices > proc-devices.txt
cat /proc/mounts > proc-mounts.txt
find /proc/scsi/ -type f -exec cat {} \; > proc-scsi.txt
find /proc/lvm/ -type f -exec cat {} \; > proc-lvm.txt
lsmod > lsmod.txt
rpm -q kernel > rpm.txt
dmesg | grep -i Linux > dmesg.txt
ls /boot/vmlinuz-* > boot.txt
cd ..

# Environment variable information
mkdir environment-variable
cd environment-variable
cat /etc/profile > etc-profile.txt
cat /etc/bashrc > etc-bashrc.txt
cat ~/.bash_profile > bash_profile.txt
cat ~/.bashrc > bashrc.txt
cat ~/.bash_logout > bash_logout.txt
cat ~/.bash_history > bash_history.txt
cat ~/.zshrc > zshrc.txt
cat ~/.zcache/completion > zsh_completion.txt
cat ~/.zcache/history > zsh_history.txt
env > env.txt
set > set.txt
cd ..

# Package information
mkdir package-information
cd package-information
cat /etc/apt/sources.list > apt-sources.list.txt
cp /var/lib/dpkg/status dpkg-status
cp /var/log/dpkg.log .
rpm -qa > rpm-qa.txt
rpm -qa --last > rpm-qa-last.txt
dpkg -l > dpkg.txt
yum list updates > yum-list-updates.txt
ls -lrtd /*bin/* /*/*bin/* >> ls-lrtd.txt
ls -d /var/db/pkg/*/* > gentoo-packages.txt
cd ..

# Partitions information
mkdir partitions-information
cd partitions-information
cat /etc/fstab > fstab.txt
fdisk -l > fdisk.txt 2> /dev/null
blkid > blkid.txt
df -ah > df.txt
cd ..

# Processus information
mkdir processus-information
cd processus-information
ps aux | sort > ps-aux.txt
cd ..

# Configuration files information
mkdir etc
cd etc
cat /etc/inittab > inittab
cat /etc/passwd > passwd
cat /etc/group > group
cat /etc/hosts > hosts
cat /etc/aliases > aliases
cat /etc/bootptab > bootptab
cat /etc/crontab > crontab
cat /etc/ethers > ethers
cat /etc/exports > exports
cat /etc/fdprm > fdprm
cat /etc/filesystems > filesystems
cat /etc/fstab > fstab
cat /etc/groups > groups
cat /etc/gshadow > gshadow
cat /etc/issue > issue
cat /etc/issue.net > issue.net
cat /etc/limits > limits
cat /etc/localtime > localtime
cat /etc/login.defs > login.defs
cat /etc/magic > magic
cat /etc/motd > motd
cat /etc/mtab > mtab
cat /etc/networks > networks
cat /etc/nologin > nologin
cat /etc/printcap > printcap
cat /etc/cshlogin > cshlogin
cat /etc/csh/cshrc > cshrc
cat /etc/protocols > protocols
cat /etc/securetty > securetty
cat /etc/services > services
cat /etc/shadow > shadow
cat /etc/shadow.group > shadow.group
cat /etc/shells > shells
cat /etc/skel/.profile > skel.profile
cat /etc/sudoers > sudoers
cat /etc/X11/XF86Config > XF86Config
cat /etc/termcap > termcap
cat /etc/terminfo > terminfo
cat /etc/usertty > usertty
cat /dev/MAKEDEV > MAKEDEV
mkdir pam.d
cd pam.d
find /etc/pam.d -type f -exec cp {} . \;
cat /etc/pam.conf > pam.conf
cd ..
mkdir modprobe.d
cd modprobe.d
find /etc/modprobe.d -type f -exec cp {} . \;
cd ..
mkdir sysconfig
cd sysconfig
cat /etc/sysconfig/amd > amd
cat /etc/sysconfig/clock > clock
cat /etc/sysconfig/i18n > i18n
cat /etc/sysconfig/init > init
cat /etc/sysconfig/keyboard > keyboard
cat /etc/sysconfig/mouse > mouse
cat /etc/sysconfig/network-scripts/ifcfg-interface > ifcfg-interface
cat /etc/sysconfig/pcmcia > pcmcia
cat /etc/sysconfig//routed > routed
cat /etc/sysconfig/static-routes > static-routes
cat /etc/sysconfig/tape > tape
cd ..
mkdir sysctl.d
cd sysctl.d
find /etc/sysctl.d -type f -exec cp {} . \;
cd ..
mkdir snmp
cd snmp
find /etc/snmp -type f -exec cp {} . \;
cp /etc/snmp.conf snmp2.conf
cd ..
cd ..

# Log information
mkdir log-information
cd log-information
cat /etc/syslog.conf > syslog.txt
cat /etc/newsyslog.conf > newsyslog.txt
ls -alrth /var/adm > var-adm.txt
ls -alrth /var/log > var-log.txt
ls -alrth /var/log/syslog > var-syslog.txt
dmesg > dmsg.txt
mkdir logrotate
cd logrotate
find /etc/logrotate.d -type f -exec cp {} . \;
cd ..
cd ..

# Connection information
mkdir connection-information
cd connection-information
who > who.txt
w > w.txt
last -a -F -n 1000 > last.txt || last -a -n 1000 > last.txt
lastb -a -F -n 1000 > lastb.txt || lastb -a -n 1000 > lastb.txt
mkdir default
cd default
find /etc/default -type f -exec cp {} . \;
cd ..
cd ..

# Ip/services information
mkdir ip_services-information
cd ip_services-information
ifconfig -a > ifconfig.txt
cat /proc/net/vlan/config > vlanconfig.txt
netstat -i > netstat_i.txt
netstat -rn > netstat_rn.txt
netstat -anptev > netstat_anptev.txt
cat /etc/sysctl.conf > sysconf.conf
mkdir proc-sys-net
cd proc-sys-net
cp -rf /proc/sys/net .
cd ..
chkconfig --list | grep 3:on > chkconfigboot.txt

ls -l /etc/hosts.allow > hosts.allow
echo "" >> hosts.allow
cat /etc/hosts.allow >> hosts.allow

ls -l /etc/hosts.deny > hosts.deny
echo "" >> hosts.deny
cat /etc/hosts.deny >> hosts.deny

ls -l /etc/hosts.equiv > hosts.equiv
echo "" >> hosts.equiv
cat /etc/hosts.equiv >> hosts.equiv

ls -l /etc/ftpusers > ftpusers
echo "" >> ftpusers
cat /etc/ftpusers >> ftpusers
cd ..

# Network information
mkdir network
cd network
arp -e > arp.txt
route > route.txt
route -6n > route-6n.txt
/sbin/route -nee > route_nee.txt
cat /etc/sysconfig/network > network.txt
cat /etc/networks > networks.txt
dnsdomainname > dnsdomainname.txt
iptables -L --line-number -v -n > iptables.txt
iptables -t nat -L --line-number -n -v > iptables-nat.txt
ip6tables -L --line-numbers -n -v > ip6tables.txt
ip6tables -t nat -L --line-numbers -n -v > ip6tables-nat.txt
cd ..

# Rpc
mkdir rpc
cd rpc
cat /etc/exports > exports.txt
rpcinfo -p > rpcinfo.txt 2>/dev/null
showmount -e > showmount.txt 2>/dev/null
cd ..

mkdir web-server
cd web-server
# Apache
if [ -d /etc/apache2 ]; then
  mkdir apache
  cd apache
  cat /etc/apache2/apache2.conf > apache2.txt
  cat /etc/apache2/ports.conf > apache2-ports.txt
  cat /etc/apache2/envvars > apache2-envvars.txt
  cat /etc/apache2/magic > apache2-magic.txt
  apache2ctl -M > apache-loaded-modules.txt 2>/dev/null || httpd -M > apache-loaded-modules.txt 2>/dev/null
  cp -rf -L /etc/apache2/sites-enabled .
  cp -rf -L /etc/apache2/conf-enabled .
  apache2 -v > apache2-version.txt
  cd ..
fi
if [ -d /etc/httpd ]; then
  mkdir httpd
  cd httpd
  cat /etc/httpd/conf/httpd.conf > apache2.txt
  cat /etc/httpd/conf/httpd.conf_ori > apache2-ori.txt
  apachectl -M > apache-loaded-modules.txt 2>/dev/null || httpd -M > apache-loaded-modules.txt 2>/dev/null
  cp -rf -L /etc/httpd/conf.d .
  httpd -V > apache2-version.txt
  cd ..
fi
# Nginx
if [ -d /etc/nginx ]; then
  mkdir nginx
  cd nginx
  cat /etc/nginx/nginx.conf > nginx.txt
  cp -rf -L /etc/nginx/sites-enabled .
  cp -rf -L /etc/nginx/conf.d .
  cd ..
fi
cd ..

mkdir php
cd php
cp /etc/php.ini .
for i in $(find /etc/php5 -name "*php.ini*"); do
  cp "$i" "slash$(echo "$i" | tr '/' '-')";
done
cd ..

mkdir ssh
cd ssh
find /etc/sshd -exec cp -r {} . \;
cd ..

mkdir postfix
cd postfix
find /etc/postfix -exec cp -r {} . \;
cd ..

# Misc
mkdir misc
cd misc
ls -alh /var/mail/ > misc.txt
cat ~/.zcache/* > zcache.txt
cat ~/.bash_history > bash_history.txt
cat ~/.zsh_history > zsh_history.txt
cat ~/.nano_history > nano_history.txt
cat ~/.atftp_history > atftp_history.txt
cat ~/.mysql_history > mysql_history.txt
cat ~/.php_history > php_history.txt
cat ~/.vimrc > vimrc.txt
cat ~/.emacsrc > emacsrc.txt
cat /var/mail/root > var-mail-root.txt
cat /var/spool/mail/root > var-spool-mail-root.txt
cat /var/apache2/config.inc > var-apache2-config.inc.txt
cat /var/lib/mysql/mysql/user.MYD > var-lib-mysql-mysql-user.txt
cat /root/anaconda-ks.cfg > root-anaconda-ks.txt

ls -alhR /var/www/ > var-www.txt
ls -alhR /srv/www/htdocs/ > serv-www-htdocs.txt
ls -alhR /opt/lampp/htdocs/ > opt-lampp-htdocs.txt
ls -alhR /var/www/html/ > var-www-html.txt
cd ..

echo "[*] Making tarball $result_folder_base.tar.bz2 in $script_folder/results"
cd "$script_folder/results" && tar jcf "$result_folder_base.tar.bz2" "$result_folder_base" 2>/dev/null && cd - &>/dev/null

echo "[*] Done!"

post-actions


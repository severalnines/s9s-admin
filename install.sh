#!/bin/bash
# Copyright 2012 Severalnines AB
#
# MODIFY THE BELOW TO SUIT YOU ENV:
function init
{
    FILES=`ls /etc/cmon.cnf 2>&1`
    FILES2=`ls /etc/cmon.d/*.cnf 2>&1`    
    FILES="$FILES $FILES2"
    configfile=""
    for f in $FILES 
    do
	X=`grep -l cluster_id=${CLUSTER_ID} $f 2>&1 `	
	if [ $? -eq 0 ]; then 
	    source $f
            configfile=$f
	fi
    done

    if [ -z "$configfile" ]; then
	echo "No matching configuration file found having cluster_id=${CLUSTER_ID}"
	exit 1
    fi
    
    source $configfile
    
    CMON_DB_HOST=127.0.0.1
    CMON_DB_PORT=$mysql_port
    CMON_USER=cmon
    CMON_DB_DB=cmon
    CMON_PASSWORD=$mysql_password
    MYSQL_BIN=$mysql_basedir/bin/mysql
    CONNECT_TIMEOUT=10
    CLUSTER_TYPE=$type
    MYSQL_OPTS="--connect-timeout=$CONNECT_TIMEOUT"
    OSUSER=$USER
    if [ "$OSUSER" != "root" ]; then
	echo "must be executed as 'root' or with 'sudo'"
	exit 1
    fi
}

function load_opts 
{
    local CLUSTER_ID=$1
    echo "load opts $CLUSTER_ID"
    OS=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='OS' AND cid=$CLUSTER_ID" 2>/dev/null`
    CONFIGDIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='CONFIGDIR' AND cid=$CLUSTER_ID" 2>/dev/null`
    MYSQL_PORT=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='MYSQL_PORT' AND cid=$CLUSTER_ID" 2>/dev/null`
    GALERA_PORT=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='GALERA_PORT' AND cid=$CLUSTER_ID" 2>/dev/null`
    MYSQL_BASEDIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='MYSQL_BASEDIR' AND cid=$CLUSTER_ID" 2>/dev/null`
    MYSQL_SCRIPTDIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SCRIPTDIR' AND cid=$CLUSTER_ID" 2>/dev/null`
    SSH_IDENTITY=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SSH_IDENTITY' AND cid=$CLUSTER_ID" 2>/dev/null`
    SSH_USER=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SSH_USER' AND cid=$CLUSTER_ID" 2>/dev/null`
    SSH_PORT=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SSH_PORT' AND cid=$CLUSTER_ID" 2>/dev/null`
    SSH_OPTSX=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SSH_OPTS' AND cid=$CLUSTER_ID"`
    SUDO=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='SUDO' AND cid=$CLUSTER_ID" 2>/dev/null`    
    OS_USER_HOME=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='OS_USER_HOME' AND cid=$CLUSTER_ID" 2>/dev/null`
    TMPDIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='STAGING_DIR' AND cid=$CLUSTER_ID"`
    S9S_TMPDIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='STAGING_DIR' AND cid=$CLUSTER_ID"`
    VENDOR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon_configuration where param='VENDOR' AND cid=$CLUSTER_ID" 2>/dev/null`
    DATADIR=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select value from cmon.cluster_config where variable='datadir' and cid=1 order by id asc limit 1" 2>/dev/null`
    MYCNF=`$MYSQL_BIN -N -B -A --user=$CMON_USER --password=$CMON_PASSWORD --database=$CMON_DB_DB --host=$CMON_DB_HOST --port=$CMON_DB_PORT -e "select data  from cmon.cluster_configuration where cid=1 limit 1" 2>/dev/null`


    echo $MYCNF |  sed 's#\\n#\n\r#g' > /tmp/my.cnf
    
    SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oNumberOfPasswordPrompts=0 -oConnectTimeout=10"
    if [ "$SSH_IDENTITY" = "" ]; then
	SSH_IDENTITY="-oIdentityFile=${OS_USER_HOME}/.ssh/id_rsa"
    else
	SSH_IDENTITY="-oIdentityFile=$SSH_IDENTITY"
    fi

    SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oNumberOfPasswordPrompts=0 -oConnectTimeout=10 $SSH_IDENTITY"
    SSH_OPTS2="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oNumberOfPasswordPrompts=0 -oConnectTimeout=10 $SSH_IDENTITY"
    if [ "$SSH_USER" != "root" ]; then
	SSH_OPTS_EXTRA="-ftt"
	SSH_OPTS=" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oNumberOfPasswordPrompts=0 -oConnectTimeout=10 $SSH_IDENTITY"
	if [ "$SUDO" = "" ] || [ "$SUDO" = "NULL" ];  then
           SUDO="sudo"
        fi
    fi
    if [ "$SSH_PORT" = "" ] || [ "$SSH_PORT" = "NULL" ];  then
        SSH_PORT="22"
    fi

    if [ "$S9S_TMPDIR" = "" ] || [ "$TMPDIR" = "NULL" ];  then
	S9S_TMPDIR="/tmp/s9s/"
	TMPDIR="/tmp/s9s/"
    fi
    SSH_OPTS="$SSH_OPTSX -p$SSH_PORT $SSH_OPTS"    
    SSH_OPTS2="-P$SSH_PORT $SSH_OPTS2"    
}

function remote_cmd()
{
   desthost=$1
   xcommand=$2
   MAX_RETRIES=1
   printf "%-4s: Executing '%s' " "$desthost" "$xcommand"
   retry=0
   while [ $retry -lt $MAX_RETRIES ]; 
   do
      x=`ssh -q $SSH_OPTS $SSH_USER@$desthost "$SUDO $xcommand " 2>&1  >> $HOME/s9s_deploy.log`
      if [ $? -eq 0 ]; then
          printf "\033[32m[ok]\033[0m\n"
          return 0
      fi
      retry=`expr $retry + 1`
      printf "\033[31m[failed: retrying ${retry}/${MAX_RETRIES}]\033[0m\n"
      ssh -q $SSH_OPTS $SSH_USER@$desthost " sync " 2>&1  >> $HOME/s9s_deploy.log
      sleep 1
   done
   printf "\033[31m[failed]\033[0m\n"
   echo $x
   echo 'The following command failed:'
   echo "ssh -q $SSH_OPTS $SSH_USER@$desthost \"$SUDO $xcommand \""
   echo 'Try running the command on the line above again, contact http://support.severalnines.com/ticket/new, attach the output from deploy.sh and the error from running the command to the Support issue.'
   exit 1
}

function remote_copy()
{
   srcfile=$1
   desthost=$2
   destfile=$3
   printf "%-4s: Copying '%s' " "$desthost" "$srcfile"
   scp $SSH_OPTS2 $srcfile $SSH_USER@$desthost:$destfile > $HOME/s9s_cmd.log 2>&1
   if [ $? -eq 0 ]; then
      printf "\033[32m[ok]\033[0m\n"
      return 0
   else
      printf "\033[31m[failed]\033[0m\n"
      cat $HOME/s9s_cmd.log
      exit 1
   fi
}


args=`getopt p:i:P:t:d:j: $*`
set -- $args
echo $args
for i
do    
    case "$i" in
        -i)
	    CLUSTER_ID="$2"; shift;
	    shift;;
    esac
done    

if [ -z "$CLUSTER_ID" ]; then
    echo "./install.sh -i <cluster id> missing"
    exit 1
fi
init
load_opts $CLUSTER_ID

QUERY="select group_concat(hostname SEPARATOR ' ') from ${CMON_DB_DB}.hosts where cid=${CLUSTER_ID}"
SERVER_LIST=`$MYSQL_BIN $MYSQL_OPTS --user=$CMON_USER --password=$CMON_PASSWORD  --host=127.0.0.1 --port=$CMON_DB_PORT -N -Bse "$QUERY"  2>/dev/null`
if [ "$SERVER_LIST" = "NULL" ]; then
    echo "No servers found"
    exit
fi
if [ -z "$SERVER_LIST" ]; then
    echo "No servers found"
    exit
fi
if [ -d ccadmin/s9s_repo ]; then   
    mv ccadmin/s9s_repo ccadmin/repo
fi
for H in $SERVER_LIST
do
    echo "Installing on $H "
    remote_cmd $H "mkdir -p $S9S_TMPDIR"
    remote_cmd $H "chown -R $SSH_USER:$SSH_USER $S9S_TMPDIR"
    remote_copy "cluster/s9s_*" $H $S9S_TMPDIR
    remote_copy "ccadmin/s9s_*" $H $S9S_TMPDIR
    remote_cmd $H "mv $S9S_TMPDIR/s9s_*  /usr/bin"
    echo "-----------------"
done
if [ -d ccadmin/s9s_repo ]; then   
    mv ccadmin/repo ccadmin/s9s_repo
fi

echo "Done."
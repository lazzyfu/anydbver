#!/bin/bash
unset LC_CTYPE
:> test-run.log

if [[ "x$1" = "x" || "x$1" = "xps-async-proxysql" ]] ; then
  ./anydbver deploy ps:5.7 node1 ps:5.7 master:default node2 ps:5.7 master:default node3 proxysql master:default >> test-run.log
  test $(./anydbver ssh node3 mysql --protocol=tcp --port 6032 -uadmin -padmin -e "'select * from runtime_mysql_servers'" 2>/dev/null|grep -c ONLINE ) = 3 || echo "ps-async-proxysql: FAIL"
fi

for m in mysql ps ; do
  if [[ "x$1" = "x" || "x$1" = "x$m" ]] ; then
    for ver in 5.6 5.7 8.0 ; do 
      ./anydbver deploy $m:$ver >> test-run.log
      ./anydbver ssh default mysql -e "'select version()'" 2>/dev/null |grep -q $ver || echo "$m:$ver : FAIL"
    done
  fi
done

if [[ "x$1" = "x" || "x$1" = "xps-el8" ]] ; then
  for ver in 8.0 ; do 
    ./anydbver deploy ps:$ver >> test-run.log
    ./anydbver ssh default mysql -e "'select version()'" 2>/dev/null |grep -q $ver || echo "ps-el8: FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xpxc" ]] ; then
  for ver in 5.6 5.7 8.0; do
    ./anydbver deploy pxc:$ver node1 pxc:$ver galera-master:default node2 pxc:$ver galera-master:default >> test-run.log
    ./anydbver ssh default mysql -e "'show status'" 2>/dev/null|grep wsrep_cluster_size|grep -q 3 || echo "pxc $ver: FAIL"
  done
fi


if [[ "x$1" = "x" || "x$1" = "xmariadb" ]] ; then
  for ver in 10.3 10.4 10.5; do
    ./anydbver deploy mariadb:$ver >> test-run.log
    ./anydbver ssh default mysql -e "'select version()'" 2>/dev/null |grep -q $ver || echo "mariadb: FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xmariadb-galera" ]] ; then
  for ver in 10.3 10.4 10.5; do
    ./anydbver deploy mariadb-cluster:$ver node1 mariadb-cluster:$ver galera-master:default node2 mariadb-cluster:$ver galera-master:default >> test-run.log
    ./anydbver ssh default mysql -e "'show status'" 2>/dev/null|grep wsrep_cluster_size|grep -q 3 || echo "mariadb-galera $ver: FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xpmm" ]] ; then
  ./anydbver deploy pmm node1 ps:5.7 pmm-client pmm-server:default >> test-run.log
  curl -u admin:secret -k -s https://$(./anydbver ip)/graph/|grep -q pmm || echo "pmm: FAILED"
fi

if [[ "x$1" = "x" || "x$1" = "xpg" ]] ; then
  for ver in 9.5 9.6 10 11 12 13 ; do
    ./anydbver deploy pg:$ver >> test-run.log
    ./anydbver ssh default psql -U postgres -h $(./anydbver ip) -c "'select version()'" 2>/dev/null | grep -q $ver || echo "pg: FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xpg-replication" ]] ; then
  for ver in 9.5 9.6 10 11 12 13 ; do
    ./anydbver deploy pg:$ver node1 pg:$ver master:default >> test-run.log
    ./anydbver ssh default psql -U postgres -h $(./anydbver ip) -xc "'select * from pg_replication_slots'" 2>/dev/null|grep active_pid |cut -d'|' -f 2|egrep -q '[0-9]' || echo "pg-replication $ver : FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xppg" ]] ; then
  for ver in 12.2 12.3 12.4 12.5 13.0 13.1 ; do
    ./anydbver deploy ppg:$ver >> test-run.log
    ./anydbver ssh default psql -U postgres -h $(./anydbver ip) -c "'select version()'" 2>/dev/null | grep -q $ver || echo "ppg $ver: FAIL"
  done
fi

if [[ "x$1" = "x" || "x$1" = "xpsmdb" ]] ; then
  for ver in 3.0 3.2 3.4 3.6 4.2 4.4 ; do
    ./anydbver deploy psmdb:$ver >> test-run.log
    ./anydbver ssh default mongo --eval "'db.version()'" 2>/dev/null | grep -q $ver || echo "psmdb $ver: FAIL"
  done
fi

# Regression tests
if [[ "x$1" = "x" || "x$1" = "xissue-2" ]] ; then
  ./anydbver deploy mysql:$(grep 8.0 .version-info/mysql.el7.txt |tail -n 2|head -n 1) >> test-run.log
  ./anydbver ssh default mysql -e "'select version()'" 2>/dev/null |grep -q 8.0 || echo "issue-2 : FAIL"
fi

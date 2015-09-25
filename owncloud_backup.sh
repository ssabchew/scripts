#!/bin/bash

set -x
set -e

###=== VARIABLES ===###
sitedir=/srv/www/owncloud/
bkpdir=/mnt/backups/owncloud
mdate=$(date +"%Y%m%d")
dbname=owncloud
archivename=owncloud_${mdate}.tar.gz



###=== MAIN ===###
pushd ${bkpdir} &>/dev/null

rm -rf ${mdate}
rm -rf  "${archivename}"
mkdir -p ${mdate}

pushd ${mdate} &>/dev/null

rsync -axAXH $sitedir owncloud_${mdate}/
mysqldump --lock-tables ${dbname} > owncloud-sqlbkp_${mdate}.bak.sql

pushd ..

tar zcvf "${archivename}" ${mdate}
rm -rf ${mdate}

popd &>/dev/null

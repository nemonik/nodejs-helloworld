#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

# Dump DBs
mysqldump --host=mysql.service.$DOCKER_DEV_HOST --port=33061 --user=root --password="gogs" --all-databases >  /tmp/gogs.sql
mysqldump --host=mysql.service.$DOCKER_DEV_HOST --port=33060 --user=root --password="drone" --all-databases >  /tmp/drone.sql

# Create bucket, if need be
BUCKET_EXIST=$(aws s3 ls | grep $S3_BUCKET_NAME | wc -l)
if [ $BUCKET_EXIST -eq 0 ];
then
  aws s3 mb s3://$S3_BUCKET_NAME
fi

cd /tmp

aws s3 --region $AWS_DEFAULT_REGION cp gogs.sql s3://$S3_BUCKET_NAME/$TIMESTAMP/gogs.sql

aws s3 --region $AWS_DEFAULT_REGION cp drone.sql s3://$S3_BUCKET_NAME/$TIMESTAMP/drone.sql

tar czf gogs-data.tar.gz /data

aws s3 --region $AWS_DEFAULT_REGION cp gogs-data.tar.gz s3://$S3_BUCKET_NAME/$TIMESTAMP/gogs-data.tar.gz

tar czf drone-data.tar.gz /var/lib/drone

aws s3 --region $AWS_DEFAULT_REGION cp drone-data.tar.gz s3://$S3_BUCKET_NAME/$TIMESTAMP/drone-data.tar.gz

#!/usr/bin/bash

#
# Backup scrupt to backup the Gogs-Drone CI/CD pipeline.
#
# @athor <github.com@nemomik.com> Michael Joseph Walsh
#

# Sync just incase there's been some drift.  I've seen it happen in VMs
ntpdate pool.ntp.org

# Stop the web service front-ends so the database and volumes aren't written to during the backup
systemctl stop docker-gogs
systemctl stop docker-drone

docker run --rm -e AWS_ACCESS_KEY_ID=AKIAJOI6F5O3J5QZ2WJA -e AWS_SECRET_ACCESS_KEY=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 --volumes-from drone-data --volumes-from gogs-data --name gogs-drone-backup nemonik/gogs-drone-backup 

# Start the web service front-ends
systemctl start docker-gogs
systemctl start docker-drone

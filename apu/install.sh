#!/bin/sh

mkdir -p /opt/scobc-v1-env-test

cp -r run.sh tests /opt/scobc-v1-env-test

cp systemd/scobc-v1-env-test.service /lib/systemd/system/
systemctl daemon-reload
systemctl enable scobc-v1-env-test.service

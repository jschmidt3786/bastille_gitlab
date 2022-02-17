#!/bin/sh
psql -d template1 -U postgres -c "CREATE USER git CREATEDB SUPERUSER;"
psql -d template1 -U postgres -c "CREATE DATABASE gitlabhq_production OWNER git;"
#psql -U git -d gitlabhq_production # just to test

psql -U postgres -d gitlabhq_production -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
psql -U postgres -d gitlabhq_production -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"

echo 'unixsocket /var/run/redis/redis.sock' >> /usr/local/etc/redis.conf
echo 'unixsocketperm 770' >> /usr/local/etc/redis.conf
sysrc redis_enable=YES
service redis start
pw groupmod redis -m git

cd /usr/local/www/gitlab-ce || exit
vi config/gitlab.yml
#vi config/secrets.yml
#vi config/puma.rb

su -l git -c "git config --global core.autocrlf input"
su -l git -c "git config --global gc.auto 0"
su -l git -c "git config --global repack.writeBitmaps true"
su -l git -c "git config --global receive.advertisePushOptions true"
su -l git -c "git config --global core.fsyncObjectFiles true"
su -l git -c "mkdir -p /usr/local/git/.ssh"
su -l git -c "mkdir -p /usr/local/git/repositories"
chown git /usr/local/git/repositories
chgrp git /usr/local/git/repositories
chmod 2770 /usr/local/git/repositories

echo "press enter to edit config/database.yml"
echo "comment out password: and host:"
read
vi config/database.yml

chown git /usr/local/share/gitlab-shell
su -l git -c "cd /usr/local/www/gitlab-ce && rake gitlab:setup RAILS_ENV=production"
chown root /usr/local/share/gitlab-shell

su -l git -c "cd /usr/local/www/gitlab-ce && rake gitlab:env:info RAILS_ENV=production"

su -l git -c "cd /usr/local/www/gitlab-ce && yarn install --production --pure-lockfile"
su -l git -c "cd /usr/local/www/gitlab-ce && RAILS_ENV=production NODE_ENV=production USE_DB=false SKIP_STORAGE_VALIDATION=true NODE_OPTIONS='--max_old_space_size=3584' bundle exec rake gitlab:assets: compile"

psql -d template1 -U postgres -c "ALTER USER git WITH NOSUPERUSER;"

service gitlab start || service gitlab restart



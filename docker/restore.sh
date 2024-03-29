#!/usr/bin/env sh

COL='\033[0;37m'
RED='\033[1;31m'
NC='\033[0m' # No Color

BACKUP=$1
if [ ! -d "$BACKUP" ] || [ ! -d "$BACKUP/nginx" ] || [ ! -d "$BACKUP/mongodb" ] || [ ! -f "$BACKUP/postgres_backup.sql" ]; then
  echo "$BACKUP is not a path to a valid DDoS-DB backup"
  exit 1
fi

printf "${COL}\n Are you sure you want to restore this backup and remove any existing content? [y/N]:${NC}"
read restore

if [ x"$restore" = x"y" ]
then

  printf "${COL}\n Restore NGINX configuration & certificates? [y/N]:${NC}"
  read nginx
  if [ x"$nginx" = x"y" ]
  then
    # Copy NGINX conf files
    docker cp etc/conf.d/ ddosdb_nginx:/etc/nginx/.

    # Copy Let's Encrypt settings and certificates
    docker cp etc/letsencrypt/ ddosdb_nginx:/etc/.
  fi

  printf "${COL}\n Restore DDoS-DB users and website configuration? [y/N]:${NC}"
  read postgres
  if [ x"postgres" = x"y" ]
  then
    # Restore DDoS-DB postgres database with users
    docker cp "$BACKUP/postgres_backup.sql" ddosdb_db:/tmp/postgres_backup.sql
    docker exec ddosdb_db psql -U ddosdb -d postgres -c "drop database ddosdb" > /dev/null
    docker exec ddosdb_db psql -U ddosdb -d postgres -c "create database ddosdb" > /dev/null
    docker exec ddosdb_db pg_restore -h localhost -U ddosdb -d ddosdb "/tmp/postgres_backup.sql"
  fi

  printf "${COL}\n Restore fingerprints? [y/N]:${NC}"
  read mongodb
  if [ x"mongodb" = x"y" ]
  then
    # Restore MongoDB with fingerprints
    docker cp "$BACKUP/mongodb" ddosdb_mongo:/dump
    docker exec ddosdb_mongo mongorestore
  fi

fi

echo "Backup restored succesfully"
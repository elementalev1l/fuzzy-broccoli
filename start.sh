#!/bin/bash
set -e

service postgresql start

if ! su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'\" " | grep -q 1; then
    su postgres -c "psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';\""
fi

if ! su postgres -c "psql -lqt | cut -d \| -f 1 | grep -w $DB_NAME" ; then
    su postgres -c "psql -c \"CREATE DATABASE $DB_NAME OWNER $DB_USER;\""
fi

until pg_isready -h $DB_HOST -U $DB_USER; do
  echo "Esperando PostgreSQL..."
  sleep 1
done

if [ ! -f /opt/lab/config/db.php ]; then
    su model -c "php /opt/lab/craft setup/keys --interactive 0"
    su model -c "php /opt/lab/craft setup/db --interactive 0 --driver pgsql --server $DB_HOST --user $DB_USER --password $DB_PASS --database $DB_NAME"
    su model -c "php /opt/lab/craft install/craft --interactive 0 --email admin@localhost.fr --language en_US --password password --site-name cve --site-url http://localhost:$PORT --username admin"
fi
tail -f /dev/null

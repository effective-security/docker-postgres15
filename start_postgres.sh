#!/bin/bash

export DB_NAME=${POSTGRES_DB:-}
export DB_USER=${POSTGRES_USER:-}
export DB_PASS=${POSTGRES_PASSWORD:-}
export DB_PORT=${POSTGRES_PORT:-}

__create_user() {
  #Grant rights

  echo "*** create user params:"
  echo "*** DB_NAME: $DB_NAME"
  echo "*** DB_USER: $DB_USER"
  #echo DB_PASS: $DB_PASS

  usermod -G wheel postgres

  # Check to see if we have pre-defined credentials to use
if [ -n "${DB_USER}" ]; then
  if [ -z "${DB_PASS}" ]; then
    echo ""
    echo "WARNING: "
    echo "No password specified for \"${DB_USER}\""
    echo ""
    DB_PASS=postgres
  fi
    echo "Creating user \"${DB_USER}\"..."
    echo "CREATE ROLE ${DB_USER} with CREATEROLE login superuser PASSWORD '${DB_PASS}';" |
      su postgres -c 'postgres --single -c config_file=$PG_CONFDIR/postgresql.conf -D $PGDATA'
fi

if [ -n "${DB_NAME}" ]; then
  echo "Creating database \"${DB_NAME}\"..."
  echo "CREATE DATABASE ${DB_NAME};" | \
    su postgres -c 'postgres --single -c config_file=$PG_CONFDIR/postgresql.conf -D $PGDATA'

  if [ -n "${DB_USER}" ]; then
    echo "Granting access to database \"${DB_NAME}\" for user \"${DB_USER}\"..."
    echo "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};" |
      su postgres -c 'postgres --single -c config_file=$PG_CONFDIR/postgresql.conf -D $PGDATA'
  fi
fi
}

__run (){

if [ -n "${DB_PORT}" ]; then
  export PGPORT=${DB_PORT}
fi

if [ -z "${PGPORT}" ]; then
  export PGPORT=5432
fi

echo "run server"
echo "config: ${PG_CONFDIR}/postgresql.conf"
echo "port: ${PGPORT}"
echo "data: ${PGDATA}"
su postgres -c 'postgres -c config_file=$PG_CONFDIR/postgresql.conf -D ${PGDATA} -p ${PGPORT} ${PG_EXTRA_OPTS}'
}

# Call all functions

__create_user
__run

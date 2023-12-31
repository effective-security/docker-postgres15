#!/bin/sh
#
# postgresql-setup - Initialization and upgrade operations for PostgreSQL

# PGVERSION is the full package version, e.g., 9.0.2
# Note: the specfile inserts the correct value during package build
PGVERSION=15

# PGENGINE is the directory containing the postmaster executable
# Note: the specfile inserts the correct value during package build
PGENGINE=/usr/pgsql-$PGVERSION/bin

# PREVMAJORVERSION is the previous major version, e.g., 8.4, for upgrades
# Note: the specfile inserts the correct value during package build
#PREVMAJORVERSION=9.2

# PREVPGENGINE is the directory containing the previous postmaster executable
# Note: the specfile inserts the correct value during package build
#PREVPGENGINE=/usr/lib64/pgsql/postgresql-9.2/bin

# Absorb configuration settings from the specified systemd service file,
# or the default "postgresql" service if not specified
SERVICE_NAME=postgresql

# this parsing technique fails for PGDATA pathnames containing spaces,
# but there's not much I can do about it given systemctl's output format...

PGDATA="/var/lib/pgsql/data"

# PGDATA=`systemctl show -p Environment "${SERVICE_NAME}.service" |
#                 sed 's/^Environment=//' | tr ' ' '\n' |
#                 sed -n 's/^PGDATA=//p' | tail -n 1`
# if [ x"$PGDATA" = x ]; then
#     echo "failed to find PGDATA setting in ${SERVICE_NAME}.service"
#     exit 1
# fi

PGPORT="5432"
# PGPORT=`systemctl show -p Environment "${SERVICE_NAME}.service" |
#                 sed 's/^Environment=//' | tr ' ' '\n' |
#                 sed -n 's/^PGPORT=//p' | tail -n 1`
# if [ x"$PGPORT" = x ]; then
#     echo "failed to find PGPORT setting in ${SERVICE_NAME}.service"
#     exit 1
# fi

# Log file for initdb
PGLOG=/var/lib/pgsql/initdb.log

# Log file for pg_upgrade

export PGDATA
export PGPORT

# For SELinux we need to use 'runuser' not 'su'
if [ -x /sbin/runuser ]; then
    SU=runuser
else
    SU=su
fi

script_result=0

# code shared between initdb and upgrade actions
perform_initdb(){
    if [ ! -e "$PGDATA" ]; then
        mkdir "$PGDATA" || return 1
        chown postgres:postgres "$PGDATA"
        chmod go-rwx "$PGDATA"
    fi
    # Clean up SELinux tagging for PGDATA
    [ -x /sbin/restorecon ] && /sbin/restorecon "$PGDATA"

    # Create the initdb log file if needed
    if [ ! -e "$PGLOG" -a ! -h "$PGLOG" ]; then
        touch "$PGLOG" || return 1
        chown postgres:postgres "$PGLOG"
        chmod go-rwx "$PGLOG"
        [ -x /sbin/restorecon ] && /sbin/restorecon "$PGLOG"
    fi

    # Initialize the database
    $SU -l postgres -c "$PGENGINE/initdb -E UTF8 --locale=en_US.UTF-8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8 --pgdata='$PGDATA' --auth='ident'" \
                    >> "$PGLOG" 2>&1 < /dev/null

    # Create directory for postmaster log files
    mkdir "$PGDATA/pg_log"
    chown postgres:postgres "$PGDATA/pg_log"
    chmod go-rwx "$PGDATA/pg_log"
    [ -x /sbin/restorecon ] && /sbin/restorecon "$PGDATA/pg_log"

    if [ -f "$PGDATA/PG_VERSION" ]; then
        return 0
    fi
    return 1
}

initdb(){
    if [ -f "$PGDATA/PG_VERSION" ]; then
        echo $"Data directory is not empty!"
        echo
        script_result=1
    else
        echo -n $"Initializing database ... "
        if perform_initdb; then
            echo $"OK"
        else
            echo $"failed, see $PGLOG"
            script_result=1
        fi
        echo
    fi
}


# See how we were called.
case "$1" in
    initdb)
        initdb
        ;;
    upgrade)
        upgrade
        ;;
    *)
        echo $"Usage: $0 {initdb|upgrade} [ service_name ]"
        exit 2
esac

exit $script_result

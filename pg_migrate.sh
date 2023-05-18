#!/bin/bash
#
# PostgreSQL schema migration manager
# https://github.com/zenwalker/pg_migrate.sh/tree/v2.0

set -e
[[ -f .env ]] && source .env

MIGRATIONS_DIR="migrations"
MIGRATIONS_TABLE="schema_version"

POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_HOST=${POSTGRES_HOST:-127.0.0.1}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
export PGPASSWORD="$POSTGRES_PASSWORD"

alias psql='psql -qtAX -v ON_ERROR_STOP=1 -U $POSTGRES_USER -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB'
shopt -s expand_aliases

#######################################
# Makes sure schema_version table exists.
# Globals:
#   MIGRATIONS_TABLE
# Arguments:
#    None
# Outputs:
#   Log information
#######################################
create_migrations_table() {
    migrations_table_exists=$(psql -c "SELECT to_regclass('$MIGRATIONS_TABLE');")

    if  [[ ! $migrations_table_exists ]]; then
        echo "Creating $MIGRATIONS_TABLE table"
        psql -c "CREATE TABLE $MIGRATIONS_TABLE (file_name text PRIMARY KEY, md5 text, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"
    fi
}

#######################################
# Upgrades database schema to given version.
# Globals:
#   MIGRATIONS_DIR
#   MIGRATIONS_TABLE
# Arguments:
#   Current database schema version
#   Desired database schema version
# Outputs:
#   Log information
#######################################
upgrade() {
    # cd "$1"
    migration_files=$(ls $1/*.sql | sort -V)

    md5s=$(psql -c "select md5 from $MIGRATIONS_TABLE")

    for file in $migration_files; do
        md5=$(cat $file | tr -d "[:space:]" | md5sum | awk '{print $1}')

        if [[ $md5s =~ $md5 ]]; then
          echo "skipping $file $md5"
          continue
        fi

        echo "Applying $file"
        psql < $file
        psql -c "INSERT INTO $MIGRATIONS_TABLE (file_name, md5) VALUES ('$file', '$md5') on conflict(file_name) do update set md5='$md5';"
    done

    # cd ..
}


########################################
# Decides which action to perform.
# Arguments:
#   Target database version to upgrade or downgrade
# Outputs:
#   Execution log
########################################
main() {
    create_migrations_table

    upgrade $MIGRATIONS_DIR
    upgrade "functions"
}

main "$@"

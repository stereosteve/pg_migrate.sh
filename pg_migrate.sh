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

# setting POSTGRES_URL will override any individual settings from above
POSTGRES_URL=${POSTGRES_URL:-postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB}

alias psql='psql -qtAX -v ON_ERROR_STOP=1 $DB_URL'
shopt -s expand_aliases


create_migrations_table() {
    migrations_table_exists=$(psql -c "SELECT to_regclass('$MIGRATIONS_TABLE');")

    if  [[ ! $migrations_table_exists ]]; then
        echo "Creating $MIGRATIONS_TABLE table"
        psql -c "CREATE TABLE $MIGRATIONS_TABLE (file_name text PRIMARY KEY, md5 text, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());"
    fi
}


migrate_dir() {
    migration_files=$(ls $1/*.sql | sort -V)

    md5s=$(psql -c "select md5 from $MIGRATIONS_TABLE")

    for file in $migration_files; do
        md5=$(cat $file | tr -d "[:space:]" | md5sum | awk '{print $1}')

        if [[ $md5s =~ $md5 ]]; then
          echo "... skipping $file $md5"
          continue
        fi

        echo "Applying $file"
        psql < "$file"
        psql -c "INSERT INTO $MIGRATIONS_TABLE (file_name, md5) VALUES ('$file', '$md5') on conflict(file_name) do update set md5='$md5', applied_at=now();"
    done
}

migrate() {
    create_migrations_table

    migrate_dir $MIGRATIONS_DIR
    migrate_dir "functions"
}

test_idempotency() {
    migrate
    psql -c "TRUNCATE TABLE $MIGRATIONS_TABLE CASCADE;"
    migrate
}

main() {
    case "$1" in
        "test") test_idempotency;;
        *) migrate
    esac
}

main "$@"

# pg_migrate roll_forward

The roll_forward branch modifies the bash script to behave like a simplified version [graphile/migrate](https://github.com/graphile/migrate).

* there are no down migrations, only up.
* it will re-run a file any time the contents change.  For dev your migrations must be idempotent.  See [idempotency note](https://github.com/graphile/migrate#idempotency) from graphile/migrate.
* it runs the files in lexographical order.  It's okay if there are two files with `0003` prefix as long as there is no logical dependency between them.
* there is a dedicated folder for `functions`.  They behave the same as migrations folder, the separation is just for organization reasons.

---
# pg_migrate

Schema migration management script for PostgreSQL. [`pg_migrate.sh`](pg_migrate.sh) is dead simple (about 100 LOC) and written in bash so it works everywhere and does not require any extra dependencies except for `psql`.

## Configuration

Before running you need to set a couple environment variables:

 * `POSTGRES_HOST` (default: 127.0.0.1)
 * `POSTGRES_PORT` (default: 5432)
 * `POSTGRES_USER` (default: postgres)
 * `POSTGRES_PASSWORD`
 * `POSTGRES_DB`

Environment variables can be automatically loaded from the `.env` file if it exists in the current directory. But keep in mind that since it is loaded using the `source` command each variable must be exported.

## Migration files

Migration files are located in the [`migrations`](/migrations/) directory. They are just plain SQL files which are applied by the script one by one.

```
├── migrations
│   ├── 0001_create_table.down.sql
│   ├── 0001_create_table.up.sql
│   ├── 0002_add_column.down.sql
│   └── 0002_add_column.up.sql
└── pg_migrate.sh
```

The name of the migration file must contain:

* `0001` — the version number, integer, leading zeroes can be used to enforce
  the proper sorting in your IDE. Using a timestamp like here is also possible.
* `create_table` — the name of the migration, can be anything that makes sense for you,
  usually a short description of what this migration does.
* `up` or `down` — required suffixes to understand if it is a normal or reverting
  migration. The `down` file is optional and can be omitted.

Please note that migrations are not executed in transactions by default, you should take care of it by using `BEGIN` and `COMMIT` statements manually if needed.

## Applying migrations

Executing `pg_migrate.sh` without arguments will case all the upcoming migrations to be applied:

```
$ ./pg_migrate.sh

Current schema version: 0
Upgrading to: 2
-----------------------------
Applying 0001_create_table.up.sql
Applying 0002_add_column.up.sql
```

You can specify the version you want to upgrade to by giving it as the first argument:

```
$ ./pg_migrate.sh 1

Current schema version: 0
Upgrading to: 1
-----------------------------
Applying 0001_create_table.up.sql
```

In case the target version is lower than the current, the required set of reverting migrations will be applied:

```
./pg_migrate.sh 1

Current schema version: 2
Downgrading to: 1
-------------------------------
Applying 0002_add_column.down.sql
```

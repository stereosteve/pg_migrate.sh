-- a better idempotency example of column rename
-- will check for old name before attempting to run
-- from: https://github.com/graphile/migrate/blob/main/docs/idempotent-examples.md

do $$
begin
    if exists(
        select 1
            from information_schema.columns
            where table_schema = 'public'
            and table_name = 'hello_world'
            and column_name = 'age2'
    ) then
        alter table hello_world rename column age2 to age3;
    end if;
end$$;

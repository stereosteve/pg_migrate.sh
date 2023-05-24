-- idempotency example of column rename
-- will swallow error if run twice.

do $$ begin
  alter table hello_world rename column age to age2;
exception
  when others then null;
end $$;

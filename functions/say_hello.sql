CREATE OR REPLACE FUNCTION say_hello(name text)
RETURNS text AS $$
BEGIN

  raise notice 'saying hello to %', name;
  return 'Hello ' || name;

END; $$ LANGUAGE plpgsql;




-- test ?
select say_hello('steve dave');

DO $$
BEGIN

  assert say_hello('dave') = 'Hello dave';

END; $$ LANGUAGE plpgsql;;

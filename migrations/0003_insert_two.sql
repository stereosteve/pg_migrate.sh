insert into hello_world (id, name) values (1, 'fun') on conflict do nothing;
-- insert into hello_world (name) values ('nope');
-- select * from nope;


insert into hello_world (id, name) values (2, 'fun2') on conflict do nothing;
select * from hello_world;

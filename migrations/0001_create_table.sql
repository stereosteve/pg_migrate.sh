CREATE TABLE if not exists hello_world (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

insert into hello_world values (99, 'cool') on conflict do nothing;
insert into hello_world values (999, 'beans') on conflict do nothing;

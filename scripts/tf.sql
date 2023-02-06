# run as sudo -u postgres psql -a -f scripts/tf.sql
create role ubuntu;
drop database ubuntu;
create database ubuntu;
grant all privileges on database ubuntu to ubuntu;

\set ON_ERROR_STOP on

\echo 'create stage schema and tables'
\i /docker-entrypoint-initdb.d/ddl/stage/create_stage_tables.sql
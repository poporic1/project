\set ON_ERROR_STOP on

\echo 'create ddl objects'
\i /docker-entrypoint-initdb.d/dags/ddl/create_ddl_objects.sql

\echo 'create dml objects'
\i /docker-entrypoint-initdb.d/dags/dml/create_dml_objects.sql
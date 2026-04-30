\set ON_ERROR_STOP on

\echo 'create stage objects'
\i /docker-entrypoint-initdb.d/ddl/stage/create_stage_objects.sql

\echo 'create dds tables'
\i /docker-entrypoint-initdb.d/ddl/dds/create_dds_objects.sql

\echo 'create dds functions and procedures'
\i /docker-entrypoint-initdb.d/dml/dds/create_dds_objects.sql
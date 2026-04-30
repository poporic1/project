\set ON_ERROR_STOP on

\echo 'create dds functions'
\i /docker-entrypoint-initdb.d/dml/dds/clean_string.sql
\i /docker-entrypoint-initdb.d/dml/dds/to_date_safe.sql
\i /docker-entrypoint-initdb.d/dml/dds/to_timestamp_safe.sql

\echo 'create dds procedures'
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_position.sql
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_location.sql
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_status.sql
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_critical.sql
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_employee.sql
\i /docker-entrypoint-initdb.d/dml/dds/load_dim_place.sql

\i /docker-entrypoint-initdb.d/dml/dds/load_fact_request.sql
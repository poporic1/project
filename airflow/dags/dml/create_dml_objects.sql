\set ON_ERROR_STOP on


\echo 'create public procedures'
\i /docker-entrypoint-initdb.d/dags/dml/public/replace_table_with_tmp.sql


\echo 'create dds functions'
\i /docker-entrypoint-initdb.d/dags/dml/dds/clean_string.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/to_date_safe.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/to_timestamp_safe.sql

\echo 'create dds procedures'
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_position.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_location.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_status.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_critical.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_employee.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_dim_place.sql
\i /docker-entrypoint-initdb.d/dags/dml/dds/load_fact_request.sql


\echo 'create dm procedures'
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_dim_month.sql
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_dim_place_location.sql
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_dim_responsible.sql
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_dim_status.sql
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_fact_first_priority.sql
\i /docker-entrypoint-initdb.d/dags/dml/dm/load_fact_metrics.sql
\set ON_ERROR_STOP on


\echo 'create stage schema'
\i /docker-entrypoint-initdb.d/dags/ddl/stage/schema_stage.sql

\echo 'create stage tables'
\i /docker-entrypoint-initdb.d/dags/ddl/stage/source_table.sql
\i /docker-entrypoint-initdb.d/dags/ddl/stage/tmp_source_table.sql


\echo 'create dds schema'
\i /docker-entrypoint-initdb.d/dags/ddl/dds/schema_dds.sql

\echo 'create dds tables'
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_position.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_location.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_status.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_critical.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_currency.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/reject_fact_request.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_employee.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/dim_place.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dds/fact_request.sql


\echo 'create dm schema'
\i /docker-entrypoint-initdb.d/dags/ddl/dm/schema_dm.sql

\echo 'create dm tables'
\i /docker-entrypoint-initdb.d/dags/ddl/dm/dim_place_location.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/dim_status.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/dim_responsible.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/dim_month.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/fact_first_priority.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/fact_metrics.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/tmp_fact_first_priority.sql
\i /docker-entrypoint-initdb.d/dags/ddl/dm/tmp_fact_metrics.sql
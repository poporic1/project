\set ON_ERROR_STOP on

\echo 'create dds schema'
\i /docker-entrypoint-initdb.d/ddl/dds/schema_dds.sql

\echo 'create tables'
\i /docker-entrypoint-initdb.d/ddl/dds/dim_position.sql
\i /docker-entrypoint-initdb.d/ddl/dds/dim_location.sql
\i /docker-entrypoint-initdb.d/ddl/dds/dim_status.sql
\i /docker-entrypoint-initdb.d/ddl/dds/dim_critical.sql
\i /docker-entrypoint-initdb.d/ddl/dds/dim_currency.sql

\i /docker-entrypoint-initdb.d/ddl/dds/reject_fact_request.sql
\i /docker-entrypoint-initdb.d/ddl/dds/tmp_fact_request_rows.sql

\i /docker-entrypoint-initdb.d/ddl/dds/dim_employee.sql
\i /docker-entrypoint-initdb.d/ddl/dds/dim_place.sql

\i /docker-entrypoint-initdb.d/ddl/dds/fact_request.sql
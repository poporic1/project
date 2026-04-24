-- Cоздание схемы и таблицы
CREATE SCHEMA IF NOT EXISTS source_data;

CREATE TABLE IF NOT EXISTS source_data.source_table (
      id                    text NULL
    , "desc"                text NULL
    , create_date           text NULL
    , plan_date             text NULL
    , "location"            text NULL
    , place                 text NULL
    , author_id             text NULL
    , author_nm             text NULL
    , author_position       text NULL
    , responsible_id        text NULL
    , responsible_nm        text NULL
    , responsible_position  text NULL
    , status                text NULL
    , close_date            text NULL
    , estimated_value       text NULL
    , critical              text NULL
    , photo                 text NULL
    , escalated             text NULL
    , insert_dt             text NULL
);

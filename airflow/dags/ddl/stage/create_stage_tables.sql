create schema if not exists stage;

create table if not exists stage.source_table (
      id                    text null
    , "desc"                text null
    , create_date           text null
    , plan_date             text null
    , "location"            text null
    , place                 text null
    , author_id             text null
    , author_nm             text null
    , author_position       text null
    , responsible_id        text null
    , responsible_nm        text null
    , responsible_position  text null
    , status                text null
    , close_date            text null
    , estimated_value       text null
    , critical              text null
    , photo                 text null
    , escalated             text null
    , insert_dt             text null
);

comment on schema stage is
  'Слой stage для хранения исходных данных без изменений.';

comment on table stage.source_table is
  'Боевая таблица слоя stage.';

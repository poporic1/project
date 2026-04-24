-- Берем только те строки, которые появились позже последней даты в stage.
select
      id
    , "desc"
    , create_date
    , plan_date
    , "location"
    , place
    , author_id
    , author_nm
    , author_position
    , responsible_id
    , responsible_nm
    , responsible_position
    , status
    , close_date
    , estimated_value
    , critical
    , photo
    , escalated
    , insert_dt
from source_data.source_table
where (%(last_insert_dt)s is null or insert_dt > %(last_insert_dt)s)
order by insert_dt, id;

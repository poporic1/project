CREATE OR REPLACE PROCEDURE dds.load_fact_request()
LANGUAGE plpgsql
AS $$
DECLARE
  -- дата текущего снапшота
  v_snapshot_dt date;
BEGIN

  -- фиксация строк, у которых не удалось определить дату снапшота
  DELETE FROM dds.reject_fact_request
  WHERE dds.to_date_safe(insert_dt) IS NULL;

  INSERT INTO dds.reject_fact_request (
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  )
  SELECT
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  FROM stage.source_table
  WHERE dds.to_date_safe(insert_dt) IS NULL;

  -- отсев некорректных заявок
  DELETE FROM dds.reject_fact_request
  WHERE dds.clean_string(id) IN ('28428', '29081');

  INSERT INTO dds.reject_fact_request (
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  )
  SELECT DISTINCT ON (dds.clean_string(id))
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  FROM stage.source_table
  WHERE dds.clean_string(id) IN ('28428', '29081')
  ORDER BY dds.clean_string(id), dds.to_date_safe(insert_dt) DESC NULLS LAST, ctid;

  -- отсев строк, где дата закрытия раньше даты создания
  DELETE FROM dds.reject_fact_request r
  USING stage.source_table s
  WHERE r.id = s.id
    AND r.insert_dt = s.insert_dt
    AND dds.to_timestamp_safe(s.create_date)::date IS NOT NULL
    AND dds.to_date_safe(s.close_date) IS NOT NULL
    AND dds.to_date_safe(s.close_date) < dds.to_timestamp_safe(s.create_date)::date;

  INSERT INTO dds.reject_fact_request (
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  )
  SELECT
    id,
    "desc",
    create_date,
    plan_date,
    location,
    place,
    author_id,
    author_nm,
    author_position,
    responsible_id,
    responsible_nm,
    responsible_position,
    status,
    close_date,
    estimated_value,
    critical,
    photo,
    escalated,
    insert_dt
  FROM stage.source_table
  WHERE dds.to_timestamp_safe(create_date)::date IS NOT NULL
    AND dds.to_date_safe(close_date) IS NOT NULL
    AND dds.to_date_safe(close_date) < dds.to_timestamp_safe(create_date)::date;

  -- цикл для обработки снапшотов, которых еще нет в dds.fact_request
  FOR v_snapshot_dt IN (
    SELECT DISTINCT dds.to_date_safe(insert_dt) AS snapshot_dt
    FROM stage.source_table
    WHERE dds.to_date_safe(insert_dt) IS NOT NULL
      AND dds.to_date_safe(insert_dt) > (
        SELECT COALESCE(MAX(snapshot_date), DATE '1900-01-01')
        FROM dds.fact_request
      )
    ORDER BY snapshot_dt
  )
  LOOP

    TRUNCATE TABLE dds.tmp_fact_request_rows;

    DELETE FROM dds.reject_fact_request
    WHERE dds.to_date_safe(insert_dt) = v_snapshot_dt;

    -- закрытие заявок, которые были в DDS, но отсутствуют в текущем снапшоте
    WITH
      curr_ids AS (
        SELECT DISTINCT dds.clean_string(id)::int AS request_id
        FROM stage.source_table
        WHERE dds.to_date_safe(insert_dt) = v_snapshot_dt
          AND dds.clean_string(id) ~ '^\d+$'
      ),
      deleted_ids AS (
        SELECT f.fact_request_id
        FROM dds.fact_request f
        WHERE f.effective_to = DATE '9999-12-31'
          AND f.is_deleted = FALSE
          AND NOT EXISTS (
            SELECT 1
            FROM curr_ids c
            WHERE c.request_id = f.request_id
          )
      )
    UPDATE dds.fact_request f
    SET effective_to = v_snapshot_dt,
        is_deleted = TRUE,
        snapshot_date = v_snapshot_dt
    WHERE EXISTS (
      SELECT 1
      FROM deleted_ids d
      WHERE d.fact_request_id = f.fact_request_id
    );

    -- фиксация строк текущего снапшота, которые не прошли dq-проверку
    WITH
      curr AS (
        SELECT
          src.ctid AS src_ctid,
          src.*,
          dds.clean_string(src.id) AS id_clean,
          dds.clean_string(src.author_id) AS author_id_clean,
          dds.clean_string(src.responsible_id) AS responsible_id_clean,
          dds.clean_string(src.status) AS status_clean,
          dds.clean_string(src.location) AS location_clean,
          dds.clean_string(src.place) AS place_clean,
          dds.clean_string(src.critical) AS critical_clean,
          dds.to_timestamp_safe(src.create_date) AS create_ts,
          dds.to_timestamp_safe(src.create_date)::date AS create_dt,
          LEFT(dds.clean_string(src."desc"), 50) AS desc_clean,
          dds.clean_string(src.photo) AS photo_clean,
          dds.clean_string(src.escalated) AS escalated_clean,
          dds.clean_string(src.estimated_value) AS estimated_value_clean,
          dds.clean_string(src.plan_date) AS plan_date_clean,
          dds.clean_string(src.close_date) AS close_date_clean,
          dds.to_date_safe(src.plan_date) AS plan_dt,
          dds.to_date_safe(src.close_date) AS close_dt
        FROM stage.source_table src
        WHERE dds.to_date_safe(src.insert_dt) = v_snapshot_dt
      ),
      prepared_curr_raw AS (
        SELECT
          c.*,
          CASE
            WHEN c.id_clean ~ '^\d+$' THEN c.id_clean::int
            ELSE NULL
          END AS request_id_int,
          CASE
            WHEN c.author_id_clean ~ '^\d+$' THEN c.author_id_clean::int
            ELSE NULL
          END AS author_id_int,
          CASE
            WHEN c.responsible_id_clean ~ '^\d+$' THEN c.responsible_id_clean::int
            ELSE NULL
          END AS responsible_id_int,
          CASE LOWER(c.photo_clean)
            WHEN 'true' THEN TRUE
            WHEN 'false' THEN FALSE
            WHEN '1' THEN TRUE
            WHEN '0' THEN FALSE
            ELSE NULL
          END AS photo_bool,
          CASE LOWER(c.escalated_clean)
            WHEN 'true' THEN TRUE
            WHEN 'false' THEN FALSE
            WHEN '1' THEN TRUE
            WHEN '0' THEN FALSE
            ELSE NULL
          END AS escalated_bool,
          CASE
            WHEN c.estimated_value_clean IS NULL THEN 0::numeric(12, 2)
            WHEN c.estimated_value_clean ~ '^-?\d+([.,]\d+)?$'
            THEN REPLACE(c.estimated_value_clean, ',', '.')::numeric(12, 2)
            ELSE NULL
          END AS estimated_value_num
        FROM curr c
      ),
      prepared_curr AS (
        SELECT
          p.*,
          COUNT(*) OVER (PARTITION BY p.request_id_int) AS id_count,
          ROW_NUMBER() OVER (PARTITION BY p.request_id_int ORDER BY p.src_ctid) AS id_row_num
        FROM prepared_curr_raw p
      ),
      curr_valid AS (
        SELECT
          c.src_ctid,
          c.request_id_int,
          c.author_id_int,
          c.responsible_id_int,
          ds.status_id,
          dp.place_id,
          dc.critical_id,
          cur.currency_id,
          c.create_ts,
          c.create_dt,
          c.desc_clean,
          c.photo_clean,
          c.photo_bool,
          c.escalated_clean,
          c.escalated_bool,
          c.estimated_value_clean,
          c.estimated_value_num,
          c.plan_date_clean,
          c.plan_dt,
          c.close_date_clean,
          c.close_dt,
          CASE
            WHEN ds.status_name = 'Устранено'
             AND c.close_dt IS NOT NULL
             AND c.create_dt IS NOT NULL
             AND c.close_dt >= c.create_dt
             AND c.close_dt - c.create_dt <= 32767
            THEN (c.close_dt - c.create_dt)::int2
            ELSE NULL
          END AS repair_duration
        FROM prepared_curr c
        LEFT JOIN dds.dim_employee author_emp
          ON author_emp.empl_id = c.author_id_int
        LEFT JOIN dds.dim_employee responsible_emp
          ON responsible_emp.empl_id = c.responsible_id_int
        LEFT JOIN dds.dim_status ds
          ON ds.status_name = c.status_clean
        LEFT JOIN dds.dim_location dl
          ON dl.location_name = c.location_clean
        LEFT JOIN dds.dim_place dp
          ON dp.place_name = c.place_clean
         AND dp.location_id = dl.location_id
        LEFT JOIN dds.dim_critical dc
          ON dc.critical_name = c.critical_clean
        LEFT JOIN dds.dim_currency cur
          ON cur.curr_code = 'USD'
        WHERE (
            c.id_count = 1
            OR (
              c.request_id_int = 4626
              AND c.id_row_num = 1
            )
          )
          AND c.request_id_int IS NOT NULL
          AND c.request_id_int NOT IN (28428, 29081)
          AND c.author_id_int IS NOT NULL
          AND c.responsible_id_int IS NOT NULL
          AND c.create_ts IS NOT NULL
          AND c.create_dt IS NOT NULL
          AND author_emp.empl_id IS NOT NULL
          AND responsible_emp.empl_id IS NOT NULL
          AND ds.status_id IS NOT NULL
          AND dl.location_id IS NOT NULL
          AND dp.place_id IS NOT NULL
          AND dc.critical_id IS NOT NULL
          AND (
            c.photo_clean IS NULL
            OR c.photo_bool IS NOT NULL
          )
          AND (
            c.escalated_clean IS NULL
            OR c.escalated_bool IS NOT NULL
          )
          AND (
            c.estimated_value_clean IS NULL
            OR c.estimated_value_num IS NOT NULL
          )
          AND (
            c.plan_date_clean IS NULL
            OR c.plan_dt IS NOT NULL
          )
          AND (
            c.close_date_clean IS NULL
            OR c.close_dt IS NOT NULL
          )
          AND (
            c.close_dt IS NULL
            OR c.close_dt >= c.create_dt
          )
          AND (
            ds.status_name <> 'Устранено'
            OR c.close_dt IS NULL
            OR c.close_dt - c.create_dt <= 32767
          )
      )
    INSERT INTO dds.reject_fact_request (
      id,
      "desc",
      create_date,
      plan_date,
      location,
      place,
      author_id,
      author_nm,
      author_position,
      responsible_id,
      responsible_nm,
      responsible_position,
      status,
      close_date,
      estimated_value,
      critical,
      photo,
      escalated,
      insert_dt
    )
    SELECT
      c.id,
      c."desc",
      c.create_date,
      c.plan_date,
      c.location,
      c.place,
      c.author_id,
      c.author_nm,
      c.author_position,
      c.responsible_id,
      c.responsible_nm,
      c.responsible_position,
      c.status,
      c.close_date,
      c.estimated_value,
      c.critical,
      c.photo,
      c.escalated,
      c.insert_dt
    FROM curr c
    LEFT JOIN curr_valid v
      ON v.src_ctid = c.src_ctid
    WHERE v.src_ctid IS NULL;

    -- сбор новых и измененных заявок во временную таблицу
    WITH
      curr AS (
        SELECT
          src.ctid AS src_ctid,
          src.*,
          dds.clean_string(src.id) AS id_clean,
          dds.clean_string(src.author_id) AS author_id_clean,
          dds.clean_string(src.responsible_id) AS responsible_id_clean,
          dds.clean_string(src.status) AS status_clean,
          dds.clean_string(src.location) AS location_clean,
          dds.clean_string(src.place) AS place_clean,
          dds.clean_string(src.critical) AS critical_clean,
          dds.to_timestamp_safe(src.create_date) AS create_ts,
          dds.to_timestamp_safe(src.create_date)::date AS create_dt,
          LEFT(dds.clean_string(src."desc"), 50) AS desc_clean,
          dds.clean_string(src.photo) AS photo_clean,
          dds.clean_string(src.escalated) AS escalated_clean,
          dds.clean_string(src.estimated_value) AS estimated_value_clean,
          dds.clean_string(src.plan_date) AS plan_date_clean,
          dds.clean_string(src.close_date) AS close_date_clean,
          dds.to_date_safe(src.plan_date) AS plan_dt,
          dds.to_date_safe(src.close_date) AS close_dt
        FROM stage.source_table src
        WHERE dds.to_date_safe(src.insert_dt) = v_snapshot_dt
      ),
      prepared_curr_raw AS (
        SELECT
          c.*,
          CASE
            WHEN c.id_clean ~ '^\d+$' THEN c.id_clean::int
            ELSE NULL
          END AS request_id_int,
          CASE
            WHEN c.author_id_clean ~ '^\d+$' THEN c.author_id_clean::int
            ELSE NULL
          END AS author_id_int,
          CASE
            WHEN c.responsible_id_clean ~ '^\d+$' THEN c.responsible_id_clean::int
            ELSE NULL
          END AS responsible_id_int,
          CASE LOWER(c.photo_clean)
            WHEN 'true' THEN TRUE
            WHEN 'false' THEN FALSE
            WHEN '1' THEN TRUE
            WHEN '0' THEN FALSE
            ELSE NULL
          END AS photo_bool,
          CASE LOWER(c.escalated_clean)
            WHEN 'true' THEN TRUE
            WHEN 'false' THEN FALSE
            WHEN '1' THEN TRUE
            WHEN '0' THEN FALSE
            ELSE NULL
          END AS escalated_bool,
          CASE
            WHEN c.estimated_value_clean IS NULL THEN 0::numeric(12, 2)
            WHEN c.estimated_value_clean ~ '^-?\d+([.,]\d+)?$'
            THEN REPLACE(c.estimated_value_clean, ',', '.')::numeric(12, 2)
            ELSE NULL
          END AS estimated_value_num
        FROM curr c
      ),
      prepared_curr AS (
        SELECT
          p.*,
          COUNT(*) OVER (PARTITION BY p.request_id_int) AS id_count,
          ROW_NUMBER() OVER (PARTITION BY p.request_id_int ORDER BY p.src_ctid) AS id_row_num
        FROM prepared_curr_raw p
      ),
      curr_valid AS (
        SELECT
          c.request_id_int,
          c.author_id_int,
          c.responsible_id_int,
          ds.status_id,
          dp.place_id,
          dc.critical_id,
          cur.currency_id,
          c.create_ts,
          c.create_dt,
          c.desc_clean,
          c.photo_clean,
          c.photo_bool,
          c.escalated_clean,
          c.escalated_bool,
          c.estimated_value_clean,
          c.estimated_value_num,
          c.plan_date_clean,
          c.plan_dt,
          c.close_date_clean,
          c.close_dt,
          CASE
            WHEN ds.status_name = 'Устранено'
             AND c.close_dt IS NOT NULL
             AND c.create_dt IS NOT NULL
             AND c.close_dt >= c.create_dt
             AND c.close_dt - c.create_dt <= 32767
            THEN (c.close_dt - c.create_dt)::int2
            ELSE NULL
          END AS repair_duration
        FROM prepared_curr c
        LEFT JOIN dds.dim_employee author_emp
          ON author_emp.empl_id = c.author_id_int
        LEFT JOIN dds.dim_employee responsible_emp
          ON responsible_emp.empl_id = c.responsible_id_int
        LEFT JOIN dds.dim_status ds
          ON ds.status_name = c.status_clean
        LEFT JOIN dds.dim_location dl
          ON dl.location_name = c.location_clean
        LEFT JOIN dds.dim_place dp
          ON dp.place_name = c.place_clean
         AND dp.location_id = dl.location_id
        LEFT JOIN dds.dim_critical dc
          ON dc.critical_name = c.critical_clean
        LEFT JOIN dds.dim_currency cur
          ON cur.curr_code = 'USD'
        WHERE (
            c.id_count = 1
            OR (
              c.request_id_int = 4626
              AND c.id_row_num = 1
            )
          )
          AND c.request_id_int IS NOT NULL
          AND c.request_id_int NOT IN (28428, 29081)
          AND c.author_id_int IS NOT NULL
          AND c.responsible_id_int IS NOT NULL
          AND c.create_ts IS NOT NULL
          AND c.create_dt IS NOT NULL
          AND author_emp.empl_id IS NOT NULL
          AND responsible_emp.empl_id IS NOT NULL
          AND ds.status_id IS NOT NULL
          AND dl.location_id IS NOT NULL
          AND dp.place_id IS NOT NULL
          AND dc.critical_id IS NOT NULL
          AND (
            c.photo_clean IS NULL
            OR c.photo_bool IS NOT NULL
          )
          AND (
            c.escalated_clean IS NULL
            OR c.escalated_bool IS NOT NULL
          )
          AND (
            c.estimated_value_clean IS NULL
            OR c.estimated_value_num IS NOT NULL
          )
          AND (
            c.plan_date_clean IS NULL
            OR c.plan_dt IS NOT NULL
          )
          AND (
            c.close_date_clean IS NULL
            OR c.close_dt IS NOT NULL
          )
          AND (
            c.close_dt IS NULL
            OR c.close_dt >= c.create_dt
          )
          AND (
            ds.status_name <> 'Устранено'
            OR c.close_dt IS NULL
            OR c.close_dt - c.create_dt <= 32767
          )
      ),
      active_fact AS (
        SELECT
          f.fact_request_id,
          f.request_id,
          f.author_id,
          f.responsible_id,
          f.status_id,
          f.place_id,
          f.critical_id,
          f.currency_id,
          f.create_date,
          f."desc",
          f.photo,
          f.escalated,
          f.estimated_value,
          f.plan_date,
          f.close_date,
          f.repair_duration
        FROM dds.fact_request f
        WHERE f.effective_to = DATE '9999-12-31'
          AND f.is_deleted = FALSE
      ),
      rows_to_insert AS (
        SELECT
          c.*,
          a.fact_request_id AS active_fact_request_id,
          FALSE AS is_deleted,
          CASE
            WHEN a.request_id IS NULL THEN c.create_dt
            ELSE v_snapshot_dt
          END AS effective_from,
          DATE '9999-12-31' AS effective_to
        FROM curr_valid c
        LEFT JOIN active_fact a
          ON a.request_id = c.request_id_int
        WHERE a.request_id IS NULL
           OR (
            c.author_id_int IS DISTINCT FROM a.author_id
            OR c.responsible_id_int IS DISTINCT FROM a.responsible_id
            OR c.status_id IS DISTINCT FROM a.status_id
            OR c.place_id IS DISTINCT FROM a.place_id
            OR c.critical_id IS DISTINCT FROM a.critical_id
            OR c.currency_id IS DISTINCT FROM a.currency_id
            OR c.create_ts IS DISTINCT FROM a.create_date
            OR c.desc_clean IS DISTINCT FROM a."desc"
            OR c.photo_bool IS DISTINCT FROM a.photo
            OR c.escalated_bool IS DISTINCT FROM a.escalated
            OR c.estimated_value_num IS DISTINCT FROM a.estimated_value
            OR c.plan_dt IS DISTINCT FROM a.plan_date
            OR c.close_dt IS DISTINCT FROM a.close_date
            OR c.repair_duration IS DISTINCT FROM a.repair_duration
          )
      )
    INSERT INTO dds.tmp_fact_request_rows (
      active_fact_request_id,
      request_id,
      author_id,
      responsible_id,
      status_id,
      place_id,
      critical_id,
      currency_id,
      create_date,
      "desc",
      photo,
      escalated,
      estimated_value,
      plan_date,
      close_date,
      repair_duration,
      is_deleted,
      effective_from,
      effective_to,
      snapshot_date
    )
    SELECT
      r.active_fact_request_id,
      r.request_id_int,
      r.author_id_int,
      r.responsible_id_int,
      r.status_id,
      r.place_id,
      r.critical_id,
      r.currency_id,
      r.create_ts,
      r.desc_clean,
      r.photo_bool,
      r.escalated_bool,
      r.estimated_value_num,
      r.plan_dt,
      r.close_dt,
      r.repair_duration,
      r.is_deleted,
      r.effective_from,
      r.effective_to,
      v_snapshot_dt
    FROM rows_to_insert r;

    -- закрытие старых записей для измененных заявок
    UPDATE dds.fact_request f
    SET effective_to = v_snapshot_dt
    WHERE f.effective_to = DATE '9999-12-31'
      AND f.is_deleted = FALSE
      AND EXISTS (
        SELECT 1
        FROM dds.tmp_fact_request_rows r
        WHERE r.active_fact_request_id = f.fact_request_id
      );

    -- вставка новых записей из временной таблицы
    INSERT INTO dds.fact_request (
      request_id,
      author_id,
      responsible_id,
      status_id,
      place_id,
      critical_id,
      currency_id,
      create_date,
      "desc",
      photo,
      escalated,
      estimated_value,
      plan_date,
      close_date,
      repair_duration,
      is_deleted,
      effective_from,
      effective_to,
      snapshot_date
    )
    SELECT
      r.request_id,
      r.author_id,
      r.responsible_id,
      r.status_id,
      r.place_id,
      r.critical_id,
      r.currency_id,
      r.create_date,
      r."desc",
      r.photo,
      r.escalated,
      r.estimated_value,
      r.plan_date,
      r.close_date,
      r.repair_duration,
      r.is_deleted,
      r.effective_from,
      r.effective_to,
      r.snapshot_date
    FROM dds.tmp_fact_request_rows r;

    WITH
      curr_ids AS (
        SELECT DISTINCT dds.clean_string(id)::int AS request_id
        FROM stage.source_table
        WHERE dds.to_date_safe(insert_dt) = v_snapshot_dt
          AND dds.clean_string(id) ~ '^\d+$'
      )
    UPDATE dds.fact_request f
    SET snapshot_date = v_snapshot_dt
    WHERE f.effective_to = DATE '9999-12-31'
      AND f.is_deleted = FALSE
      AND f.snapshot_date < v_snapshot_dt
      AND EXISTS (
        SELECT 1
        FROM curr_ids c
        WHERE c.request_id = f.request_id
      );
  END LOOP;
END;
$$;

COMMENT ON PROCEDURE dds.load_fact_request()
IS 'Загрузка таблицы фактов dds.fact_request';
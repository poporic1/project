CREATE OR REPLACE PROCEDURE dm.load_fact_metrics()
LANGUAGE plpgsql
AS $$
BEGIN
  -- tmp хранит предыдущую версию факта после swap, поэтому перед расчетом очищаем ее
  TRUNCATE TABLE dm.tmp_fact_metrics RESTART IDENTITY;

  INSERT INTO dm.tmp_fact_metrics (
    month_id,
    place_id,
    total_requests,
    daily_change_closed,
    daily_change_new,
    daily,
    avg_repair_duration_month,
    dashboard_date
  )
  WITH
    snapshot_info AS (
      SELECT MAX(snapshot_date)::date AS dashboard_date
      FROM dds.fact_request
    ),
    max_create_month AS (
      SELECT date_trunc('month', MAX(create_date))::date AS max_month
      FROM dds.fact_request
      WHERE effective_to = DATE '9999-12-31'
    ),
    calendar_months AS (
      SELECT generate_series(
        max_month - INTERVAL '11 months',
        max_month,
        INTERVAL '1 month'
      )::date AS month_start
      FROM max_create_month
      WHERE max_month IS NOT NULL
    ),
    months_with_id AS (
      SELECT
        cm.month_start,
        dm.month_id
      FROM calendar_months cm
      JOIN dm.dim_month dm
        ON dm.month = cm.month_start
    ),
    places AS (
      SELECT DISTINCT place_id
      FROM dm.dim_place_location
    ),
    base AS (
      SELECT
        m.month_start,
        m.month_id,
        p.place_id
      FROM months_with_id m
      CROSS JOIN places p
    ),
    active_current AS (
      SELECT DISTINCT
        fr.request_id,
        fr.place_id
      FROM dds.fact_request fr
      JOIN dds.dim_status ds
        ON ds.status_id = fr.status_id
      WHERE fr.effective_to = DATE '9999-12-31'
        AND ds.status_name IN ('Новая', 'В работе')
    ),
    active_previous AS (
      SELECT DISTINCT
        fr.request_id,
        fr.place_id
      FROM dds.fact_request fr
      JOIN dds.dim_status ds
        ON ds.status_id = fr.status_id
      CROSS JOIN snapshot_info si
      WHERE ds.status_name IN ('Новая', 'В работе')
        AND fr.effective_from <= si.dashboard_date - 1
        AND fr.effective_to > si.dashboard_date - 1
    ),
    total_requests AS (
      SELECT
        place_id,
        COUNT(DISTINCT request_id)::int2 AS total_requests
      FROM active_current
      GROUP BY place_id
    ),
    closed_requests AS (
      SELECT
        ap.request_id,
        ap.place_id
      FROM active_previous ap
      WHERE NOT EXISTS (
        SELECT 1
        FROM active_current ac
        WHERE ac.request_id = ap.request_id
      )
    ),
    new_requests AS (
      SELECT
        ac.request_id,
        ac.place_id
      FROM active_current ac
      WHERE NOT EXISTS (
        SELECT 1
        FROM active_previous ap
        WHERE ap.request_id = ac.request_id
      )
    ),
    stable_active_requests AS (
      SELECT
        ac.request_id,
        ac.place_id
      FROM active_current ac
      WHERE EXISTS (
        SELECT 1
        FROM active_previous ap
        WHERE ap.request_id = ac.request_id
      )
    ),
    daily AS (
      SELECT
        place_id,
        COUNT(DISTINCT request_id)::int2 AS daily
      FROM stable_active_requests
      GROUP BY place_id
    ),
    daily_changes AS (
      SELECT
        p.place_id,
        (-COUNT(DISTINCT cr.request_id))::int2 AS daily_change_closed,
        COUNT(DISTINCT nr.request_id)::int2 AS daily_change_new
      FROM places p
      LEFT JOIN closed_requests cr
        ON cr.place_id = p.place_id
      LEFT JOIN new_requests nr
        ON nr.place_id = p.place_id
      GROUP BY p.place_id
    ),
    avg_duration AS (
      SELECT
        date_trunc('month', fr.close_date)::date AS month_start,
        fr.place_id,
        ROUND(AVG(fr.repair_duration)::numeric, 1) AS avg_repair_duration_month
      FROM dds.fact_request fr
      JOIN dds.dim_status ds
        ON ds.status_id = fr.status_id
      JOIN calendar_months cm
        ON cm.month_start = date_trunc('month', fr.close_date)::date
      WHERE fr.effective_to = DATE '9999-12-31'
        AND fr.close_date IS NOT NULL
        AND fr.repair_duration IS NOT NULL
        AND ds.status_name = 'Устранено'
      GROUP BY
        date_trunc('month', fr.close_date)::date,
        fr.place_id
    )
  SELECT
    b.month_id,
    b.place_id,
    COALESCE(tr.total_requests, 0::int2) AS total_requests,
    COALESCE(dc.daily_change_closed, 0::int2) AS daily_change_closed,
    COALESCE(dc.daily_change_new, 0::int2) AS daily_change_new,
    COALESCE(d.daily, 0::int2) AS daily,
    COALESCE(ad.avg_repair_duration_month, 0::numeric) AS avg_repair_duration_month,
    si.dashboard_date
  FROM base b
  CROSS JOIN snapshot_info si
  LEFT JOIN total_requests tr
    ON tr.place_id = b.place_id
  LEFT JOIN daily_changes dc
    ON dc.place_id = b.place_id
  LEFT JOIN daily d
    ON d.place_id = b.place_id
  LEFT JOIN avg_duration ad
    ON ad.month_start = b.month_start
   AND ad.place_id = b.place_id
  ORDER BY
    b.month_id,
    b.place_id;
END;
$$;

COMMENT ON PROCEDURE dm.load_fact_metrics() IS 'Расчет нового набора данных для dm.fact_metrics в tmp-таблицу';
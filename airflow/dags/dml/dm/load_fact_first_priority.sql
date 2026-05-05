CREATE OR REPLACE PROCEDURE dm.load_fact_first_priority()
LANGUAGE plpgsql
AS $$
BEGIN
  -- tmp хранит предыдущую версию факта после swap, поэтому перед расчетом очищаем ее
  TRUNCATE TABLE dm.tmp_fact_first_priority RESTART IDENTITY;

  INSERT INTO dm.tmp_fact_first_priority (
    status_id,
    place_id,
    responsible_id,
    create_date,
    plan_date,
    description,
    estimated_value_rub,
    estimated_value_usd,
    is_high_priority,
    is_1_day,
    overdue_days
  )
  WITH
    snapshot_info AS (
      SELECT MAX(snapshot_date)::date AS max_snapshot_date
      FROM dds.fact_request
    ),
    usd_rate AS (
      SELECT curr_value / NULLIF(curr_nominal, 0) AS rate_value
      FROM dds.dim_currency
      WHERE curr_code = 'USD'
    ),
    first_priority_requests AS (
      SELECT
        fr.status_id,
        fr.place_id,
        fr.responsible_id,
        fr.create_date::date AS create_date,
        fr.plan_date,
        fr."desc" AS description,
        fr.estimated_value AS estimated_value_rub,
        dc.critical_name,
        si.max_snapshot_date
      FROM dds.fact_request fr
      JOIN dds.dim_status ds
        ON ds.status_id = fr.status_id
      JOIN dds.dim_critical dc
        ON dc.critical_id = fr.critical_id
      CROSS JOIN snapshot_info si
      WHERE fr.effective_to = DATE '9999-12-31'
        AND ds.status_name IN ('Новая', 'В работе')
        AND (
          dc.critical_name = 'Первый приоритет'
          OR fr.plan_date - si.max_snapshot_date = 1
          OR si.max_snapshot_date > fr.plan_date
        )
    )
  SELECT
    r.status_id,
    r.place_id,
    r.responsible_id,
    r.create_date,
    r.plan_date,
    r.description,
    r.estimated_value_rub,
    ROUND(r.estimated_value_rub / NULLIF(u.rate_value, 0), 2) AS estimated_value_usd,
    (r.critical_name = 'Первый приоритет') AS is_high_priority,
    (r.plan_date - r.max_snapshot_date = 1) AS is_1_day,
    CASE
      WHEN r.max_snapshot_date > r.plan_date
        THEN (r.max_snapshot_date - r.plan_date)::int2
      ELSE 0::int2
    END AS overdue_days
  FROM first_priority_requests r
  CROSS JOIN usd_rate u
  ORDER BY
    is_high_priority DESC,
    (r.max_snapshot_date - r.plan_date) DESC,
    is_1_day DESC;
END;
$$;

COMMENT ON PROCEDURE dm.load_fact_first_priority() IS 'Расчет нового набора данных для dm.fact_first_priority в tmp-таблицу';
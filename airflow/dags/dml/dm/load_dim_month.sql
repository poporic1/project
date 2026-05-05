CREATE OR REPLACE PROCEDURE dm.load_dim_month()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm.dim_month;
    INSERT INTO dm.dim_month (month)
    SELECT generate_month::DATE
    FROM (
        SELECT generate_series(
            (SELECT date_trunc('month', MIN(create_date))
             FROM dds.fact_request
             WHERE effective_to = '9999-12-31'::DATE),
            (SELECT date_trunc('month', MIN(create_date))
             FROM dds.fact_request
             WHERE effective_to = '9999-12-31'::DATE) + INTERVAL '35 months',
            INTERVAL '1 month'
        ) AS generate_month
    ) months
    ORDER BY generate_month;
END;
$$;
COMMENT ON PROCEDURE dm.load_dim_month() IS 'Загрузка таблицы справочника месяцев';
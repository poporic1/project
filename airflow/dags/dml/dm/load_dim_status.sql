CREATE OR REPLACE PROCEDURE dm.load_dim_status()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm.dim_status;
    INSERT INTO dm.dim_status (status_id, status_name)
    SELECT status_id, status_name
    FROM dds.dim_status;
END;
$$;
COMMENT ON PROCEDURE dm.load_dim_status() IS 'Загрузка таблицы справочника статусов заявок';
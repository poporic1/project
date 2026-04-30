CREATE OR REPLACE PROCEDURE dds.load_dim_status() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_status (status_name)
SELECT DISTINCT dds.clean_string(status) AS status_name
FROM stage.source_table
WHERE dds.clean_string(status) IS NOT NULL ON CONFLICT (status_name) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_status() IS 'Загрузка таблицы справочника статусов заявок';
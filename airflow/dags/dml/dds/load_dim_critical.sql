CREATE OR REPLACE PROCEDURE dds.load_dim_critical() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_critical (critical_name)
SELECT DISTINCT dds.clean_string(critical) AS critical_name
FROM stage.source_table
WHERE dds.clean_string(critical) IS NOT NULL ON CONFLICT (critical_name) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_critical() IS 'Загрузка таблицы справочника критичности заявок';
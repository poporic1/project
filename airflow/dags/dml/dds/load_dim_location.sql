CREATE OR REPLACE PROCEDURE dds.load_dim_location() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_location (location_name)
SELECT DISTINCT dds.clean_string(location) AS location_name
FROM stage.source_table
WHERE dds.clean_string(location) IS NOT NULL ON CONFLICT (location_name) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_location() IS 'Загрузка таблицы справочника локаций';
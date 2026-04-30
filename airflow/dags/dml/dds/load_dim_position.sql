CREATE OR REPLACE PROCEDURE dds.load_dim_position() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_position (position_name)
SELECT DISTINCT position_name
FROM (
    SELECT dds.clean_string(author_position) AS position_name
    FROM stage.source_table
    UNION
    SELECT dds.clean_string(responsible_position) AS position_name
    FROM stage.source_table
  ) src
WHERE position_name IS NOT NULL ON CONFLICT (position_name) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_position() IS 'Загрузка таблицы справочника должностей';
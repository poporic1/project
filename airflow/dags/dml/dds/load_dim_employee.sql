CREATE OR REPLACE PROCEDURE dds.load_dim_employee() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_employee (
    empl_id,
    empl_name,
    position_id
  )
SELECT DISTINCT e.empl_id,
  e.empl_name,
  p.position_id
FROM (
    SELECT CASE
        WHEN dds.clean_string(author_id) ~ '^\d+$' THEN dds.clean_string(author_id)::int4
        ELSE NULL
      END AS empl_id,
      dds.clean_string(author_nm) AS empl_name,
      dds.clean_string(author_position) AS position_name
    FROM stage.source_table
    UNION
    SELECT CASE
        WHEN dds.clean_string(responsible_id) ~ '^\d+$' THEN dds.clean_string(responsible_id)::int4
        ELSE NULL
      END AS empl_id,
      dds.clean_string(responsible_nm) AS empl_name,
      dds.clean_string(responsible_position) AS position_name
    FROM stage.source_table
  ) e
  JOIN dds.dim_position p ON p.position_name = e.position_name
WHERE e.empl_id IS NOT NULL
  AND e.empl_name IS NOT NULL
  AND e.position_name IS NOT NULL ON CONFLICT (empl_id) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_employee() IS 'Загрузка таблицы справочника сотрудников';
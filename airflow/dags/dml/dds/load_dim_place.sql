CREATE OR REPLACE PROCEDURE dds.load_dim_place() LANGUAGE plpgsql AS $$ BEGIN
INSERT INTO dds.dim_place (location_id, place_name)
SELECT DISTINCT dl.location_id,
  pl.place_name
FROM (
    SELECT dds.clean_string(place) AS place_name,
      dds.clean_string(location) AS location_name
    FROM stage.source_table
  ) pl
  JOIN dds.dim_location dl ON dl.location_name = pl.location_name
WHERE pl.place_name IS NOT NULL
  AND pl.location_name IS NOT NULL ON CONFLICT (location_id, place_name) DO NOTHING;
END;
$$;
COMMENT ON PROCEDURE dds.load_dim_place() IS 'Загрузка таблицы справочника мест';
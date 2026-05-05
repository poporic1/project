CREATE OR REPLACE PROCEDURE dm.load_dim_place_location()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm.dim_place_location;
    INSERT INTO dm.dim_place_location (place_id, place_name, location_name)
    SELECT
        p.place_id,
        p.place_name,
        l.location_name
    FROM dds.dim_place p
    JOIN dds.dim_location l ON p.location_id = l.location_id
    WHERE EXISTS (
        SELECT 1
        FROM dds.dim_place p2
        WHERE p2.location_id = l.location_id
    );
END;
$$;
COMMENT ON PROCEDURE dm.load_dim_place_location() IS 'Загрузка таблицы справочника мест и локаций';
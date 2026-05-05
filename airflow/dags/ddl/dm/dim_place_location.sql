CREATE TABLE IF NOT EXISTS dm.dim_place_location (
    place_id      INT4 PRIMARY KEY,
    place_name    VARCHAR(40),
    location_name VARCHAR(20)
);

COMMENT ON TABLE dm.dim_place_location IS 'Справочник мест и локаций';
COMMENT ON COLUMN dm.dim_place_location.place_id IS 'Уникальный идентификатор места и локации в связке';
COMMENT ON COLUMN dm.dim_place_location.place_name IS 'Название места';
COMMENT ON COLUMN dm.dim_place_location.location_name IS 'Название локации';
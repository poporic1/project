CREATE TABLE IF NOT EXISTS dds.dim_place (
    place_id SERIAL PRIMARY KEY,
    location_id INT4 NOT NULL,
    place_name VARCHAR(40) NOT NULL,
    UNIQUE (location_id, place_name),
    FOREIGN KEY (location_id) REFERENCES dds.dim_location(location_id)
);
COMMENT ON TABLE dds.dim_place IS 'Справочник мест';
COMMENT ON COLUMN dds.dim_place.place_id IS 'Уникальный идентификатор места';
COMMENT ON COLUMN dds.dim_place.location_id IS 'Уникальный идентификатор локации';
COMMENT ON COLUMN dds.dim_place.place_name IS 'Конкретное местоположение внутри локации';
CREATE TABLE IF NOT EXISTS dds.dim_location (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(20) NOT NULL UNIQUE
);
COMMENT ON TABLE dds.dim_location IS 'Справочник локаций';
COMMENT ON COLUMN dds.dim_location.location_id IS 'Уникальный идентификатор локации';
COMMENT ON COLUMN dds.dim_location.location_name IS 'Укрупненное местоположение проблемы';
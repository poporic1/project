CREATE TABLE IF NOT EXISTS dds.dim_position (
    position_id SERIAL PRIMARY KEY,
    position_name VARCHAR(30) NOT NULL UNIQUE
);
COMMENT ON TABLE dds.dim_position IS 'Справочник должностей';
COMMENT ON COLUMN dds.dim_position.position_id IS 'Уникальный идентификатор должности';
COMMENT ON COLUMN dds.dim_position.position_name IS 'Должность';
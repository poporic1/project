CREATE TABLE IF NOT EXISTS dds.dim_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(15) NOT NULL UNIQUE
);
COMMENT ON TABLE dds.dim_status IS 'Справочник статусов заявок';
COMMENT ON COLUMN dds.dim_status.status_id IS 'Уникальный идентификатор статуса';
COMMENT ON COLUMN dds.dim_status.status_name IS 'Статус заявки';
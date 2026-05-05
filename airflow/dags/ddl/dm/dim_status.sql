CREATE TABLE IF NOT EXISTS dm.dim_status (
    status_id   INT4 PRIMARY KEY,
    status_name VARCHAR(15)
);

COMMENT ON TABLE dm.dim_status IS 'Справочник статусов заявок';
COMMENT ON COLUMN dm.dim_status.status_id IS 'Уникальный идентификатор статуса заявки';
COMMENT ON COLUMN dm.dim_status.status_name IS 'Название статуса заявки';
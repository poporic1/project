CREATE TABLE IF NOT EXISTS dds.dim_critical (
    critical_id SERIAL PRIMARY KEY,
    critical_name VARCHAR(20) NOT NULL UNIQUE
);
COMMENT ON TABLE dds.dim_critical IS 'Справочник статусов критичности';
COMMENT ON COLUMN dds.dim_critical.critical_id IS 'Уникальный идентификатор оценки критичности';
COMMENT ON COLUMN dds.dim_critical.critical_name IS 'Оценка критичности заявки';
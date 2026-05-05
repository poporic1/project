CREATE TABLE IF NOT EXISTS dm.dim_month (
    month_id SERIAL PRIMARY KEY,
    month    DATE NOT NULL
);

COMMENT ON TABLE dm.dim_month IS 'Справочник месяцев';
COMMENT ON COLUMN dm.dim_month.month_id IS 'Уникальный идентификатор месяца и года в связке';
COMMENT ON COLUMN dm.dim_month.month IS 'Месяц и год в связке для агрегации метрик';
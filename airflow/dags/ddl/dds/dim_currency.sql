CREATE TABLE IF NOT EXISTS dds.dim_currency (
    currency_id SERIAL PRIMARY KEY,
    curr_code VARCHAR(3) NOT NULL UNIQUE,
    curr_name VARCHAR(40) NOT NULL UNIQUE,
    curr_value NUMERIC(12, 2) NOT NULL,
    curr_nominal INT4 NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);
COMMENT ON TABLE dds.dim_currency IS 'Справочник валют';
COMMENT ON COLUMN dds.dim_currency.currency_id IS 'Уникальный идентификатор валюты';
COMMENT ON COLUMN dds.dim_currency.curr_code IS 'Код валюты';
COMMENT ON COLUMN dds.dim_currency.curr_name IS 'Название валюты';
COMMENT ON COLUMN dds.dim_currency.curr_value IS 'Курс валюты в рублях';
COMMENT ON COLUMN dds.dim_currency.curr_nominal IS 'Номинал валюты';
COMMENT ON COLUMN dds.dim_currency.updated_at IS 'Время обновления курса';
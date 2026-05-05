CREATE TABLE IF NOT EXISTS dm.tmp_fact_metrics (
    metrics_id                SERIAL PRIMARY KEY,
    month_id                  INT4,
    place_id                  INT4,
    total_requests            INT2,
    daily_change_closed       INT2,
    daily_change_new          INT2,
    daily                     INT2,
    avg_repair_duration_month NUMERIC(5,1),
    dashboard_date            DATE,
    UNIQUE (month_id, place_id)
);

COMMENT ON TABLE dm.tmp_fact_metrics IS 'Tmp-таблица для подготовки нового набора данных dm.fact_metrics';
COMMENT ON COLUMN dm.tmp_fact_metrics.metrics_id IS 'Уникальный идентификатор метрик';
COMMENT ON COLUMN dm.tmp_fact_metrics.month_id IS 'Уникальный идентификатор месяца и года в связке';
COMMENT ON COLUMN dm.tmp_fact_metrics.place_id IS 'Уникальный идентификатор места и локации в связке';
COMMENT ON COLUMN dm.tmp_fact_metrics.total_requests IS 'Общее количество заявок со статусом «В работе» или «Новая»';
COMMENT ON COLUMN dm.tmp_fact_metrics.daily_change_closed IS 'Количество закрытых заявок со статусом «В работе» или «Новая»';
COMMENT ON COLUMN dm.tmp_fact_metrics.daily_change_new IS 'Количество новых заявок со статусом «В работе» или «Новая»';
COMMENT ON COLUMN dm.tmp_fact_metrics.daily IS 'Количество активных заявок со статусом «В работе» или «Новая»';
COMMENT ON COLUMN dm.tmp_fact_metrics.avg_repair_duration_month IS 'Среднее время устранения проблемы за месяц (в днях)';
COMMENT ON COLUMN dm.tmp_fact_metrics.dashboard_date IS 'Дата, на которую данные на дашборде актуальны';

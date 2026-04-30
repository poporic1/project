CREATE TABLE IF NOT EXISTS dds.fact_request (
    fact_request_id SERIAL PRIMARY KEY,
    request_id INT4 NOT NULL,
    author_id INT4 NOT NULL,
    responsible_id INT4 NOT NULL,
    status_id INT4 NOT NULL,
    place_id INT4 NOT NULL,
    critical_id INT4 NOT NULL,
    currency_id INT4 NOT NULL,
    create_date TIMESTAMP NOT NULL,
    "desc" VARCHAR(50),
    photo BOOLEAN,
    escalated BOOLEAN,
    estimated_value NUMERIC(12, 2),
    plan_date DATE,
    close_date DATE,
    repair_duration INT2,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    snapshot_date DATE NOT NULL,
    FOREIGN KEY (author_id) REFERENCES dds.dim_employee(empl_id),
    FOREIGN KEY (responsible_id) REFERENCES dds.dim_employee(empl_id),
    FOREIGN KEY (status_id) REFERENCES dds.dim_status(status_id),
    FOREIGN KEY (place_id) REFERENCES dds.dim_place(place_id),
    FOREIGN KEY (critical_id) REFERENCES dds.dim_critical(critical_id),
    FOREIGN KEY (currency_id) REFERENCES dds.dim_currency(currency_id)
);
COMMENT ON TABLE dds.fact_request IS 'Основная таблица фактов';
COMMENT ON COLUMN dds.fact_request.fact_request_id IS 'Первичный ключ fact_request';
COMMENT ON COLUMN dds.fact_request.request_id IS 'Идентификатор заявки';
COMMENT ON COLUMN dds.fact_request.author_id IS 'Уникальный идентификатор сотрудника, создавшего заявку';
COMMENT ON COLUMN dds.fact_request.responsible_id IS 'Уникальный идентификатор сотрудника, отвественного за решение проблемы';
COMMENT ON COLUMN dds.fact_request.status_id IS 'Уникальный идентификатор статуса';
COMMENT ON COLUMN dds.fact_request.place_id IS 'Уникальный идентификатор места';
COMMENT ON COLUMN dds.fact_request.critical_id IS 'Уникальный идентификатор оценки критичности';
COMMENT ON COLUMN dds.fact_request.currency_id IS 'Уникальный идентификатор стоимости устранения проблемы';
COMMENT ON COLUMN dds.fact_request.create_date IS 'Дата и время создания заявки';
COMMENT ON COLUMN dds.fact_request."desc" IS 'Описание проблемы';
COMMENT ON COLUMN dds.fact_request.photo IS 'Индикатор: приложено ли фото при создании заявки';
COMMENT ON COLUMN dds.fact_request.escalated IS 'Индикатор: обострилась ли проблема';
COMMENT ON COLUMN dds.fact_request.estimated_value IS 'Стоимость устранения проблемы';
COMMENT ON COLUMN dds.fact_request.plan_date IS 'Плановая дата устранения проблемы';
COMMENT ON COLUMN dds.fact_request.close_date IS 'Дата закрытия заявки';
COMMENT ON COLUMN dds.fact_request.repair_duration IS 'Время устранения проблемы (в днях)';
COMMENT ON COLUMN dds.fact_request.is_deleted IS 'Индикатор: удалена ли запись';
COMMENT ON COLUMN dds.fact_request.effective_from IS 'Дата начала действия записи';
COMMENT ON COLUMN dds.fact_request.effective_to IS 'Дата окончания действия записи';
COMMENT ON COLUMN dds.fact_request.snapshot_date IS 'Дата снапшота';
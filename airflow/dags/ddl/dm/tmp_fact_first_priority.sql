CREATE TABLE IF NOT EXISTS dm.tmp_fact_first_priority (
    first_priority_id   SERIAL PRIMARY KEY,
    status_id           INT4,
    place_id            INT4,
    responsible_id      INT4,
    create_date         DATE,
    plan_date           DATE,
    description         VARCHAR(50),
    estimated_value_rub NUMERIC(12,2),
    estimated_value_usd NUMERIC(12,2),
    is_high_priority    BOOLEAN,
    is_1_day            BOOLEAN,
    overdue_days        INT2
);

COMMENT ON TABLE dm.tmp_fact_first_priority IS 'Временная-таблица для подготовки нового набора данных dm.fact_first_priority';
COMMENT ON COLUMN dm.tmp_fact_first_priority.first_priority_id IS 'Уникальный идентификатор записей в таблице с "Первым приоритетом"';
COMMENT ON COLUMN dm.tmp_fact_first_priority.status_id IS 'Уникальный идентификатор статуса заявки';
COMMENT ON COLUMN dm.tmp_fact_first_priority.place_id IS 'Уникальный идентификатор места';
COMMENT ON COLUMN dm.tmp_fact_first_priority.responsible_id IS 'Идентификатор сотрудника, ответственного за устранение проблемы';
COMMENT ON COLUMN dm.tmp_fact_first_priority.create_date IS 'Дата создания заявки';
COMMENT ON COLUMN dm.tmp_fact_first_priority.plan_date IS 'Плановая дата закрытия заявки';
COMMENT ON COLUMN dm.tmp_fact_first_priority.description IS 'Описание проблемы';
COMMENT ON COLUMN dm.tmp_fact_first_priority.estimated_value_rub IS 'Стоимость устранения проблемы в рублях';
COMMENT ON COLUMN dm.tmp_fact_first_priority.estimated_value_usd IS 'Стоимость устранения проблемы в долларах';
COMMENT ON COLUMN dm.tmp_fact_first_priority.is_high_priority IS 'Индикатор: нужно ли быстро закрыть заявку (критичность — «Первый приоритет»)';
COMMENT ON COLUMN dm.tmp_fact_first_priority.is_1_day IS 'Индикатор: остался ли 1 день до плановой даты';
COMMENT ON COLUMN dm.tmp_fact_first_priority.overdue_days IS 'Количество дней, на которые просрочена заявка';

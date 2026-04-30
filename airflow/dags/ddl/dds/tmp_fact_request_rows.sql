CREATE TABLE IF NOT EXISTS dds.tmp_fact_request_rows (
  active_fact_request_id int4,
  request_id int4 NOT NULL,
  author_id int4 NOT NULL,
  responsible_id int4 NOT NULL,
  status_id int4 NOT NULL,
  place_id int4 NOT NULL,
  critical_id int4 NOT NULL,
  currency_id int4 NOT NULL,
  create_date timestamp NOT NULL,
  "desc" varchar(50),
  photo boolean,
  escalated boolean,
  estimated_value numeric(12, 2),
  plan_date date,
  close_date date,
  repair_duration int2,
  is_deleted boolean NOT NULL,
  effective_from date NOT NULL,
  effective_to date NOT NULL,
  snapshot_date date NOT NULL
);

COMMENT ON TABLE dds.tmp_fact_request_rows IS 'Временная таблица для подготовки новых и измененных заявок перед загрузкой в dds.fact_request';

COMMENT ON COLUMN dds.tmp_fact_request_rows.active_fact_request_id IS 'Идентификатор активной версии заявки в dds.fact_request';
COMMENT ON COLUMN dds.tmp_fact_request_rows.request_id IS 'Идентификатор заявки';
COMMENT ON COLUMN dds.tmp_fact_request_rows.author_id IS 'Идентификатор сотрудника, создавшего заявку';
COMMENT ON COLUMN dds.tmp_fact_request_rows.responsible_id IS 'Идентификатор сотрудника, ответственного за решение проблемы';
COMMENT ON COLUMN dds.tmp_fact_request_rows.status_id IS 'Идентификатор статуса заявки';
COMMENT ON COLUMN dds.tmp_fact_request_rows.place_id IS 'Идентификатор места';
COMMENT ON COLUMN dds.tmp_fact_request_rows.critical_id IS 'Идентификатор оценки критичности';
COMMENT ON COLUMN dds.tmp_fact_request_rows.currency_id IS 'Идентификатор валюты';
COMMENT ON COLUMN dds.tmp_fact_request_rows.create_date IS 'Дата и время создания заявки';
COMMENT ON COLUMN dds.tmp_fact_request_rows."desc" IS 'Описание проблемы';
COMMENT ON COLUMN dds.tmp_fact_request_rows.photo IS 'Индикатор: приложено ли фото при создании заявки';
COMMENT ON COLUMN dds.tmp_fact_request_rows.escalated IS 'Индикатор: обострилась ли проблема';
COMMENT ON COLUMN dds.tmp_fact_request_rows.estimated_value IS 'Стоимость устранения проблемы';
COMMENT ON COLUMN dds.tmp_fact_request_rows.plan_date IS 'Плановая дата устранения проблемы';
COMMENT ON COLUMN dds.tmp_fact_request_rows.close_date IS 'Дата закрытия заявки';
COMMENT ON COLUMN dds.tmp_fact_request_rows.repair_duration IS 'Время устранения проблемы (в днях)';
COMMENT ON COLUMN dds.tmp_fact_request_rows.is_deleted IS 'Индикатор: удалена ли запись';
COMMENT ON COLUMN dds.tmp_fact_request_rows.effective_from IS 'Дата начала действия записи';
COMMENT ON COLUMN dds.tmp_fact_request_rows.effective_to IS 'Дата окончания действия записи';
COMMENT ON COLUMN dds.tmp_fact_request_rows.snapshot_date IS 'Дата снапшота';
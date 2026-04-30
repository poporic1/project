CREATE TABLE IF NOT EXISTS dds.reject_fact_request (
  id text,
  "desc" text,
  create_date text,
  plan_date text,
  location text,
  place text,
  author_id text,
  author_nm text,
  author_position text,
  responsible_id text,
  responsible_nm text,
  responsible_position text,
  status text,
  close_date text,
  estimated_value text,
  critical text,
  photo text,
  escalated text,
  insert_dt text,
  created_at timestamp NOT NULL DEFAULT now()
);

COMMENT ON TABLE dds.reject_fact_request
IS 'Некорректные строки из stage.source_table, которые не попали в dds.fact_request';

COMMENT ON COLUMN dds.reject_fact_request.id IS 'Идентификатор заявки';
COMMENT ON COLUMN dds.reject_fact_request."desc" IS 'Описание проблемы';
COMMENT ON COLUMN dds.reject_fact_request.create_date IS 'Дата и время создания заявки';
COMMENT ON COLUMN dds.reject_fact_request.plan_date IS 'Плановая дата устранения проблемы';
COMMENT ON COLUMN dds.reject_fact_request.location IS 'Укрупненное местоположение проблемы';
COMMENT ON COLUMN dds.reject_fact_request.place IS 'Конкретное местоположение внутри локации';
COMMENT ON COLUMN dds.reject_fact_request.author_id IS 'Идентификатор сотрудника, создавшего заявку';
COMMENT ON COLUMN dds.reject_fact_request.author_nm IS 'Фамилия и инициалы сотрудника, создавшего заявку';
COMMENT ON COLUMN dds.reject_fact_request.author_position IS 'Должность сотрудника, создавшего заявку';
COMMENT ON COLUMN dds.reject_fact_request.responsible_id IS 'Идентификатор сотрудника, ответственного за решение проблемы';
COMMENT ON COLUMN dds.reject_fact_request.responsible_nm IS 'Фамилия и инициалы сотрудника, ответственного за решение проблемы';
COMMENT ON COLUMN dds.reject_fact_request.responsible_position IS 'Должность сотрудника, ответственного за решение проблемы';
COMMENT ON COLUMN dds.reject_fact_request.status IS 'Статус заявки';
COMMENT ON COLUMN dds.reject_fact_request.close_date IS 'Дата закрытия заявки';
COMMENT ON COLUMN dds.reject_fact_request.estimated_value IS 'Стоимость устранения проблемы';
COMMENT ON COLUMN dds.reject_fact_request.critical IS 'Оценка критичности заявки';
COMMENT ON COLUMN dds.reject_fact_request.photo IS 'Индикатор: приложено ли фото при создании заявки';
COMMENT ON COLUMN dds.reject_fact_request.escalated IS 'Индикатор: обострилась ли проблема';
COMMENT ON COLUMN dds.reject_fact_request.insert_dt IS 'Дата снапшота';
COMMENT ON COLUMN dds.reject_fact_request.created_at IS 'Дата и время фиксации некорректной строки';
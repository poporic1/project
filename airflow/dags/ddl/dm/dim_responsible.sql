CREATE TABLE IF NOT EXISTS dm.dim_responsible (
    responsible_id           INT4 PRIMARY KEY,
    responsible_name_position VARCHAR(60)
);

COMMENT ON TABLE dm.dim_responsible IS 'Справочник сотрудников, отвественных за закрытие заявки';
COMMENT ON COLUMN dm.dim_responsible.responsible_id IS 'Уникальный идентификатор сотрудника, ответственного за устранение проблемы';
COMMENT ON COLUMN dm.dim_responsible.responsible_name_position IS 'Фамилия и инициалы и должность сотрудника, ответстсвнного за устранение проблемы';
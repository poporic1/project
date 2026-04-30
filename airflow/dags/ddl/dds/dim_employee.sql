CREATE TABLE IF NOT EXISTS dds.dim_employee (
    empl_id INT4 PRIMARY KEY,
    position_id INT4 NOT NULL,
    empl_name VARCHAR(25) NOT NULL,
    FOREIGN KEY (position_id) REFERENCES dds.dim_position(position_id)
);
COMMENT ON TABLE dds.dim_employee IS 'Справочник сотрудников';
COMMENT ON COLUMN dds.dim_employee.position_id IS 'Уникальный идентификатор должности';
COMMENT ON COLUMN dds.dim_employee.empl_id IS 'Уникальный идентификатор сотрудника';
COMMENT ON COLUMN dds.dim_employee.empl_name IS 'Фамилия и инициалы сотрудника';
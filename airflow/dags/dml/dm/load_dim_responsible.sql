CREATE OR REPLACE PROCEDURE dm.load_dim_responsible()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm.dim_responsible;
    INSERT INTO dm.dim_responsible (responsible_id, responsible_name_position)
    SELECT
        e.empl_id,
        e.empl_name || ', ' || pos.position_name AS responsible_name_position
    FROM dds.dim_employee e
    JOIN dds.dim_position pos ON e.position_id = pos.position_id
    WHERE e.empl_id IN (
        SELECT DISTINCT responsible_id
        FROM dds.fact_request
        WHERE responsible_id IS NOT NULL
    );
END;
$$;
COMMENT ON PROCEDURE dm.load_dim_responsible() IS 'Загрузка таблицы справочника сотрудников, ответственных за закрытие заявки';
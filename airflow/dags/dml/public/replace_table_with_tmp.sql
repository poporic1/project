CREATE OR REPLACE PROCEDURE public.replace_table_with_tmp(
  p_schema_name text,
  p_target_table_name text,
  p_tmp_table_name text
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_swap_table_name text;
BEGIN
  v_swap_table_name := p_target_table_name || '_swap';

  -- удаление служебной таблицы, если она осталась после нештатного запуска
  EXECUTE format(
    'DROP TABLE IF EXISTS %I.%I',
    p_schema_name,
    v_swap_table_name
  );

  -- переименование текущей целевой таблицы во временное служебное имя
  EXECUTE format(
    'ALTER TABLE %I.%I RENAME TO %I',
    p_schema_name,
    p_target_table_name,
    v_swap_table_name
  );

  -- переименование tmp-таблицы в имя целевой таблицы
  EXECUTE format(
    'ALTER TABLE %I.%I RENAME TO %I',
    p_schema_name,
    p_tmp_table_name,
    p_target_table_name
  );

  -- сохранение предыдущей версии данных в tmp-таблицу
  EXECUTE format(
    'ALTER TABLE %I.%I RENAME TO %I',
    p_schema_name,
    v_swap_table_name,
    p_tmp_table_name
  );
END;
$$;

COMMENT ON PROCEDURE public.replace_table_with_tmp(text, text, text) IS 'Замена целевой таблицы tmp-таблицей с сохранением предыдущей версии данных в tmp-таблице';
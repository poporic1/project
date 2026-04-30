CREATE OR REPLACE FUNCTION dds.clean_string(input TEXT) RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE result TEXT;
BEGIN IF input IS NULL THEN RETURN NULL;
END IF;
result := REGEXP_REPLACE(input, '<[^>]*>', '', 'gi');
result := REGEXP_REPLACE(result, '&nbsp;?', '', 'g');
result := REPLACE(result, E'\u00B6', '');
result := REPLACE(result, E'\u00A0', ' ');
result := TRIM(result);
RETURN NULLIF(result, '');
END;
$$;
COMMENT ON FUNCTION dds.clean_string IS 'Функция для преобразования текста в нужный формат';
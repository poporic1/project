CREATE OR REPLACE FUNCTION dds.to_date_safe(input TEXT) RETURNS DATE LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE cleaned TEXT;
result DATE;
formats TEXT [] := ARRAY [
        'DD/MM/YYYY', 'DD.MM.YYYY', 'DD-MM-YYYY',
        'MM/DD/YYYY', 'MM.DD.YYYY', 'MM-DD-YYYY',
        'DD/MM/YY',   'DD.MM.YY',   'DD-MM-YY',
        'MM/DD/YY',   'MM.DD.YY',   'MM-DD-YY',
        'YYYY-MM-DD', 'YYYY.MM.DD', 'YYYY/MM/DD'
    ];
fmt TEXT;
BEGIN IF input IS NULL
OR TRIM(input) = '' THEN RETURN NULL;
END IF;
cleaned := dds.clean_string(input);
IF cleaned IS NULL THEN RETURN NULL;
END IF;
cleaned := SPLIT_PART(cleaned, ' ', 1);
FOREACH fmt IN ARRAY formats LOOP BEGIN result := TO_DATE(cleaned, fmt);
RETURN result;
EXCEPTION
WHEN OTHERS THEN NULL;
END;
END LOOP;
RETURN NULL;
END;
$$;
COMMENT ON FUNCTION dds.to_date_safe IS 'Функция для преобразования дат в нужный формат';
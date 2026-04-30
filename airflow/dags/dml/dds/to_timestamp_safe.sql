CREATE OR REPLACE FUNCTION dds.to_timestamp_safe(input TEXT) RETURNS TIMESTAMP LANGUAGE plpgsql IMMUTABLE AS $func$
DECLARE cleaned TEXT;
result TIMESTAMP;
formats TEXT [] := ARRAY [
        'DD/MM/YY HH24:MI',
        'DD/MM/YYYY HH24:MI',
        'DD/MM/YY HH24:MI:SS',
        'DD/MM/YYYY HH24:MI:SS',

        'DD.MM.YY HH24:MI',
        'DD.MM.YYYY HH24:MI',
        'DD.MM.YY HH24:MI:SS',
        'DD.MM.YYYY HH24:MI:SS',

        'YYYY-MM-DD HH24:MI:SS',
        'YYYY-MM-DD HH24:MI'
    ];
fmt TEXT;
BEGIN IF input IS NULL
OR TRIM(input) = '' THEN RETURN NULL;
END IF;
cleaned := dds.clean_string(input);
IF cleaned IS NULL THEN RETURN NULL;
END IF;
cleaned := REPLACE(cleaned, 'T', ' ');
cleaned := REPLACE(cleaned, 'Т', ' ');
cleaned := REGEXP_REPLACE(cleaned, '\s+', ' ', 'g');
cleaned := TRIM(cleaned);
cleaned := REGEXP_REPLACE(cleaned, '\.\d+', '');
FOREACH fmt IN ARRAY formats LOOP BEGIN result := TO_TIMESTAMP(cleaned, fmt);
IF EXTRACT(
    YEAR
    FROM result
) BETWEEN 1900 AND 2100 THEN RETURN result;
END IF;
EXCEPTION
WHEN OTHERS THEN NULL;
END;
END LOOP;
RETURN NULL;
END;
$func$;
COMMENT ON FUNCTION dds.to_date_safe IS 'Функция для преобразования дат
 со временем в нужный формат';
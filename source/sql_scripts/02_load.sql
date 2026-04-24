-- Загрузка данных из CSV-файлов
COPY source_data.source_table FROM '/csv/tab_2025_06_29.csv' DELIMITER ',' CSV HEADER;
COPY source_data.source_table FROM '/csv/tab_2025_06_30.csv' DELIMITER ',' CSV HEADER;
COPY source_data.source_table FROM '/csv/tab_2025_07_30.csv' DELIMITER ',' CSV HEADER;
COPY source_data.source_table FROM '/csv/tab_2025_07_31.csv' DELIMITER ',' CSV HEADER;

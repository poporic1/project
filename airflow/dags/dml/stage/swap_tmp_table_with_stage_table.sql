-- Старую боевую таблицу временно убираем в сторону.
drop table if exists stage.source_table_old;

alter table stage.source_table rename to source_table_old;

-- Публикуем новый полный набор данных.
alter table stage.tmp_source_table rename to source_table;

-- Старая таблица больше не нужна.
drop table stage.source_table_old;

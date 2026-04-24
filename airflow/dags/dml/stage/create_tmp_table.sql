-- На всякий случай убираем tmp-таблицу от прошлого запуска.
drop table if exists stage.tmp_source_table;

-- Создаем новую tmp-таблицу с такой же структурой, как у боевой stage-таблицы.
create table stage.tmp_source_table
(
  like stage.source_table including all
);

comment on table stage.tmp_source_table is
  'Промежуточная таблица для полной перегрузки stage.source_table.';

-- =====================================================================
-- Итоговый расчет. Приближенный метеобюллетень (ДМК / ВР)
-- Состав скрипта:
--   0. Подготовка (объекты, которые ожидает учебный скрипт; очистка для повторного запуска)
--   1. Учебный скрипт 20261102.sql (без изменений, кроме строки OWNER TO admin - см. ниже)
--   2. Корректировки: заголовки в отдельной таблице, изменение справочника типов,
--      исправление данных (Таблица 2, Таблица 3)
--   3. Входной тип и функция расчета fn_calc_meteo_approx
-- Тип оборудования: 1 = ДМК, 2 = ВР (как в calc_correction_types.measurment_equipment_id)
-- =====================================================================


-- =====================================================================
-- 0. ПОДГОТОВКА
-- =====================================================================

-- 0.1 Очистка объектов итогового расчета (для повторного запуска)
drop function if exists public.fn_calc_meteo_approx(public.calc_input_params, integer);
drop type     if exists public.calc_input_params;
drop table    if exists public.calc_correction;
drop table    if exists public.calc_correction_types;
drop table    if exists public.calc_correction_headers;
drop table    if exists public.calc_correction_heights;
drop sequence if exists public.calc_correction_seq;
drop sequence if exists public.calc_correction_types_seq;
drop sequence if exists public.calc_correction_header_seq;
drop sequence if exists public.calc_correction_height_seq;

-- 0.2 Объекты, на которые ссылается учебный скрипт (в рабочей БД они уже есть,
--     создаются только если отсутствуют)
do $env$
begin
    if not exists (select 1 from pg_type where typname = 'interpolation_type') then
        create type public.interpolation_type as (x0 numeric, y0 numeric, x1 numeric, y1 numeric);
    end if;

    if not exists (select 1 from pg_proc where proname = 'fn_calc_interpolation') then
        create function public.fn_calc_interpolation(par_x numeric, par_i public.interpolation_type)
        returns numeric
        language sql immutable
        as $f$
            select case when (par_i).x1 = (par_i).x0 then (par_i).y0
                        else (par_i).y0 + (par_x - (par_i).x0) * ((par_i).y1 - (par_i).y0) / ((par_i).x1 - (par_i).x0)
                   end
        $f$;
    end if;

    if to_regclass('public.calc_temperature_correction') is null then
        if to_regclass('public.calc_correction_temperature') is not null then
            -- повторный запуск: возвращаем исходное имя, учебный скрипт переименует снова
            alter table public.calc_correction_temperature rename to calc_temperature_correction;
        else
            -- Таблица 1 (виртуальная поправка)
            create table public.calc_temperature_correction
            (
                temperature numeric(8,2) not null,
                correction  numeric(8,2) not null
            );
            insert into public.calc_temperature_correction(temperature, correction)
            values (-58, 0), (0, 0), (5, 0.5), (10, 1), (15, 1), (20, 1.5), (25, 2), (30, 3.5), (40, 4.5), (58, 4.5);
        end if;
    end if;
end
$env$;


-- =====================================================================
-- 1. УЧЕБНЫЙ СКРИПТ 20261102.sql
-- =====================================================================
-- Домашняя работа от 2026-11-02
do $$
begin

	-- Создаем новые структуры
	begin
		
		-- Таблица стандартных высот
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
		        id integer primary key not null default nextval('public.calc_correction_height_seq'),
		        height integer not null
		);
		
		
		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);
	
		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';
	
		-- Справочник типов таблиц корректировок
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
		        id integer not null primary key default nextval('public.calc_correction_types_seq'),
		        parent_id integer,
		        measurment_equipment_id integer,
		        description text not null,
		        header_values integer[]
		);
	
		comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
		comment on column calc_correction_types.description is 'Описание к таблице';
		comment on column calc_correction_types.header_values is 'Значения в заголовке таблице';

		-- Универсальная таблица корректировок
		create sequence calc_correction_seq;
		create table calc_correction
		(
		        id integer not null primary key default nextval('public.calc_correction_seq'),
		        height_id integer not null,
		        type_id integer not null,
		        row_values integer[]
		);

		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками';

	end;	

	-- Добавляем данные
	begin

		
		insert into calc_correction_types(  description, header_values)
		values( 'Таблица 2', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 10, 20, 30, 40, 50]),  -- 1
		( 'Таблица 3, скорость среднего ветра', null), -- 2
		( 'Таблица 3, направление среднего ветра', null);       -- 3

		insert into calc_correction_types( description, parent_id, measurment_equipment_id, header_values)
		values
		('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 4
		('Таблица 3, Направление среднего ветра (ВР)',3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 5
		('Таблица 3, Скорость среднего ветра (ДМК)',2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 6
		('Таблица 3, Направление среднего ветра (ДМК)',3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); -- 7
		
		insert into calc_correction_types( description, parent_id)
		values('Таблица 2, Положительные температуры', 1 ), -- 8
		('Таблица 2, Отрицательные температуры', 1 ) --9
		;

		
		insert into calc_correction(height_id, type_id, row_values )
		-- Таблица 2, отрицптельные значения
		values(1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
		(2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]), -- 400
		(3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
		(4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
		-- Таблица 2, положитеьные значения
		(1, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
		(2, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
		(3, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
		(4, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
		-- Таблица 3, Скорость среднего ветра (ВР)
		(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
		(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15]), -- 400
		(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 ,16]), -- 800
		(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15 ,15, 16]), -- 1200
		-- Таблица 3, Направление среднего ветра (ВР)
		(1, 5, array[0]), -- 200
		(2, 5, array[1]), -- 400
		(3, 5, array[2]), -- 800
		(4, 5, array[2]), -- 1200
		-- Таблица 3,Скорость среднего ветра (ДМК)
		(1, 6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]), -- 200
		(2, 6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]), -- 400
		(3, 6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]), -- 800
		(4, 6, array[5,8,11,12,13,16,19,20,23,24,26,28,30]), -- 1200
		-- 'Таблица 3, Направление среднего ветра (ДМК)
		(1, 7, array[1]), -- 200
		(2, 7, array[2]), -- 400
		(3, 7, array[3]), -- 800
		(4, 7, array[3]) -- 1200
		;
		
	end;

	-- Прочее
	begin
		-- Наименование подправлю
		alter table public.calc_temperature_correction rename to calc_correction_temperature;
		
				
		CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		    COST 100
		    VOLATILE PARALLEL UNSAFE
		AS $BODY$
				        declare 
				                var_interpolation interpolation_type;
				                var_result numeric(8,2) default 0;
				                var_min_temparure numeric(8,2) default 0;
				                var_max_temperature numeric(8,2) default 0;
				                var_denominator numeric(8,2) default 0;
				        begin
				
				                                raise notice 'Расчет интерполяции для температуры %', par_temperature;
				
				                -- Проверим, возможно температура совпадает со значением в справочнике
				                if exists (select 1 from public.calc_correction_temperature where temperature = par_temperature ) then
				                begin
				                        select correction 
				                        into  var_result 
				                        from  public.calc_correction_temperature
				                        where 
				                                temperature = par_temperature;
				                end;
				                else    
				                begin
				                        -- Получим диапазон в котором работают поправки
				                        select min(temperature), max(temperature) 
				                        into var_min_temparure, var_max_temperature
				                        from public.calc_correction_temperature;
				
				                        if par_temperature < var_min_temparure or   
				                           par_temperature > var_max_temperature then
				
				                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
				                                        var_min_temparure, var_max_temperature;
				                        end if;   
				
				                        -- Получим граничные параметры
				
				                        select x0, y0, x1, y1 
				                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
				                        from
				                        (
				                                select t1.temperature as x0, t1.correction as y0
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature <= par_temperature
				                                order by t1.temperature desc
				                                limit 1
				                        ) as leftPart
				                        cross join
				                        (
				                                select t1.temperature as x1, t1.correction as y1
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature >= par_temperature
				                                order by t1.temperature 
				                                limit 1
				                        ) as rightPart;
				
				                        raise notice 'Граничные значения %', var_interpolation;
				                        var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);
				                                                 
				                end;
				                end if;
				
				                                return var_result;
				
				end;
				
		$BODY$;
		
		-- В учебном скрипте: ALTER FUNCTION ... OWNER TO admin;
		-- Здесь выполняется только если роль admin существует
		if exists (select 1 from pg_roles where rolname = 'admin') then
			execute 'ALTER FUNCTION public.fn_calc_temperature_interpolation(numeric) OWNER TO admin';
		end if;
		
		COMMENT ON FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    IS 'Функция для расчета интерполяции для метео приближенный';
	end;

	commit;
	
end $$;


-- =====================================================================
-- 2. КОРРЕКТИРОВКИ СПРАВОЧНИКОВ
-- =====================================================================

-- 2.1 Отдельная таблица для хранения заголовков
create sequence public.calc_correction_header_seq;
create table public.calc_correction_headers
(
    id            integer primary key not null default nextval('public.calc_correction_header_seq'),
    description   text    not null,
    header_values integer[] not null
);

comment on table  public.calc_correction_headers is 'Справочник заголовков таблиц корректировок';
comment on column public.calc_correction_headers.id is 'Уникальный код';
comment on column public.calc_correction_headers.description is 'Описание заголовка';
comment on column public.calc_correction_headers.header_values is 'Значения в заголовке таблицы (порядок = порядок значений в calc_correction.row_values)';

insert into public.calc_correction_headers(description, header_values)
values
('Таблица 2, отклонение приземной виртуальной температуры',  array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),            -- 1
('Таблица 3 (ВР), дальность сноса ветровых пуль, м',         array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),     -- 2
('Таблица 3 (ДМК), скорость приземного ветра, м/с',          array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);              -- 3

-- 2.2 Изменение структуры справочника типов таблиц: связь с заголовками
alter table public.calc_correction_types
    add column header_id integer references public.calc_correction_headers(id),
    add column code      text;

comment on column public.calc_correction_types.header_id is 'Код заголовка таблицы (calc_correction_headers)';
comment on column public.calc_correction_types.code is 'Символьный код типа таблицы';

update public.calc_correction_types set header_id = 1 where id in (8, 9);  -- Таблица 2 (положительные / отрицательные)
update public.calc_correction_types set header_id = 2 where id = 4;        -- Таблица 3, скорость (ВР)
update public.calc_correction_types set header_id = 3 where id = 6;        -- Таблица 3, скорость (ДМК)
-- Направление ветра (id 5, 7): одно значение на высоту, заголовка нет

update public.calc_correction_types set code = 'T2'       where id = 1;
update public.calc_correction_types set code = 'T3_SPEED' where id = 2;
update public.calc_correction_types set code = 'T3_DIR'   where id = 3;
update public.calc_correction_types set code = 'T2_POS'   where id = 8;
update public.calc_correction_types set code = 'T2_NEG'   where id = 9;

alter table public.calc_correction_types drop column header_values;

-- 2.3 Исправление данных
-- Таблица 2: отрицательные значения были записаны с типом 8 (положительные) -> тип 9
update public.calc_correction set type_id = 9 where type_id = 8;

-- Таблица 2: положительные значения были записаны с типом 7 (направление ветра ДМК) -> тип 8
-- (строки направления содержат одно значение, строки Таблицы 2 - несколько)
update public.calc_correction set type_id = 8 where type_id = 7 and array_length(row_values, 1) > 1;

-- 2.4 Добавление отсутствующих данных
-- Таблица 2, положительные: не хватало столбцов 40 и 50 (в строках 12 значений при 14 столбцах заголовка)
update public.calc_correction
set row_values = row_values || array[40, 50]
where type_id = 8 and array_length(row_values, 1) = 12;

-- Высоты 1600, 2000, 2400, 3000, 4000 (height_id 5..9) в справочниках отсутствуют.
-- Значения берутся из Таблицы 2 и Таблицы 3 (рисунки алгоритмов). Шаблон для заполнения:
-- insert into public.calc_correction(height_id, type_id, row_values) values
-- (5, 9, array[ ...14 значений... ]),   -- Таблица 2, отрицательные,  1600 м
-- (5, 8, array[ ...14 значений... ]),   -- Таблица 2, положительные,  1600 м
-- (5, 4, array[ ...12 значений... ]),   -- Таблица 3, скорость (ВР),  1600 м
-- (5, 5, array[ ...1 значение... ]),    -- Таблица 3, направление (ВР)
-- (5, 6, array[ ...13 значений... ]),   -- Таблица 3, скорость (ДМК)
-- (5, 7, array[ ...1 значение... ]);    -- Таблица 3, направление (ДМК)


-- =====================================================================
-- 3. РАСЧЕТ
-- =====================================================================

-- 3.1 Тип "входящие параметры"
create type public.calc_input_params as
(
    meteopost_height integer,       -- Высота метеопоста, м
    temperature      numeric(8,1),  -- Температура, °C
    pressure         integer,       -- Давление, мм рт. ст.
    wind_direction   integer,       -- Направление ветра, большие деления угломера (0..59)
    wind_speed       integer,       -- Скорость ветра, м/с (для ДМК)
    drift_distance   integer        -- Дальность сноса пуль, м (для ВР)
);

-- 3.2 Функция расчета: на входе входящие параметры и тип оборудования (1 - ДМК, 2 - ВР),
--     на выходе строка по каждой стандартной высоте: H, TT, HH, CC
create or replace function public.fn_calc_meteo_approx(
    par_input        public.calc_input_params,
    par_equipment_id integer)
returns table (h integer, tt text, hh text, cc text)
language plpgsql
as $body$
declare
    var_t0              numeric;
    var_dt              integer;    -- отклонение приземной виртуальной температуры
    var_abs             integer;
    var_tens            integer;
    var_units           integer;
    var_temp_type_id    integer;
    var_speed_type_id   integer;
    var_dir_type_id     integer;
    var_temp_header     integer[];
    var_speed_header    integer[];
    var_wind_value      integer;
    var_wind_zero       boolean;
    var_x0              integer;
    var_x1              integer;
    var_y0              integer;
    var_y1              integer;
    var_inc             integer;
    var_sum             integer;
    var_speed           numeric;
    var_row             integer[];
    var_height          record;
begin
    if par_equipment_id not in (1, 2) then
        raise exception 'Неизвестный тип оборудования %. Допустимо: 1 - ДМК, 2 - ВР', par_equipment_id;
    end if;

    var_wind_value := case par_equipment_id when 1 then par_input.wind_speed else par_input.drift_distance end;

    if par_input.temperature is null or par_input.wind_direction is null or var_wind_value is null then
        raise exception 'Не заданы входные параметры (температура, направление ветра, скорость ветра / дальность сноса пуль)';
    end if;

    -- Приземная виртуальная температура и ее отклонение от табличного значения 15,9
    var_t0 := par_input.temperature + public.fn_calc_temperature_interpolation(par_input.temperature);
    var_dt := round(var_t0 - 15.9);

    var_abs   := abs(var_dt);
    var_tens  := (var_abs / 10) * 10;
    var_units := var_abs % 10;

    -- Тип и заголовок Таблицы 2
    select t.id, hd.header_values
    into   var_temp_type_id, var_temp_header
    from   public.calc_correction_types t
           join public.calc_correction_headers hd on hd.id = t.header_id
    where  t.code = case when var_dt < 0 then 'T2_NEG' else 'T2_POS' end;

    if (var_tens > 0  and array_position(var_temp_header, var_tens)  is null) or
       (var_units > 0 and array_position(var_temp_header, var_units) is null) then
        raise exception 'Отклонение температуры % выходит за пределы Таблицы 2', var_dt;
    end if;

    -- Тип и заголовок Таблицы 3 (скорость) и тип Таблицы 3 (направление) для оборудования
    select t.id, hd.header_values
    into   var_speed_type_id, var_speed_header
    from   public.calc_correction_types t
           join public.calc_correction_types p on p.id = t.parent_id and p.code = 'T3_SPEED'
           join public.calc_correction_headers hd on hd.id = t.header_id
    where  t.measurment_equipment_id = par_equipment_id;

    select t.id
    into   var_dir_type_id
    from   public.calc_correction_types t
           join public.calc_correction_types p on p.id = t.parent_id and p.code = 'T3_DIR'
    where  t.measurment_equipment_id = par_equipment_id;

    -- Ветер: при значении меньше первого столбца таблицы (ДМК < 3 м/с, ВР < 40 м) скорость и направление = 00
    var_wind_zero := var_wind_value < var_speed_header[1];

    if not var_wind_zero then
        -- соседние столбцы заголовка (между столбцами скорость определяется линейно и округляется до 1 м/с)
        select max(u.v) into var_x0 from unnest(var_speed_header) as u(v) where u.v <= var_wind_value;
        select min(u.v) into var_x1 from unnest(var_speed_header) as u(v) where u.v >= var_wind_value;
        var_x1 := coalesce(var_x1, var_x0);
    end if;

    for var_height in
        select ch.id, ch.height
        from   public.calc_correction_heights ch
        order by ch.height
    loop
        h  := var_height.height;
        tt := null;
        hh := null;
        cc := null;

        -- TT: среднее отклонение температуры (Таблица 2)
        if var_dt = 0 then
            tt := '00';
        else
            select cr.row_values into var_row
            from   public.calc_correction cr
            where  cr.height_id = var_height.id and cr.type_id = var_temp_type_id;

            if var_row is null then
                raise notice 'Нет данных Таблицы 2 для высоты % м', var_height.height;
            else
                var_sum := 0;
                if var_tens > 0 then
                    var_sum := var_sum + var_row[array_position(var_temp_header, var_tens)];
                end if;
                if var_units > 0 then
                    var_sum := var_sum + var_row[array_position(var_temp_header, var_units)];
                end if;

                if var_dt < 0 then
                    tt := lpad((abs(var_sum) + 50)::text, 2, '0');
                else
                    tt := lpad(var_sum::text, 2, '0');
                end if;
            end if;
        end if;

        -- HH, CC: направление и скорость среднего ветра (Таблица 3)
        if var_wind_zero then
            hh := '00';
            cc := '00';
        else
            select cr.row_values into var_row
            from   public.calc_correction cr
            where  cr.height_id = var_height.id and cr.type_id = var_speed_type_id;

            if var_row is null then
                raise notice 'Нет данных Таблицы 3 (скорость) для высоты % м', var_height.height;
            else
                var_y0 := var_row[array_position(var_speed_header, var_x0)];
                var_y1 := var_row[array_position(var_speed_header, var_x1)];
                if var_x0 = var_x1 then
                    var_speed := var_y0;
                else
                    var_speed := var_y0 + (var_wind_value - var_x0)::numeric * (var_y1 - var_y0) / (var_x1 - var_x0);
                end if;
                cc := lpad(round(var_speed)::text, 2, '0');
            end if;

            select (cr.row_values)[1] into var_inc
            from   public.calc_correction cr
            where  cr.height_id = var_height.id and cr.type_id = var_dir_type_id;

            if var_inc is null then
                raise notice 'Нет данных Таблицы 3 (направление) для высоты % м', var_height.height;
            else
                hh := lpad(((par_input.wind_direction + var_inc) % 60)::text, 2, '0');
            end if;
        end if;

        return next;
    end loop;
end;
$body$;

comment on function public.fn_calc_meteo_approx(public.calc_input_params, integer)
    is 'Расчет приближенного метеобюллетеня по стандартным высотам (1 - ДМК, 2 - ВР)';

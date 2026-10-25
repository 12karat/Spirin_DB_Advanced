-- =====================================================================
-- 02_meteo_ddl_validation.sql
-- П. 1 задания:
--   * расширение DDL (информация об ошибках входных параметров)
--   * новый тип данных "Список параметров"
--   * функция проверки корректности параметров
-- Запускать ПОСЛЕ 01_meteo_constants.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Базовые таблицы.
--    Исходная DDL в задании не видна, поэтому структура принята как
--    предположение. Если таблицы уже есть - CREATE IF NOT EXISTS
--    ничего не изменит, а ALTER ниже добавит только колонки ошибок.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meteo.users (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name  text NOT NULL
);

CREATE TABLE IF NOT EXISTS meteo.batches (          -- пачки
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code       text      NOT NULL UNIQUE,           -- код пачки (N)
    created_at timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS meteo.equipment_types (  -- типы оборудования
    id         int  PRIMARY KEY,
    name       text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS meteo.measurements (     -- входные параметры
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id            bigint    NOT NULL REFERENCES meteo.batches (id),
    user_id             bigint    NOT NULL REFERENCES meteo.users (id),
    observed_at         timestamp NOT NULL DEFAULT now(),
    equipment_type_id   int,                        -- без FK: ошибку ловит валидация
    meteopost_height    numeric(8,2),               -- высота метеопоста, м
    temperature         numeric(6,2),               -- температура, °C
    pressure            numeric(7,2),               -- давление, мм рт. ст.
    wind_direction      numeric(6,2),               -- направление ветра, град
    wind_speed          numeric(6,2),               -- скорость ветра, м/с
    bullet_drift_range  numeric(8,2)                -- дальность сноса пуль, м
);

-- ---------------------------------------------------------------------
-- 1. Расширение DDL: информация об ошибках
-- ---------------------------------------------------------------------
ALTER TABLE meteo.measurements
    ADD COLUMN IF NOT EXISTS has_error   boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS error_count int     NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS error_text  text;

COMMENT ON COLUMN meteo.measurements.has_error   IS 'Флаг: есть ошибка во входных параметрах';
COMMENT ON COLUMN meteo.measurements.error_count IS 'Количество найденных ошибок';
COMMENT ON COLUMN meteo.measurements.error_text  IS 'Описание ошибок (через "; ")';

CREATE INDEX IF NOT EXISTS ix_measurements_batch ON meteo.measurements (batch_id);
CREATE INDEX IF NOT EXISTS ix_measurements_user  ON meteo.measurements (user_id);

-- ---------------------------------------------------------------------
-- 2. Новый тип данных: список параметров
-- ---------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'meteo' AND t.typname = 't_meteo_params'
    ) THEN
        CREATE TYPE meteo.t_meteo_params AS (
            equipment_type_id   int,
            meteopost_height    numeric,
            temperature         numeric,
            pressure            numeric,
            wind_direction      numeric,
            wind_speed          numeric,
            bullet_drift_range  numeric
        );
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- 3. Вспомогательная функция: проверка одного значения по диапазону
--    Возвращает NULL, если всё в порядке, иначе текст ошибки.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_check_range(p_param text, p_value numeric)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_name text;
    v_min  numeric;
    v_max  numeric;
    v_unit text;
BEGIN
    SELECT l.param_name, l.min_value, l.max_value, l.unit
    INTO   v_name, v_min, v_max, v_unit
    FROM   meteo.param_limits l
    WHERE  l.param_code = p_param;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Диапазон для параметра "%" не задан', p_param;
    END IF;

    IF p_value IS NULL THEN
        RETURN format('%s: значение не задано', v_name);
    ELSIF p_value < v_min OR p_value > v_max THEN
        RETURN format('%s: значение %s вне допустимого диапазона [%s; %s] %s',
                      v_name, p_value, v_min, v_max, coalesce(v_unit, ''));
    END IF;

    RETURN NULL;
END;
$$;

-- ---------------------------------------------------------------------
-- 4. Проверка корректности параметров -> массив ошибок
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_validate_params_arr(p meteo.t_meteo_params)
RETURNS text[]
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_errors text[] := ARRAY[]::text[];
BEGIN
    -- тип оборудования
    IF p.equipment_type_id IS NULL THEN
        v_errors := v_errors || 'Тип оборудования: значение не задано';
    ELSIF NOT EXISTS (SELECT 1 FROM meteo.equipment_types e WHERE e.id = p.equipment_type_id) THEN
        v_errors := v_errors || format('Тип оборудования: код %s отсутствует в справочнике',
                                       p.equipment_type_id);
    END IF;

    -- числовые параметры
    v_errors := v_errors || meteo.fn_check_range('HEIGHT',      p.meteopost_height);
    v_errors := v_errors || meteo.fn_check_range('TEMPERATURE', p.temperature);
    v_errors := v_errors || meteo.fn_check_range('PRESSURE',    p.pressure);
    v_errors := v_errors || meteo.fn_check_range('WIND_DIR',    p.wind_direction);
    v_errors := v_errors || meteo.fn_check_range('WIND_SPEED',  p.wind_speed);
    v_errors := v_errors || meteo.fn_check_range('DRIFT_RANGE', p.bullet_drift_range);

    -- fn_check_range возвращает NULL для корректных значений - убираем их
    RETURN array_remove(v_errors, NULL);
END;
$$;

-- ---------------------------------------------------------------------
-- 5. Проверка корректности параметров -> строка со списком ошибок
--    Вход: тип со списком параметров. Выход: строка ошибок через "; "
--    или NULL, если ошибок нет.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_validate_params(p meteo.t_meteo_params)
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(array_to_string(meteo.fn_validate_params_arr(p), '; '), '');
$$;

-- ---------------------------------------------------------------------
-- 6. Триггер: автоматически заполняет has_error / error_count / error_text
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.trg_measurements_validate()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_errors text[];
BEGIN
    v_errors := meteo.fn_validate_params_arr(
        ROW(NEW.equipment_type_id, NEW.meteopost_height, NEW.temperature,
            NEW.pressure, NEW.wind_direction, NEW.wind_speed,
            NEW.bullet_drift_range)::meteo.t_meteo_params
    );

    NEW.error_count := coalesce(cardinality(v_errors), 0);
    NEW.has_error   := NEW.error_count > 0;
    NEW.error_text  := NULLIF(array_to_string(v_errors, '; '), '');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_measurements_validate ON meteo.measurements;
CREATE TRIGGER trg_measurements_validate
    BEFORE INSERT OR UPDATE ON meteo.measurements
    FOR EACH ROW EXECUTE FUNCTION meteo.trg_measurements_validate();

-- Пересчёт ошибок для уже существующих строк (сработает триггер)
UPDATE meteo.measurements SET equipment_type_id = equipment_type_id;

-- ---------------------------------------------------------------------
-- Пример вызова:
--   SELECT meteo.fn_validate_params(ROW(1, 120, 99, 745, 400, 5, 10)::meteo.t_meteo_params);
-- ---------------------------------------------------------------------

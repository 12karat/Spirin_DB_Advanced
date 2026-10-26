CREATE SCHEMA IF NOT EXISTS meteo;

CREATE TABLE IF NOT EXISTS meteo.constants (
    const_code  text    PRIMARY KEY,
    num_value   numeric,
    text_value  text,
    unit        text,
    description text    NOT NULL,
    CONSTRAINT ck_constants_value CHECK (num_value IS NOT NULL OR text_value IS NOT NULL)
);

COMMENT ON TABLE meteo.constants IS 'Константы расчёта Метео-приближенного';

CREATE TABLE IF NOT EXISTS meteo.param_limits (
    param_code  text    PRIMARY KEY,
    param_name  text    NOT NULL,
    min_value   numeric NOT NULL,
    max_value   numeric NOT NULL,
    unit        text,
    CONSTRAINT ck_param_limits_range CHECK (min_value <= max_value)
);

COMMENT ON TABLE meteo.param_limits IS 'Допустимые диапазоны входных параметров метеоизмерений';

INSERT INTO meteo.constants (const_code, num_value, unit, description) VALUES
    ('NORM_PRESSURE',       750,  'мм рт. ст.', 'Табличное (нормальное) давление у земли'),
    ('NORM_TEMPERATURE',    15.9, '°C',         'Табличная температура у земли'),
    ('PRESSURE_NEG_OFFSET', 500,  NULL,         'Добавка к БББ при отрицательном отклонении давления'),
    ('PRESSURE_CODE_MAX',   499,  NULL,         'Максимальный модуль отклонения давления для кодирования БББ'),
    ('TEMP_NEG_OFFSET',     50,   NULL,         'Добавка к ТТ при отрицательном отклонении температуры'),
    ('TEMP_CODE_MAX',       49,   NULL,         'Максимальный модуль отклонения температуры для кодирования ТТ'),
    ('HEIGHT_NEG_OFFSET',   5000, NULL,         'Добавка к ВВВВ при отрицательной высоте метеопоста'),
    ('HEIGHT_CODE_MAX',     4999, 'м',          'Максимальный модуль высоты метеопоста для кодирования ВВВВ')
ON CONFLICT (const_code) DO UPDATE
    SET num_value = EXCLUDED.num_value, unit = EXCLUDED.unit, description = EXCLUDED.description;

INSERT INTO meteo.param_limits (param_code, param_name, min_value, max_value, unit) VALUES
    ('HEIGHT',      'Высота метеопоста',      -200,  4999, 'м'),
    ('TEMPERATURE', 'Температура',             -50,    60, '°C'),
    ('PRESSURE',    'Давление',                500,   800, 'мм рт. ст.'),
    ('WIND_DIR',    'Направление ветра',         0,   360, 'град'),
    ('WIND_SPEED',  'Скорость ветра',            0,    60, 'м/с'),
    ('DRIFT_RANGE', 'Дальность сноса пуль',      0,  1000, 'м')
ON CONFLICT (param_code) DO UPDATE
    SET param_name = EXCLUDED.param_name, min_value = EXCLUDED.min_value,
        max_value  = EXCLUDED.max_value,  unit      = EXCLUDED.unit;

CREATE OR REPLACE FUNCTION meteo.fn_const_num(p_code text)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_value numeric;
BEGIN
    SELECT c.num_value INTO v_value
    FROM meteo.constants c
    WHERE c.const_code = p_code;

    IF NOT FOUND OR v_value IS NULL THEN
        RAISE EXCEPTION 'Числовая константа "%" не найдена в meteo.constants', p_code;
    END IF;
    RETURN v_value;
END;
$$;

CREATE OR REPLACE FUNCTION meteo.fn_const_text(p_code text)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_value text;
BEGIN
    SELECT c.text_value INTO v_value
    FROM meteo.constants c
    WHERE c.const_code = p_code;

    IF NOT FOUND OR v_value IS NULL THEN
        RAISE EXCEPTION 'Текстовая константа "%" не найдена в meteo.constants', p_code;
    END IF;
    RETURN v_value;
END;
$$;

CREATE OR REPLACE FUNCTION meteo.fn_limit_min(p_param text)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_value numeric;
BEGIN
    SELECT l.min_value INTO v_value FROM meteo.param_limits l WHERE l.param_code = p_param;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Диапазон для параметра "%" не задан в meteo.param_limits', p_param;
    END IF;
    RETURN v_value;
END;
$$;

CREATE OR REPLACE FUNCTION meteo.fn_limit_max(p_param text)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_value numeric;
BEGIN
    SELECT l.max_value INTO v_value FROM meteo.param_limits l WHERE l.param_code = p_param;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Диапазон для параметра "%" не задан в meteo.param_limits', p_param;
    END IF;
    RETURN v_value;
END;
$$;

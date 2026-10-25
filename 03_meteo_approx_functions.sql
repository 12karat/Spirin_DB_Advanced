-- =====================================================================
-- 03_meteo_approx_functions.sql
-- П. 5 задания: функции расчёта "Метео приближенный" (ДДЧЧМ, ВВВВ, БББТТ).
-- Запускать после 01_meteo_constants.sql
--
-- ПРИНЯТЫЕ СОГЛАШЕНИЯ (все значения лежат в meteo.constants и меняются там):
--   ДДЧЧМ - ДД день месяца, ЧЧ час, М десятки минут времени измерения.
--   ВВВВ  - высота метеопоста, м, 4 знака; отрицательная высота
--           кодируется добавлением HEIGHT_NEG_OFFSET (5000).
--   БББТТ - БББ: отклонение давления от нормального (750 мм рт. ст.),
--           отрицательное отклонение кодируется добавкой 500;
--           ТТ : отклонение температуры от нормальной (15.9 °C),
--           отрицательное отклонение кодируется добавкой 50;
--           модуль ТТ ограничен значением TEMP_CODE_MAX (49).
-- =====================================================================

-- ---------------------------------------------------------------------
-- ДДЧЧМ
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_meteo_ddchhm(p_observed_at timestamp)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT to_char(p_observed_at, 'DDHH24')
        || (floor(extract(minute FROM p_observed_at) / 10))::int::text;
$$;

-- ---------------------------------------------------------------------
-- ВВВВ
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_meteo_vvvv(p_height numeric)
RETURNS text
LANGUAGE plpgsql
STABLE
STRICT
AS $$
DECLARE
    v_h        int     := round(p_height)::int;
    v_max      int     := meteo.fn_const_num('HEIGHT_CODE_MAX')::int;
    v_neg_off  int     := meteo.fn_const_num('HEIGHT_NEG_OFFSET')::int;
    v_code     int;
BEGIN
    IF abs(v_h) > v_max THEN
        RAISE EXCEPTION 'Высота метеопоста % м вне диапазона кодирования ВВВВ (±%)', v_h, v_max;
    END IF;

    v_code := CASE WHEN v_h < 0 THEN abs(v_h) + v_neg_off ELSE v_h END;
    RETURN lpad(v_code::text, 4, '0');
END;
$$;

-- ---------------------------------------------------------------------
-- БББТТ
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_meteo_bbbtt(p_pressure numeric, p_temperature numeric)
RETURNS text
LANGUAGE plpgsql
STABLE
STRICT
AS $$
DECLARE
    v_dp        int := round(p_pressure    - meteo.fn_const_num('NORM_PRESSURE'))::int;
    v_dt        int := round(p_temperature - meteo.fn_const_num('NORM_TEMPERATURE'))::int;
    v_p_max     int := meteo.fn_const_num('PRESSURE_CODE_MAX')::int;
    v_t_max     int := meteo.fn_const_num('TEMP_CODE_MAX')::int;
    v_p_off     int := meteo.fn_const_num('PRESSURE_NEG_OFFSET')::int;
    v_t_off     int := meteo.fn_const_num('TEMP_NEG_OFFSET')::int;
    v_bbb       int;
    v_tt        int;
BEGIN
    IF abs(v_dp) > v_p_max THEN
        RAISE EXCEPTION 'Отклонение давления % вне диапазона кодирования БББ (±%)', v_dp, v_p_max;
    END IF;

    v_bbb := CASE WHEN v_dp < 0 THEN abs(v_dp) + v_p_off ELSE v_dp END;

    -- модуль отклонения температуры ограничивается форматом (2 знака)
    v_tt  := CASE WHEN v_dt < 0 THEN least(abs(v_dt), v_t_max) + v_t_off
                  ELSE least(v_dt, v_t_max) END;

    RETURN lpad(v_bbb::text, 3, '0') || lpad(v_tt::text, 2, '0');
END;
$$;

-- ---------------------------------------------------------------------
-- Итоговая строка: "ДДЧЧМ ВВВВ БББТТ"
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION meteo.fn_meteo_approx(
    p_observed_at timestamp,
    p_height      numeric,
    p_pressure    numeric,
    p_temperature numeric
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT concat_ws(' ',
        meteo.fn_meteo_ddchhm(p_observed_at),
        meteo.fn_meteo_vvvv(p_height),
        meteo.fn_meteo_bbbtt(p_pressure, p_temperature)
    );
$$;

-- ---------------------------------------------------------------------
-- Примеры:
--   SELECT meteo.fn_meteo_ddchhm('2026-10-25 14:37');       -- 25143
--   SELECT meteo.fn_meteo_vvvv(120);                        -- 0120
--   SELECT meteo.fn_meteo_bbbtt(745, 20);                   -- 50504  (dP=-5 -> 505, dT=+4 -> 04)
--   SELECT meteo.fn_meteo_approx('2026-10-25 14:37', 120, 745, 20);
-- ---------------------------------------------------------------------

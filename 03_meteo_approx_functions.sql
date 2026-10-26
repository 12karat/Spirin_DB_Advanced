CREATE OR REPLACE FUNCTION meteo.fn_meteo_ddchhm(p_observed_at timestamp)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT to_char(p_observed_at, 'DDHH24')
        || (floor(extract(minute FROM p_observed_at) / 10))::int::text;
$$;

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

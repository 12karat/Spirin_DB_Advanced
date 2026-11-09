-- Тестовый скрипт: расчет для типовых входных данных из ТЗ
-- Запускать ПОСЛЕ 20261108_meteo_calc.sql
do $$
declare
    var_row record;
begin
    -- ДМК (Пример 2 из ТЗ): высота 100, давление 765, температура 25, направление 15, скорость 6
    raise notice 'ДМК';
    for var_row in select * from public.fn_calc_meteo_approx((100, 25, 765, 15, 6, 0)::public.calc_input_params, 1) loop
        raise notice 'H=%  TT=%  HH=%  CC=%', var_row.h, coalesce(var_row.tt, '--'), coalesce(var_row.hh, '--'), coalesce(var_row.cc, '--');
    end loop;

    -- ВР: те же данные, дальность сноса пуль 75
    raise notice 'ВР';
    for var_row in select * from public.fn_calc_meteo_approx((100, 25, 765, 15, 0, 75)::public.calc_input_params, 2) loop
        raise notice 'H=%  TT=%  HH=%  CC=%', var_row.h, coalesce(var_row.tt, '--'), coalesce(var_row.hh, '--'), coalesce(var_row.cc, '--');
    end loop;
end $$;

do $$
declare
    v_from date := date '2010-01-01';
    v_to   date := date '2030-12-31';
    v_months text[] := array['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                             'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    v_quarters text[] := array['I квартал', 'II квартал', 'III квартал', 'IV квартал'];
begin
    insert into olap.dim_time (
        time_code, month_start_date, month_end_date, month_name,
        year_number, quarter_number, quarter_name
    )
    select
        extract(year from m)::int * 100 + extract(month from m)::int,
        m::date,
        (m + interval '1 month' - interval '1 day')::date,
        v_months[extract(month from m)::int],
        extract(year from m)::int,
        extract(quarter from m)::int,
        v_quarters[extract(quarter from m)::int]
    from generate_series(
        date_trunc('month', v_from::timestamp),
        date_trunc('month', v_to::timestamp),
        interval '1 month'
    ) as m
    on conflict (time_code) do nothing;
end
$$;

-- проверка
select * from olap.dim_time order by time_code limit 15;

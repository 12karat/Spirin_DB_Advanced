do $$
declare
    v_dir text := '/csv';
    r     record;
    n     bigint;
begin
    truncate table
        olap.fact_journal_details,
        olap.fact_stock_operations,
        olap.fact_work_hours,
        olap.fact_staff_bonus,
        olap.fact_sales,
        olap.fact_purchases,
        olap.dim_product,
        olap.dim_staff,
        olap.dim_operation_type,
        olap.dim_storage,
        olap.dim_vendor;

    for r in
        select t.tbl, t.cols
        from (values
            (1,  'dim_vendor',            'vendor_id, client_name, client_group, full_name'),
            (2,  'dim_storage',           'storage_id, description, company_id'),
            (3,  'dim_operation_type',    'operation_type_id, description, factor'),
            (4,  'dim_staff',             'person_id, last_name, first_name, middle_name'),
            (5,  'dim_product',           'product_id, product_code, description, vendor_id'),
            (6,  'fact_purchases',        'operation_id, document_id, operation_date, time_code, operation_type_id, product_id, vendor_id, storage_id, quantity, price, amount'),
            (7,  'fact_sales',            'sale_id, ticket_number, sale_date, time_code, product_type, bludo_id, bludo_name, manager_id, storage_id, quantity, price, amount'),
            (8,  'fact_staff_bonus',      'bonus_id, client_id, action_id, action_name, bonus_value, bonus_date, time_code, ticket_number, person_id, is_calc'),
            (9,  'fact_work_hours',       'work_hours_id, shift_id, work_date, time_code, person_id, system_hours, manual_hours, position_id, manual_flag'),
            (10, 'fact_stock_operations', 'operation_id, document_id, operation_date, time_code, operation_type_id, storage_id, product_id, quantity, rest, price, amount'),
            (11, 'fact_journal_details',  'detail_id, source_id, added_date, time_code, product_id, storage_id, quantity, count_value')
        ) as t (ord, tbl, cols)
        order by t.ord
    loop
        execute format(
            'copy olap.%I (%s) from %L with (format csv, header true, encoding ''UTF8'')',
            r.tbl, r.cols, v_dir || '/' || r.tbl || '.csv'
        );

        execute format('select count(*) from olap.%I', r.tbl) into n;
        raise notice '%: загружено строк %', r.tbl, n;
    end loop;
end
$$;

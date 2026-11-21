do $$
begin
    create schema if not exists olap;

    -- справочники

    create table if not exists olap.dim_time (
        time_code        int primary key,
        month_start_date date        not null,
        month_end_date   date        not null,
        month_name       varchar(20) not null,
        year_number      int         not null,
        quarter_number   int         not null,
        quarter_name     varchar(20) not null
    );

    create table if not exists olap.dim_vendor (
        vendor_id    bigint primary key,
        client_name  text,
        client_group int,
        full_name    text
    );

    create table if not exists olap.dim_storage (
        storage_id  bigint primary key,
        description text,
        company_id  int
    );

    create table if not exists olap.dim_operation_type (
        operation_type_id bigint primary key,
        description       text,
        factor            int
    );

    create table if not exists olap.dim_staff (
        person_id   int primary key,
        last_name   text,
        first_name  text,
        middle_name text
    );

    create table if not exists olap.dim_product (
        product_id   bigint primary key,
        product_code text,
        description  text,
        vendor_id    bigint references olap.dim_vendor (vendor_id)
    );

    -- закупки продукции

    create table if not exists olap.fact_purchases (
        operation_id      bigint primary key,
        document_id       bigint not null,
        operation_date    timestamp,
        time_code         int references olap.dim_time (time_code),
        operation_type_id bigint not null references olap.dim_operation_type (operation_type_id),
        product_id        bigint not null references olap.dim_product (product_id),
        vendor_id         bigint references olap.dim_vendor (vendor_id),
        storage_id        bigint not null references olap.dim_storage (storage_id),
        quantity          numeric(18, 4),
        price             numeric(18, 4),
        amount            numeric(18, 4)
    );

    -- продажи товара

    create table if not exists olap.fact_sales (
        sale_key      bigint generated always as identity primary key,
        sale_id       bigint,
        ticket_number numeric,
        sale_date     timestamp,
        time_code     int references olap.dim_time (time_code),
        product_type  varchar(12),
        bludo_id      bigint,
        bludo_name    text,
        manager_id    int,
        storage_id    bigint references olap.dim_storage (storage_id),
        quantity      numeric(18, 4),
        price         numeric(18, 4),
        amount        numeric(18, 4)
    );

    -- работа персонала

    create table if not exists olap.fact_staff_bonus (
        bonus_id      bigint primary key,
        client_id     bigint,
        action_id     bigint,
        action_name   text,
        bonus_value   numeric(18, 4),
        bonus_date    timestamp,
        time_code     int references olap.dim_time (time_code),
        ticket_number varchar(25),
        person_id     int references olap.dim_staff (person_id),
        is_calc       int
    );

    create table if not exists olap.fact_work_hours (
        work_hours_id bigint primary key,
        shift_id      int,
        work_date     timestamp,
        time_code     int references olap.dim_time (time_code),
        person_id     int,
        system_hours  double precision,
        manual_hours  double precision,
        position_id   varchar(16),
        manual_flag   int
    );

    -- остатки

    create table if not exists olap.fact_stock_operations (
        operation_id      bigint primary key,
        document_id       bigint,
        operation_date    timestamp,
        time_code         int references olap.dim_time (time_code),
        operation_type_id bigint references olap.dim_operation_type (operation_type_id),
        storage_id        bigint not null references olap.dim_storage (storage_id),
        product_id        bigint not null references olap.dim_product (product_id),
        quantity          numeric(18, 4),
        rest              numeric(18, 4),
        price             numeric(18, 4),
        amount            numeric(18, 4)
    );

    create table if not exists olap.fact_journal_details (
        detail_id  bigint primary key,
        source_id  bigint,
        added_date timestamp,
        time_code  int references olap.dim_time (time_code),
        product_id bigint references olap.dim_product (product_id),
        storage_id bigint references olap.dim_storage (storage_id),
        quantity   numeric(18, 4),
        count_value numeric(18, 4)
    );
end
$$;

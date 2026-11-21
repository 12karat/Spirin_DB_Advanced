-- общие справочники

-- dim_vendor.csv
select v.id, v.clientid, v.clientgroup, v.firstname
from vendors as v;

-- dim_storage.csv
select s.id, s.description, s.CompanyID
from storages as s;

-- dim_operation_type.csv
select ot.ID, ot.Description, ot.Factor
from bm_StorageOperationsType as ot;

-- dim_staff.csv
select p.personid, p.lastname, p.firstname, p.middlename
from personnel as p;

-- dim_product.csv (если поставщика нет в vendors, пишем NULL)
select
    p.id,
    p.productid,
    p.description,
    case when v.id is null then null else p.vendorid end as vendor_id
from product as p
left join vendors as v on v.id = p.vendorid;


-- 1. закупки продукции

-- fact_purchases.csv (берем поступления, тип операции 1)
select
    so.ID,
    so.DocumentID,
    jd.Period,
    year(jd.Period) * 100 + month(jd.Period) as time_code,
    so.OperationID,
    so.ProductID,
    case when v.id is null then null else so.VendorID end as vendor_id,
    so.StorageID,
    so.Quantity,
    so.Price,
    so.Amount
from bm_StorageOperations as so
join bm_JournalBarnetDocs as jd on jd.ID = so.DocumentID
left join vendors as v on v.id = so.VendorID
where so.OperationID = 1;


-- 2. продажи товара

-- fact_sales.csv
select
    s.ID,
    s.TicketNumber,
    s.TicketDate,
    year(s.TicketDate) * 100 + month(s.TicketDate) as time_code,
    s.ProductType,
    s.BludoID,
    s.BludoName,
    s.ManagerID,
    case when st.id is null then null else s.StorageID end as storage_id,
    s.quantity,
    s.price,
    s.amount
from vw_SalesTicketInfo as s
left join storages as st on st.id = s.StorageID;


-- 3. работа персонала

-- fact_staff_bonus.csv
select
    bh.ID,
    bh.ClientID,
    bh.ActionID,
    bh.ActionName,
    bh.BonusValue,
    bh.Period,
    year(bh.Period) * 100 + month(bh.Period) as time_code,
    bh.TicketNumber,
    bh.PersonID,
    bh.IsCalc
from bm_BonusHistory as bh;

-- fact_work_hours.csv (таблица в базе пустая, в файле будет только заголовок)
select
    wh.ID,
    wh.ShiftID,
    wh.DateR,
    year(wh.DateR) * 100 + month(wh.DateR) as time_code,
    wh.PersonID,
    wh.SystemPeriod,
    wh.ManualPeriod,
    wh.PositionID,
    wh.ManualFlag
from bm_WorkHours as wh;


-- 4. остатки

-- fact_stock_operations.csv
select
    sot.ID,
    sot.DocumentID,
    jd.Period,
    year(jd.Period) * 100 + month(jd.Period) as time_code,
    sot.OperationID,
    sot.StorageID,
    sot.ProductID,
    sot.Quantity,
    sot.Rest,
    sot.Price,
    sot.Amount
from bm_StorageOperations_Table as sot
left join bm_JournalBarnetDocs as jd on jd.ID = sot.DocumentID;

-- fact_journal_details.csv
select
    d.ID,
    d.SourceID,
    d.DateAdd,
    year(d.DateAdd) * 100 + month(d.DateAdd) as time_code,
    d.ProductID,
    case when st.id is null then null else d.StorageID end as storage_id,
    d.Quantity,
    d.[Count]
from bm_Journal_Details as d
left join storages as st on st.id = d.StorageID;


-- проверочные запросы, в CSV их сохранять не надо

-- какие даты есть в данных (в таблице времени годы с 2010 по 2030)
select min(Period) as min_date, max(Period) as max_date from bm_JournalBarnetDocs;
select min(TicketDate) as min_date, max(TicketDate) as max_date from vw_SalesTicketInfo;
select min(Period) as min_date, max(Period) as max_date from bm_BonusHistory;
select min(DateAdd) as min_date, max(DateAdd) as max_date from bm_Journal_Details;

-- какие типы операций есть в закупках
select OperationID, count(*) as cnt
from bm_StorageOperations
group by OperationID;

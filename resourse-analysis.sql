-- задание 1; проверяю, что в таблицах есть данные

-- закупки
select * from bm_StorageOperations;
select * from bm_StorageOperations_Table;

-- продажи
select * from vw_SalesTicketInfo;

-- поставщики
select * from vendors;

-- персонал
select * from personnel;
select * from bm_WorkHours;

-- остатки
select * from bm_StorageOperations_Table;
select * from bm_Journal_Details;


-- задание 2; основные и связанные таблицы

-- закупки
select * from bm_StorageOperations;
select * from bm_JournalBarnetDocs;
select * from bm_StorageOperations_Table;
select * from product;
select * from vendors;
select * from bm_JournalTypeDocuments;
select * from bm_Contracts;
select * from storages;
select * from bm_StorageOperationsType;

-- продажи
select * from product;
select * from pricelist;
select * from vw_SalesTicketInfo;

-- поставщики
select * from vendors;
select * from bm_StorageOperations;
select * from bm_JournalBarnetDocs;

-- персонал
select * from personnel;
select * from bm_BonusHistory;
select * from bm_WorkHours;

-- остатки
select * from bm_StorageOperations_Table;
select * from bm_JournalBarnetDocs;
select * from bm_Journal_Details;


-- задание 4; запросы для проверки выводов

-- закупки: у каждой операции должен находиться её документ
select *
from bm_StorageOperations as so
join bm_JournalBarnetDocs as jd on jd.ID = so.DocumentID;

-- закупки: у каждого документа должен находиться его тип
select *
from bm_JournalBarnetDocs as jd
join bm_JournalTypeDocuments as jt on jt.ID = jd.DocumentTypeID;

-- закупки: у каждой операции должен находиться её тип
select *
from bm_StorageOperations as so
join bm_StorageOperationsType as sot on sot.ID = so.OperationID;

-- закупки: у каждой операции должен находиться товар
select *
from bm_StorageOperations as so
join product as p on p.id = so.ProductID;

-- закупки: у операций (табличная часть) должны находиться документ, тип, склад и товар
select *
from bm_StorageOperations_Table as sot
join bm_JournalBarnetDocs as jd on jd.ID = sot.DocumentID;

select *
from bm_StorageOperations_Table as sot
join bm_StorageOperationsType as ot on ot.ID = sot.OperationID;

select *
from bm_StorageOperations_Table as sot
join storages as st on st.id = sot.StorageID;

select *
from bm_StorageOperations_Table as sot
join product as p on p.id = sot.ProductID;

-- закупки: у каждой операции должен находиться склад
select *
from bm_StorageOperations as so
join storages as st on st.id = so.StorageID;

-- закупки: связь с договорами (таблица пустая, поэтому строк не будет)
select *
from bm_StorageOperations as so
join bm_Contracts as c on c.ID = so.ContractID;

-- продажи: к каждой цене находится товар
select *
from pricelist as pl
join product as p on p.id = pl.productid;

-- продажи: цена оформлена документом
select *
from pricelist as pl
join bm_JournalBarnetDocs as jd on jd.ID = pl.DocumentID;

-- поставщики: к каждой операции находится поставщик
select *
from bm_StorageOperations as so
join vendors as v on v.id = so.VendorID;

-- персонал: к каждой записи о бонусах находится сотрудник
select *
from bm_BonusHistory as bh
join personnel as p on p.personid = bh.PersonID;

-- остатки: к складской операции находится документ
select *
from bm_StorageOperations_Table as sot
join bm_JournalBarnetDocs as jd on jd.ID = sot.DocumentID;

-- остатки: позиция журнала связана с товаром
select *
from bm_Journal_Details as d
join product as p on p.id = d.ProductID;

/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%'
   or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select ps.SupplierID, ps.SupplierName
from Purchasing.Suppliers as ps
         left join Purchasing.PurchaseOrders as ppo
                   on ps.SupplierID = ppo.SupplierID
where ppo.SupplierID is NULL


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
select orders.OrderID,
       format(orders.OrderDate, 'dd.MM.yyy') as OrderDate,
       DATENAME(month, orders.OrderDate)     as Month,
       DATEPART(quarter, orders.OrderDate)   as Quarter,
       case
           when DATEPART(month, orders.OrderDate) between 1 and 4 then 1
           when DATEPART(month, orders.OrderDate) between 5 and 8 then 2
           when DATEPART(month, orders.OrderDate) between 9 and 12 then 3
           end                               as 'Third of Year',
       orders.Customer
from (select so.OrderID,
             so.OrderDate,
             sc.CustomerName as Customer
      from Sales.Orders as so
               join Sales.OrderLines as sol on sol.OrderID = so.OrderID
               join Sales.Customers as sc on sc.CustomerID = so.CustomerID
      where (sol.UnitPrice > 100 or sol.Quantity > 20)
      group by so.OrderID,
               so.OrderDate,
               sc.CustomerName) as orders
order by Quarter, 'Third of Year', OrderDate

select orders.OrderID,
       format(orders.OrderDate, 'dd.MM.yyy') as OrderDate,
       DATENAME(month, orders.OrderDate)     as Month,
       DATEPART(quarter, orders.OrderDate)   as Quarter,
       case
           when DATEPART(month, orders.OrderDate) between 1 and 4 then 1
           when DATEPART(month, orders.OrderDate) between 5 and 8 then 2
           when DATEPART(month, orders.OrderDate) between 9 and 12 then 3
           end                               as 'Third of Year',
       orders.Customer
from (select so.OrderID,
             so.OrderDate,
             sc.CustomerName as Customer
      from Sales.Orders as so
               join Sales.OrderLines as sol
                    on sol.OrderID = so.OrderID
               join Sales.Customers as sc
                    on sc.CustomerID = so.CustomerID
      where (sol.UnitPrice > 100 or sol.Quantity > 20)
      group by so.OrderID,
               so.OrderDate,
               sc.CustomerName) as orders
order by Quarter, 'Third of Year', OrderDate
offset 1000 rows fetch next 1000 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select adm.DeliveryMethodName,
       ppo.ExpectedDeliveryDate,
       ps.SupplierName,
       ap.FullName
from Purchasing.Suppliers as ps
         join Purchasing.PurchaseOrders as ppo
              on ppo.SupplierID = ps.SupplierID
         join Application.DeliveryMethods as adm
              on adm.DeliveryMethodID = ppo.DeliveryMethodID
         join Application.People as ap
              on ap.PersonID = ppo.ContactPersonID
where ppo.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
  and adm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
  and ppo.IsOrderFinalized = 'true'

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select ap_client.FullName   as client,
       ap_customer.FullName as customer,
       so.OrderDate
from Sales.Orders as so
         join Application.People as ap_client
              on ap_client.PersonID = so.ContactPersonID
         join Application.People as ap_customer
              on ap_customer.PersonID = so.SalespersonPersonID
order by so.OrderDate desc
offset 0 rows fetch next 10 rows only

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select so.ContactPersonID, ap.FullName, ap.PhoneNumber
from Sales.Orders as so
         join Sales.OrderLines as sol on sol.OrderID = so.OrderID
         join Application.People as ap
              on ap.PersonID = so.ContactPersonID
         join Warehouse.StockItems as wsi
              on wsi.StockItemID = sol.StockItemID
where wsi.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(si.InvoiceDate)              as sale_of_year,
       month(si.InvoiceDate)             as sale_of_month,
       sum(sil.Quantity * sil.UnitPrice) /
       sum(sil.Quantity)                 as 'mean sale by month',
       sum(sil.Quantity * sil.UnitPrice) as 'total sale by month'
from Sales.Invoices as si
         join Sales.InvoiceLines as sil on sil.InvoiceID = si.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate)
order by sale_of_year, sale_of_month


/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(si.InvoiceDate)                             as sale_of_year,
       month(si.InvoiceDate)                            as sale_of_month,
       cast(sum(sil.Quantity * sil.UnitPrice) as float) as 'total sale by month'
from Sales.Invoices as si
         join Sales.InvoiceLines as sil on sil.InvoiceID = si.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate)
having cast(sum(sil.Quantity * sil.UnitPrice) as float) > 10000
order by year(si.InvoiceDate), month(si.InvoiceDate)

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(si.InvoiceDate)                             as sale_of_year,
       month(si.InvoiceDate)                            as sale_of_month,
       sil.Description,
       cast(sum(sil.Quantity * sil.UnitPrice) as float) as 'total sale by month',
       sum(sil.Quantity)                                as 'total count',
       min(si.InvoiceDate)                              as 'first sale'
from Sales.Invoices as si
         join Sales.InvoiceLines as sil on sil.InvoiceID = si.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate), sil.Description
having sum(sil.Quantity) < 50



-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

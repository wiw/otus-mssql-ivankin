/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson),
и не сделали ни одной продажи 04 июля 2015 года.
Вывести ИД сотрудника и его полное имя.
Продажи смотреть в таблице Sales.Invoices.
*/

select ap.PersonID, ap.FullName
from Application.People ap
where IsSalesperson = 'true'
  and ap.PersonID not in (select SalespersonPersonID
                          from Sales.Invoices
                          where InvoiceDate = '2015-07-04')


with person(SalespersonPersonID) as (select SalespersonPersonID
                                     from Sales.Invoices
                                     where InvoiceDate = '2015-07-04')
select ap.PersonID, ap.FullName, person.SalespersonPersonID
from Application.People ap
         left join person on ap.PersonID = person.SalespersonPersonID
where IsSalesperson = 'true'
  and person.SalespersonPersonID is null

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса.
Вывести: ИД товара, наименование товара, цена.
*/

Select StockItemID, StockItemName, RecommendedRetailPrice
from Warehouse.StockItems
where RecommendedRetailPrice =
      (select min(RecommendedRetailPrice) from Warehouse.StockItems)

with minimal_price(min_price)
         as (select min(RecommendedRetailPrice) as min_price
             from Warehouse.StockItems)
Select wsi.StockItemID, wsi.StockItemName, wsi.RecommendedRetailPrice
from Warehouse.StockItems as wsi
         join minimal_price
              on wsi.RecommendedRetailPrice = minimal_price.min_price

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей
из Sales.CustomerTransactions.
Представьте несколько способов (в том числе с CTE).
*/

select TOP (5) sct.AmountExcludingTax as totalCost,
               ap.PersonID,
               ap.FullName,
               ap.PhoneNumber,
               ap.EmailAddress
from Sales.CustomerTransactions as sct
         join Application.People as ap on ap.PersonID = sct.CustomerID
where sct.IsFinalized = 'true'
order by totalCost desc


with top_customer as (select sct.AmountExcludingTax as totalCost,
                             sct.CustomerID
                      from Sales.CustomerTransactions as sct
                      where sct.IsFinalized = 'true'),
     joined as (select tc.totalCost,
                       ap.PersonID,
                       ap.FullName,
                       ap.PhoneNumber,
                       ap.EmailAddress
                from top_customer as tc
                         join Application.People as ap
                              on ap.PersonID = tc.CustomerID)
select *
from joined
order by totalCost desc
offset 0 rows fetch next 5 rows only

select TOP (5) sct.AmountExcludingTax as totalCost,
               ap.PersonID,
               ap.FullName,
               ap.PhoneNumber,
               ap.EmailAddress
from Sales.CustomerTransactions as sct
         join Application.People as ap on ap.PersonID = sct.CustomerID
where sct.IsFinalized = 'true'
order by totalCost desc

/*
4. Выберите города (ид и название), в которые были доставлены товары,
входящие в тройку самых дорогих товаров, а также имя сотрудника,
который осуществлял упаковку заказов (PackedByPersonID).
*/
select ac.CityID, ac.CityName, ap.FullName as packed_person
from (Select si.CustomerID, si.PackedByPersonID
      from Sales.Invoices as si
      where si.InvoiceID in (select sil.InvoiceID
                             from Sales.InvoiceLines as sil
                             where sil.StockItemID in (select top3.StockItemID
                                                       from (Select TOP (3) RecommendedRetailPrice,
                                                                            StockItemID
                                                             from Warehouse.StockItems
                                                             order by RecommendedRetailPrice desc) as top3))) as pp
         join Sales.Customers as sc on sc.CustomerID = pp.CustomerID
         join Application.People as ap on ap.PersonID = pp.PackedByPersonID
         join Application.Cities as ac on ac.CityID = sc.DeliveryCityID
group by ac.CityID, ac.CityName, ap.FullName
order by ap.FullName,
         ac.CityName

with top3 as (
    Select TOP (3) RecommendedRetailPrice,
                   StockItemID
    from Warehouse.StockItems
    order by RecommendedRetailPrice desc
),
     filtered_top3 as (
         select StockItemID
         from top3
     ),
     invoices as (
         select sil.InvoiceID
         from Sales.InvoiceLines as sil
                  join filtered_top3
                       on sil.StockItemID = filtered_top3.StockItemID
     ),
     joined as (
         Select si.CustomerID,
                si.PackedByPersonID,
                ac.CityID,
                ac.CityName,
                ap.FullName
         from Sales.Invoices as si
                  join invoices on si.InvoiceID = invoices.InvoiceID
                  join Sales.Customers as sc on sc.CustomerID = si.CustomerID
                  join Application.People as ap
                       on ap.PersonID = si.PackedByPersonID
                  join Application.Cities as ac on ac.CityID = sc.DeliveryCityID
     )
select joined.CityID, joined.CityName, joined.FullName as packed_person
from joined
group by joined.CityID, joined.CityName, joined.FullName
order by joined.FullName, joined.CityName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса,
-- так и в сторону упрощения плана\ускорения.
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON.
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы).
-- Напишите ваши рассуждения по поводу оптимизации.

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT Invoices.InvoiceID,
       Invoices.InvoiceDate,
       (SELECT People.FullName
        FROM Application.People
        WHERE People.PersonID = Invoices.SalespersonPersonID
       )                     AS SalesPersonName,
       SalesTotals.TotalSumm AS TotalSummByInvoice,
       (SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
        FROM Sales.OrderLines
        WHERE OrderLines.OrderId = (SELECT Orders.OrderId
                                    FROM Sales.Orders
                                    WHERE Orders.PickingCompletedWhen IS NOT NULL
                                      AND Orders.OrderId = Invoices.OrderId)
       )                     AS TotalSummForPickedItems
FROM Sales.Invoices
         JOIN
     (SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
      FROM Sales.InvoiceLines
      GROUP BY InvoiceId
      HAVING SUM(Quantity * UnitPrice) > 27000) AS SalesTotals
     ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение

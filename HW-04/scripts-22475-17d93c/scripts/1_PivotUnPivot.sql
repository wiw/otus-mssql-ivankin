Use AdventureWorks2017;

SELECT DaysToManufacture, StandardCost 
		FROM Production.Product;

SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, [0], [1], [2], [3], [4]
FROM (SELECT DaysToManufacture, StandardCost 
		FROM Production.Product) AS SourceTable
PIVOT ( AVG(StandardCost) FOR DaysToManufacture
	IN ([0], [1], [2], [3], [4])
) AS PivotTable;


---
WITH PivotData AS
(SELECT DaysToManufacture, StandardCost 
		FROM Production.Product
)
SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, [0], [1], [2], [3], [4]
FROM PivotData
PIVOT ( AVG(StandardCost) FOR DaysToManufacture
	IN ([0], [1], [2], [3], [4])
) AS PivotTable;

-----------
use WideWorldImporters;

-- по годам
SELECT * FROM 
	(
	SELECT YEAR(ord.OrderDate) as SalesYear,
			L.UnitPrice*L.Quantity as TotalSales
	 FROM Sales.Orders AS ord 
		 JOIN Sales.OrderLines L ON ord.OrderID = L.OrderID
	) AS Sales
PIVOT (sum(TotalSales)
FOR SalesYear IN ([2013],[2014],[2015],[2016]))
as PVT_my;

--https://www.codeproject.com/Tips/500811/Simple-Way-To-Use-Pivot-In-SQL-Query
-- по месяцам
 SET LANGUAGE russian;
SELECT *
FROM (
    SELECT 
        year(I.InvoiceDate) as [year],left(datename(month,I.InvoiceDate),3)as [month], 
         Trans.TransactionAmount as Amount 
    FROM Sales.Invoices AS I
		JOIN Sales.CustomerTransactions AS Trans
			ON I.InvoiceId = Trans.InvoiceID
) as s
PIVOT
(
    SUM(Amount)
    FOR [month] IN (Янв, Фев, Мар, Апр, Май, Июн, Июл, Авг, Сен, Окт, Ноя, Дек)
)AS pvt
order by [year];

--
Use AdventureWorks2017;

SELECT SalesYear, 
       ISNULL([1], 0) AS Jan, 
       ISNULL([2], 0) AS Feb, 
       ISNULL([3], 0) AS Mar, 
       ISNULL([4], 0) AS Apr, 
       ISNULL([5], 0) AS May, 
       ISNULL([6], 0) AS Jun, 
       ISNULL([7], 0) AS Jul, 
       ISNULL([8], 0) AS Aug, 
       ISNULL([9], 0) AS Sep, 
       ISNULL([10], 0) AS Oct, 
       ISNULL([11], 0) AS Nov, 
       ISNULL([12], 0) AS Dec, 
       (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([4], 0) + ISNULL([5], 0) + ISNULL([6], 0) + ISNULL([7], 0) + ISNULL([8], 0) + ISNULL([9], 0) + ISNULL([10], 0) + ISNULL([11], 0) + ISNULL([12], 0)) SalesYTD
FROM
(   SELECT YEAR(SOH.OrderDate) AS SalesYear, 
           DATEPART(MONTH, SOH.OrderDate) Months,
          SOH.SubTotal AS TotalSales
    FROM sales.SalesOrderHeader SOH
         JOIN sales.SalesOrderDetail SOD ON SOH.SalesOrderId = SOD.SalesOrderId
 ) AS Data 
 PIVOT (SUM(TotalSales) 
 FOR Months IN([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS pvt 
   order by SalesYear;



--по кварталам
use WideWorldImporters;

SELECT SalesYear, 
       ISNULL([Q1], 0) AS Q1, 
       ISNULL([Q2], 0) AS Q2, 
       ISNULL([Q3], 0) AS Q3, 
       ISNULL([Q4], 0) AS Q4, 
       (ISNULL([Q1], 0) + ISNULL([Q2], 0) + ISNULL([Q3], 0) + ISNULL([Q4], 0)) SalesYTD
FROM
(
    SELECT YEAR(OH.OrderDate) AS SalesYear, 
           CAST('Q'+CAST(DATEPART(QUARTER, OH.OrderDate) AS VARCHAR(1)) AS VARCHAR(2)) AS Quarters, 
           SUM(L.UnitPrice*L.Quantity) AS TotalSales
    FROM Sales.Orders OH
         JOIN Sales.OrderLines L ON OH.OrderId = L.OrderId
	GROUP BY YEAR(OH.OrderDate), 
           CAST('Q'+CAST(DATEPART(QUARTER, OH.OrderDate) AS VARCHAR(1)) AS VARCHAR(2))
 ) AS Data 
 PIVOT(SUM(TotalSales) FOR Quarters 
	IN([Q1], 
       [Q2], 
       [Q3], 
       [Q4])) 
	   AS pvt
ORDER BY SalesYear;

--- error
SELECT * 
	FROM (
		SELECT YEAR(ord.OrderDate) as SalesYear,
				L.UnitPrice*L.Quantity as TotalSales
		 FROM Sales.Orders AS ord 
			 JOIN Sales.OrderLines L ON ord.OrderID = L.OrderID
		) AS Sales
		PIVOT (SUM(TotalSales), AVG(TotalSales)
		FOR SalesYear IN ([2013],[2014],[2015],[2016]))
		as PVT;


--- unpivot
SELECT SalesYear,TotalSales
FROM (
	SELECT * 
	FROM (
		SELECT YEAR(ord.OrderDate) as SalesYear,
				L.UnitPrice*L.Quantity as TotalSales
		 FROM Sales.Orders AS ord 
			 JOIN Sales.OrderLines L ON ord.OrderID = L.OrderID
		) AS Sales
		PIVOT (SUM(TotalSales)
		FOR SalesYear IN ([2013],[2014],[2015],[2016]))
		as PVT
) T UNPIVOT(TotalSales FOR SalesYear IN([2013],
                                        [2014],
										[2015],
										[2016])) AS upvt;

---
        SELECT 
			PersonID,
			FullName,
			PreferredName,
			LogonName,*
		FROM Application.People;

SELECT *
FROM (
		SELECT 
			PersonID,
			FullName,
			PreferredName,
			LogonName
		FROM Application.People
	) AS People
UNPIVOT (PersonName FOR Name IN (FullName, PreferredName, LogonName)) AS unpt;

--type 
--all columns should be the same type
SELECT *
FROM (
		SELECT 
			PersonID,
			FullName,
			PreferredName,
			LogonName,
			PersonID AS IDEx
		FROM Application.People
	) AS People
UNPIVOT (PersonName FOR Name IN (IDEx, FullName, PreferredName, LogonName)) AS unpt;



--- key value
--Таблицы настроек
DROP TABLE IF EXISTS settings_type;
DROP TABLE IF EXISTS settings_value;
DROP TABLE IF EXISTS point;


CREATE TABLE settings_type
(settings_type_id INT IDENTITY(1,1) PRIMARY KEY,
 settings_type_name VARCHAR(50),
 settings_type_description VARCHAR(128),
 settings_default_value VARCHAR(128));

 CREATE TABLE point
(point_id BIGINT IDENTITY(1,1) PRIMARY KEY,
 point_name VARCHAR(128),
 point_address VARCHAR(256));

CREATE TABLE settings_value
(settings_id BIGINT IDENTITY(1,1) PRIMARY KEY,
 point_id BIGINT, 
 settings_type_id INT,
 settings_value VARCHAR(128));

INSERT INTO settings_type
(settings_type_name, settings_type_description, settings_default_value)
VALUES
('t','температура','25'),
('printer','printer type',''),
('modem','modem',''),
('cash system','','');

INSERT INTO point
(point_name, point_address)
VALUES 
('Terminal A','Saratov'),
('Terminal B','Rostov'),
('Terminal C','Moscow');

INSERT INTO settings_value
(point_id, settings_type_id, settings_value)
VALUES 
(1,1,'15'),
(1,2,'Canon 25'),
(1,3,'Seagate 1'),
(1,4,'BS 11'),
(2,1,'27'),
(2,2,'HTP 616'),
(2,3,'CMD11'),
(2,4,'UMD 4'),
(3,1,'20'),
(3,2,'HP 77'),
(3,3,'RM 1'),
(3,4,'BS 11');

SELECT 
  point.point_id,
  point.point_address,
  st.settings_type_name,
  sv.settings_value
FROM point 
	JOIN settings_value AS sv ON 
	  point.point_id = sv.point_id
	JOIN settings_type AS st ON
	  sv.settings_type_id = st.settings_type_id;


WITH settings AS
(
	SELECT 
	  point.point_id,
	  point.point_address,
	  st.settings_type_name,
	  sv.settings_value
	FROM point 
		JOIN settings_value AS sv ON 
		  point.point_id = sv.point_id
		JOIN settings_type AS st ON
		  sv.settings_type_id = st.settings_type_id
)
SELECT
	*
FROM settings
PIVOT (MIN(settings_value) --должно быть только 1 значение для одного типа и одной точки
FOR settings_type_name 
	IN([t], 
       [printer], 
       [modem], 
       [cash system]))
	   AS pvt;

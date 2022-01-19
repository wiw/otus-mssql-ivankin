USE WideWorldImporters; 

--� ���������� ����� ������� ������ 0 ��� 1 ������
SELECT C.CustomerName, (SELECT TOP 1 OrderId
                FROM Sales.Orders O
                WHERE O.CustomerID = C.CustomerID
					AND OrderDate < '2014-01-01'
                ORDER BY O.OrderDate DESC, O.OrderID DESC)
FROM Sales.Customers C
ORDER BY C.CustomerName;

SET STATISTICS IO,TIME ON;

--��������� 2 ������, ������ Inner join
SELECT C.CustomerName, O.*
FROM Sales.Customers C
CROSS APPLY (SELECT TOP 2 *
                FROM Sales.Orders O
                WHERE O.CustomerID = C.CustomerID
					AND OrderDate < '2014-01-01'
                ORDER BY O.OrderDate DESC, O.OrderID DESC) AS O
ORDER BY C.CustomerName;


--��������� 2 ������, ������ Inner join
SELECT C.CustomerName, O.*
FROM Sales.Customers C
INNER JOIN (SELECT TOP 2 CustomerID, O.OrderID, O.OrderDate
                FROM Sales.Orders O
                WHERE --O.CustomerID = C.CustomerID AND
					 OrderDate < '2014-01-01'
                ORDER BY O.OrderDate DESC, O.OrderID DESC) AS O ON 
				O.CustomerID = C.CustomerID
ORDER BY C.CustomerName;

--��������� 2 ������, ������ Inner join
SELECT C.CustomerName, O.*
FROM Sales.Customers C
INNER JOIN (SELECT CustomerID, O.OrderID, O.OrderDate
            FROM (
			SELECT CustomerID, O.OrderID, O.OrderDate, ROW_NUMBER() OVER ( PARTITION BY O.CustomerID ORDER BY O.OrderDate DESC, O.OrderID DESC) as RN
                FROM Sales.Orders AS O
                WHERE OrderDate < '2014-01-01') AS O
			WHERE rn < 3) AS O ON 
				O.CustomerID = C.CustomerID
ORDER BY C.CustomerName;

--��������� 2 ������, ������ Left join
SELECT C.CustomerName, O.*
FROM Sales.Customers C
OUTER APPLY (SELECT TOP 2 *
                FROM Sales.Orders O
                WHERE O.CustomerID = C.CustomerID
					AND OrderDate < '2014-01-01'
                ORDER BY O.OrderDate DESC, O.OrderID DESC) AS O
ORDER BY C.CustomerName;


--function call
SELECT C.CustomerName, O.*
FROM Sales.Customers C
OUTER APPLY [Sales].[fnGetInvoiceMetricsByBillToCustomerID](C.CustomerID) AS O
ORDER BY C.CustomerName;

--- �������������� � APPLY
--alter table Sales.Customers add LastInvoiceId int ;
--update Sales.Customers set LastInvoiceId = NULL;

select top 10 LastInvoiceId, *
FROM Sales.Customers;
 
UPDATE C
SET LastInvoiceId = LatestTransaction.InvoiceID
FROM Sales.Customers AS C
CROSS APPLY (
	SELECT TOP 1 Invoices.InvoiceId, Invoices.InvoiceDate, trans.TransactionAmount
		FROM Sales.Invoices as Invoices
			join Sales.CustomerTransactions as trans
				ON Invoices.InvoiceID = trans.InvoiceID
	WHERE Invoices.CustomerID = C.CustomerID
	ORDER BY Invoices.InvoiceDate DESC
	) AS LatestTransaction;

--alter table Sales.Customers drop column LastInvoiceId;





SELECT DATEADD(hh,DATEDIFF(hh,0,GETDATE()),0), GETDATE(), DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)

-- ����� group by � apply
SELECT CAST(DATEADD(mm,DATEDIFF(mm,0,P.OrderDate),0) AS DATE) AS PurchaseOrderMonth,
	COUNT(*) AS PurchaseCount
FROM Purchasing.PurchaseOrders AS P
GROUP BY CAST(DATEADD(mm,DATEDIFF(mm,0,P.OrderDate),0) AS DATE)
ORDER BY CAST(DATEADD(mm,DATEDIFF(mm,0,P.OrderDate),0) AS DATE);

--cross apply
SELECT CA.PurchaseOrderMonth,
	COUNT(*) AS PurchaseCount
FROM Purchasing.PurchaseOrders AS P
CROSS APPLY (SELECT CAST(DATEADD(mm,DATEDIFF(mm,0,P.OrderDate),0) AS DATE) AS PurchaseOrderMonth) AS CA
GROUP BY CA.PurchaseOrderMonth
ORDER BY CA.PurchaseOrderMonth;

-------------
CREATE TABLE #t
(
   ID int identity(1,1)
  ,ListOfNums varchar(50)
);

insert #t
values ('279,37,972,15,175')
      ,('17,72')
      ,('672,52,19,23')
      ,('153,798,266,52,29')
      ,('77,349,14')
select * from #t;
-- 2, 5, 3, 1
--���������� ������� ������, � ������� � 4 ������� ����� ������ 50
--� ������������� �� 3 �������
select ID
      ,ListOfNums,
	  convert(int,substring(ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1,
		  (charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1)-
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,')+1)+1))-1)) AS Num4 
from #t
where convert(int,substring(ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1,
		  (charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1)-
		  charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
		  charindex(',',ListOfNums+',,,,')+1)+1))-1)) < 50
order by convert(int,substring(ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
         charindex(',',ListOfNums+',,,,')+1)+1,(charindex(',',ListOfNums+',,,,',
         charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)-
         charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1))-1));


select ID,
	ListOfNums,
	Num4
from #t
cross apply (select WorkString=ListOfNums+',,,,') F_Str
cross apply (select p1=charindex(',',WorkString)) F_P1
cross apply (select p2=charindex(',',WorkString,p1+1)) F_P2
cross apply (select p3=charindex(',',WorkString,p2+1)) F_P3
cross apply (select p4=charindex(',',WorkString,p3+1)) F_P4      
cross apply (select Num3=convert(int,substring(WorkString,p2+1,p3-p2-1))
                   ,Num4=convert(int,substring(WorkString,p3+1,p4-p3-1))) F_Nums
where Num4<50
order by Num3;

DROP TABLE IF EXISTS #t;
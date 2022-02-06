---1 �������� ���� ������ �� ���������
CREATE DATABASE test1_new;
GO

---- �������� ���� ������
drop database test1_new;

---2 � ��������� ������
CREATE DATABASE [test2]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = test2, FILENAME = N'D:\1-DDL\test2.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
 LOG ON 
( NAME = test2_log, FILENAME = N'D:\1-DDL\test2_log.ldf' , 
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB )
GO

---- �������� ���� ������
drop database test2;

-- ���

USE master; 
GO 
IF DB_ID (N'test2') IS NOT NULL 
	DROP DATABASE test2; 
GO 


---3 � ��������� ��������
CREATE DATABASE [test2]
 CONTAINMENT = NONE
 ON  PRIMARY 
	( NAME = test2, FILENAME = N'D:\1-DDL\test2.mdf' , 
		SIZE = 8MB , 
		MAXSIZE = 50Mb, 
		FILEGROWTH = 10MB ),
	( NAME = test2_2, FILENAME = N'D:\1-DDL\test2_2.mdf' , 
		SIZE = 8MB , 
		MAXSIZE = 50Mb, 
		FILEGROWTH = 10% ),

	FILEGROUP test2_gr2
	( NAME = test2_f1, FILENAME = N'E:\2-DDL\test2_f1.ndf',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%),
	
	( NAME = test2_f2,
	  FILENAME = N'E:\2-DDL\test2_f2.ndf',
          SIZE = 10MB,
          MAXSIZE = 50MB,
          FILEGROWTH = 10%)

 LOG ON 
	( NAME = test2_log, FILENAME = N'D:\1-DDL\test2_log.ldf' , 
		SIZE = 8MB , 
		MAXSIZE = 10GB , 
		FILEGROWTH = 65536KB ),
	( NAME = test2_log_f, FILENAME = N'E:\2-DDL\test2_log_f.ldf' , 
		SIZE = 10MB , 
		MAXSIZE = 50GB , 
		FILEGROWTH = 10Mb )
GO

-- 4 �������������� ��
--���������� 3-�� ����� ������ � �������� ������ 2
use test2;

ALTER DATABASE [test2] 
ADD FILE 
( 
    NAME = N'test2_f3', 
    FILENAME = N'E:\2-DDL\test2_f3.ndf', 
    MAXSIZE = 100MB 
) 
TO FILEGROUP [test2_gr2] 
GO  

-- ��������� ����� ��
USE master; 
GO 
ALTER DATABASE test1_new 
Modify Name = test1 ; 
GO

--- ���������� �������� ������, ����� ������ � ������� � ����� ������  
ALTER DATABASE test1 
ADD FILEGROUP test1_FG2; 
GO 

ALTER DATABASE test1 
ADD FILE  
( 
    NAME = N'test1_f1', 
    FILENAME = N'C:\0-DDL\test1_f1.ndf', 
    SIZE = 5MB, 
    MAXSIZE = 100MB,
	FILEGROWTH = 5MB 
)
 TO FILEGROUP test1_FG2; 
GO 

ALTER DATABASE test1 
ADD LOG FILE  
( 
    NAME = N'test1_log_f1', 
    FILENAME = N'E:\2-DDL\test1_log_f1.ldf', 
    SIZE = 5MB, 
    MAXSIZE = 100MB,
	FILEGROWTH = 5MB 
); 
GO 

---��������� ������� 
ALTER DATABASE test1  
MODIFY FILE 
    (NAME = N'test1_new', 
    SIZE = 5MB);
GO  

drop database test1;

create database test1;

USE master; 
GO 

SELECT DB_ID (N'test1')
IF DB_ID (N'test1') IS NOT NULL 
	DROP DATABASE test1; 

----5 �������� ������
use test2;
GO

CREATE TABLE student(
	id 	int not null identity(1, 1)  primary key,
	fio	varchar(50) ,
	d_r	date 
);

EXEC sp_help student;

insert into student values	('������', '2000-03-10'), 
							('������', '2001-04-20'),
							('�������', '1999-10-19');

---6 �������� ������������� ������ ����

CREATE DATABASE test2_copy1 ON
( NAME = test2 , FILENAME = 'C:\0-DDL\test2_copy1.ss' ),
( NAME = test2_2, FILENAME = 'C:\0-DDL\test2_copy2.ss' ),
( NAME = test2_f1, FILENAME = 'C:\0-DDL\test2_copy_f1.ss' ),
( NAME = test2_f2, FILENAME = 'C:\0-DDL\test2_copy_f2.ss' ),
( NAME = test2_f3, FILENAME = 'C:\0-DDL\test2_copy_f3.ss' )
AS SNAPSHOT OF test2;
GO

use test2_copy1;
select * from student;

insert into student values	('������ 2', '10/03/2000'); 

use master;
drop database test2_copy1;

------ 7 �������� ����� �����
use test2;
GO

CREATE SCHEMA sch_2; 

--- �������� ������� � ����� ����� � ������ ������
CREATE TABLE sch_2.student(
	id 	int not null identity(1, 1)  primary key,
	fio	varchar(50) ,
	d_r	date 
) on test2_gr2;


EXEC sp_help 'sch_2.student';

EXEC sp_help student;

SELECT * FROM student;

SELECT * FROM sch_2.student;

-- 8 �������� ������� � ����������� ��������
CREATE TABLE Tablesparse (
	id	int PRIMARY KEY,
	field1 varchar(50) SPARSE NULL 
) ;

use test1;
---9 �������� ��������
CREATE TABLE table1(
	id 	int not null identity(1, 1)  primary key,
	fio	varchar(50) ,
	d_r	date 
);

CREATE TABLE test(
	id 	int not null identity(1, 1)  primary key,
	fio	varchar(50) ,
	d_r	date 
);

CREATE SYNONYM db_test1 FOR test1.dbo.table1;

CREATE SYNONYM test FOR test1.dbo.table1;

use test2;
select * from db_test1;

select * from test1.dbo.table1;


CREATE SYNONYM st FOR [sch_2].[student];

SELECT * FROM st;

use test1;
CREATE TABLE table1(
	id 	int not null identity(1, 1)  primary key,
	fio	varchar(50)
)
GO


--- 10 �������������� ������
-----
use test2;

CREATE TABLE kurs(
	id 			int not null identity(1, 1)  primary key,		
	name_k 		varchar(100) ,
	autor 		varchar(50)  ,
	price 		money 
);


CREATE TABLE vebinar (
	id 	int not null identity(1, 1)  primary key,
	id_s 		int not null ,
	id_k 		int not null ,
	name_v  	varchar(100) ,
	fio_v		varchar (50) ,
	date_v		datetime,
	d_z			int  
)

-- ������������ �����
ALTER TABLE vebinar  ADD  CONSTRAINT FK_v_st FOREIGN KEY(id_s)
REFERENCES student (id)
ON UPDATE CASCADE
ON DELETE CASCADE


ALTER TABLE vebinar  ADD  CONSTRAINT FK_v_k FOREIGN KEY(id_k)
REFERENCES kurs (id)


--------- �������� �� ���������
--��� ���������� ����� ������ � ���� ��������� ������� �� ��������� ��������� 0
ALTER TABLE vebinar ADD  CONSTRAINT v_dz DEFAULT (0) FOR d_z;

---- ����������� �� �������� - ��������� ����� ������ ��������� c 18 ��� 
ALTER TABLE student 
	ADD CONSTRAINT constr_dr 
		CHECK (datediff(yy, d_r, getdate()) >=18);

--��������� � ����������� �����������
insert into student values	('�������', '2010-03-10'); 

ALTER TABLE student NOCHECK CONSTRAINT constr_dr;

insert into student values	('�������', '2010-03-10'); 

ALTER TABLE student CHECK CONSTRAINT constr_dr;

SELECT * 
FROM student;

--- �������� �����������
ALTER TABLE student  DROP CONSTRAINT constr_dr;

----12 �������� �������
create index idx_fio on student (fio);

EXEC sp_help student;


---11 �������� ������������������
CREATE SEQUENCE example_seq
  AS int
  START WITH 1
  INCREMENT BY 1
  MINVALUE 0
  MAXVALUE 3
  CYCLE;

select next value for example_seq;

drop sequence example_seq;

CREATE SEQUENCE table_seq
  START WITH 1
  INCREMENT BY 1;
  
create table customer(
id int primary key,
fio varchar(50));

insert into customer values (
NEXT VALUE FOR table_seq, '����2');

select * from customer 

create table customer_2(
id int primary key CONSTRAINT id_sec DEFAULT (NEXT VALUE FOR table_seq) ,
fio varchar(50));

insert into customer_2(fio) values ('����2');


select * from customer_2;


ALTER TABLE sch_2.student 
	ADD e_mail varchar(50) constraint e_mail_un unique;


--- 13 system versioned tables
use WideWorldImporters

SELECT ValidFrom, ValidTo, *
FROM Sales.Customers
WHERE CustomerName like 'J%'
ORDER BY CustomerID

SELECT ValidFrom, ValidTo, *
-- FROM Sales.Customers FOR System_Time AS OF '20130101'
 --FROM Sales.Customers FOR System_Time BETWEEN '20121201' AND '20120501'
-- FROM Sales.Customers FOR System_Time FROM '20121201' TO '20130101'
 FROM Sales.Customers FOR System_Time CONTAINED IN ('20130501' ,'20190212')
WHERE CustomerName like 'J%'	
ORDER BY CustomerID

SELECT ValidFrom, ValidTo, c.*
FROM Sales.Customers FOR System_Time ALL c
WHERE CustomerName like 'J%'	
ORDER BY c.CustomerID, c.ValidFrom

---
use test2;

--- � ��������� �������� ������
CREATE TABLE Course
(
    ID INT NOT NULL PRIMARY KEY CLUSTERED
  , CourseName VARCHAR(50) NOT NULL
  , StartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
  , EndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
  , PERIOD FOR SYSTEM_TIME (StartTime, EndTime)
)
WITH (SYSTEM_VERSIONING = ON);

insert into Course(ID, CourseName) values (1, '��');

update Course set CourseName = 'DataBase';

delete from Course;

select * from Course FOR System_Time ALL;

--- � �������� ������ �� ��������� 
CREATE TABLE Course2
(
    ID INT NOT NULL PRIMARY KEY CLUSTERED
  , CourseName VARCHAR(50) NOT NULL
  , StartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
  , EndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
  , PERIOD FOR SYSTEM_TIME (StartTime, EndTime)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sch_2.CourseHistory));

ALTER TABLE Course2 SET (SYSTEM_VERSIONING = OFF);

drop table Course2;
drop table sch_2.CourseHistory;

----
insert into Course(ID, CourseName)
	values(1, 'SQL Developer');

select * from Course;
update Course set CourseName = 'SQL Developer 2022' where id = 1;

select * from Course FOR System_Time ALL;

delete from Course where id = 1;

-----14 �������� �������
CREATE TABLE Person (ID INTEGER PRIMARY KEY, Name VARCHAR(100), Age INT) AS NODE;
CREATE TABLE friends (StartDate date) AS EDGE;

select * from Person;

insert into Person(ID, Name, Age) 
values  (1, '����', 18),
		(2, '���', 17),
		(3, '����', 20);

select * from friends;

insert into friends
values  ((SELECT $node_id FROM Person WHERE ID = 1), 
			(SELECT $node_id FROM Person WHERE ID = 2), '2021-01-20'),
		((SELECT $node_id FROM Person WHERE ID = 1), 
			(SELECT $node_id FROM Person WHERE ID = 1), '2021-01-20'),
		((SELECT $node_id FROM Person WHERE ID = 1), 
			(SELECT $node_id FROM Person WHERE ID = 3), '2021-02-15'),
		((SELECT $node_id FROM Person WHERE ID = 2), 
			(SELECT $node_id FROM Person WHERE ID = 3), '2021-02-04'),
		((SELECT $node_id FROM Person WHERE ID = 3), 
			(SELECT $node_id FROM Person WHERE ID = 1), '2021-02-16');


SELECT Person2.Name 
FROM Person Person1, friends, Person Person2
WHERE MATCH(Person1-(friends)->Person2)
AND Person1.Name = '����';

--- 15 �������� 
use test2;

drop table if exists sch_2.student;

select * from student 
delete from student;
insert into student values	('�������', '2000-03-10'); 

truncate table student;
alter table vebinar drop constraint fk_v_st;

insert into student values	('�������', '2000-03-10'); 

truncate table customer;
insert into customer values	(NEXT VALUE FOR table_seq, '�������'); 
select * from customer
-----
truncate table Course

USE master; 
GO 

IF DB_ID (N'test2') IS NOT NULL 
	DROP DATABASE test2; 
GO 
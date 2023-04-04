USE master;

/*
use master 
go
alter database WWI_DM set single_user with rollback immediate

drop database WWI_DM

*/
GO
CREATE DATABASE WWI_DM;

USE WWI_DM;
GO

CREATE TABLE dbo.DimLocations(--type1 SCD
	LocationKey INT NOT NULL,
	CityName NVARCHAR(50) NULL,
	StateProvCode NVARCHAR(5) NULL,
	StateProvName NVARCHAR(50) NULL,
	CountryName NVARCHAR(60) NULL,
	CountryFormalName NVARCHAR(60) NULL,
    CONSTRAINT PK_DimCities PRIMARY KEY CLUSTERED ( LocationKey )
);

CREATE TABLE dbo.DimCustomers(--type 2 SCD
	CustomerKey INT NOT NULL,
	CustomerName NVARCHAR(100) NULL,
	CustomerCategoryName NVARCHAR(50) NULL,
	DeliveryCityName NVARCHAR(50) NULL,
	DeliveryStateProvCode NVARCHAR(5) NULL,
	DeliveryCountryName NVARCHAR(50) NULL,
	PostalCityName NVARCHAR(50) NULL,
	PostalStateProvCode NVARCHAR(5) NULL,
	PostalCountryName NVARCHAR(50) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY CLUSTERED ( CustomerKey )
);

CREATE TABLE dbo.DimProducts(--type 2 SCD
	ProductKey INT NOT NULL,
	ProductName NVARCHAR(100) NULL,
	ProductColour NVARCHAR(20) NULL,
	ProductBrand NVARCHAR(50) NULL,
	ProductSize NVARCHAR(20) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY CLUSTERED ( ProductKey )
);

CREATE TABLE dbo.DimSalesPeople(
	SalespersonKey INT NOT NULL,
	FullName NVARCHAR(50) NULL,
	PreferredName NVARCHAR(50) NULL,
	LogonName NVARCHAR(50) NULL,
	PhoneNumber NVARCHAR(20) NULL,
	FaxNumber NVARCHAR(20) NULL,
	EmailAddress NVARCHAR(256) NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY CLUSTERED (SalespersonKey )
);

CREATE TABLE dbo.DimDate(
	DateKey INT NOT NULL,
	DateValue DATE NOT NULL,
	CYear SMALLINT NOT NULL,
	CQtr TINYINT NOT NULL,
	CMonth TINYINT NOT NULL,
	Day TINYINT NOT NULL,
	StartOfMonth DATE NOT NULL,
	EndOfMonth DATE NOT NULL,
	MonthName VARCHAR(9) NOT NULL,
	DayOfWeekName VARCHAR(9) NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED ( DateKey )
);

CREATE TABLE dbo.FactOrders(
	CustomerKey INT NOT NULL,
	LocationKey INT NOT NULL,
	ProductKey INT NOT NULL,
    --SupplierKey INT NOT NULL,--supplier
	SalespersonKey INT NOT NULL,
	DateKey INT NOT NULL,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(18, 2) NOT NULL,
	TaxRate DECIMAL(18, 3) NOT NULL,
	TotalBeforeTax DECIMAL(18, 2) NOT NULL,
	TotalAfterTax DECIMAL(18, 2) NOT NULL,

    CONSTRAINT FK_FactOrders_DimLocations FOREIGN KEY(LocationKey) REFERENCES dbo.DimLocations (LocationKey),
    --CONSTRAINT FK_FactOrders_DimSuppliers FOREIGN KEY(SupplierKey) REFERENCES dbo.DimSuppliers (SupplierKey), --supplier
    CONSTRAINT FK_FactOrders_DimCustomers FOREIGN KEY(CustomerKey) REFERENCES dbo.DimCustomers (CustomerKey),
    CONSTRAINT FK_FactOrders_DimDate FOREIGN KEY(DateKey) REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactOrders_DimProducts FOREIGN KEY(ProductKey) REFERENCES dbo.DimProducts (ProductKey),
    CONSTRAINT FK_FactOrders_DimSalesPeople FOREIGN KEY(SalespersonKey) REFERENCES dbo.DimSalesPeople (SalespersonKey)
);
GO



--SELECT * FROM FactOrders

-- Requirement1
--ALTER TABLE DimSuppliers ADD SupplierCategoryName NVARCHAR(50) NULL;
CREATE TABLE dbo.DimSuppliers(
	SupplierKey INT NOT NULL,
	SupplierName NVARCHAR(100) NULL,
	PhoneNumber NVARCHAR(20) NULL,
    FaxNumber NVARCHAR(20) NULL,
    WebsiteUrl NVARCHAR(100) NULL,
	SupplierCategoryName NVARCHAR(50) NULL,
    StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_DimSuppliers PRIMARY KEY CLUSTERED ( SupplierKey )

);
ALTER TABLE dbo.FactOrders ADD SupplierKey INT NOT NULL,
						   FOREIGN KEY (SupplierKey) REFERENCES dbo.DimSuppliers (SupplierKey);


CREATE INDEX IX_FactOrders_SupplierKey ON dbo.FactOrders(SupplierKey);--supplier index

GO
-- Requirement2
CREATE OR ALTER PROCEDURE dbo.DimDate_Load
AS
BEGIN;
 DECLARE @startDate date = '2012-01-01';
    DECLARE @endDate date = '2021-12-31';
    DECLARE @currentDate date = @startDate;
 WHILE @currentDate <= @endDate
    BEGIN
  INSERT INTO dbo.DimDate
  SELECT CAST( YEAR(@currentDate) * 10000 + MONTH(@currentDate) * 100 + DAY(@currentDate) AS INT),
      @currentDate,
      YEAR(@currentDate),
      DATEPART(qq,@currentDate),
      MONTH(@currentDate),
      DAY(@currentDate),
      DATEADD(DAY,1,EOMONTH(@currentDate,-1)),
      EOMONTH(@currentDate),
      DATENAME(mm,@currentDate),
      DATENAME(dw,@currentDate);
  SET @currentDate = DATEADD(DAY, 1, @currentDate);
 END
END

--EXEC DimDate_Load

--SELECT * FROM dbo.DimDate;
GO

-- Requirement3



-- Requirement4


-- stage tables
CREATE TABLE dbo.Supplier_Stage (
	SupplierName NVARCHAR(100) NULL,
	PhoneNumber NVARCHAR(20) NULL,
    FaxNumber NVARCHAR(20) NULL,
    WebsiteUrl NVARCHAR(100) NULL,
	SupplierCategoryName NVARCHAR(50)
);


CREATE TABLE dbo.Customers_Stage (
    CustomerName NVARCHAR(100),
    CustomerCategoryName NVARCHAR(50),
    DeliveryCityName NVARCHAR(50),
    DeliveryStateProvinceCode NVARCHAR(5),
    DeliveryStateProvinceName NVARCHAR(50),
    DeliveryCountryName NVARCHAR(50),
    DeliveryFormalName NVARCHAR(60),
    PostalCityName NVARCHAR(50),
    PostalStateProvinceCode NVARCHAR(5),
    PostalStateProvinceName NVARCHAR(50),
    PostalCountryName NVARCHAR(50),
    PostalFormalName NVARCHAR(60)
);

CREATE TABLE dbo.Orders_Stage(
	OrderDate DATE,
	Quantity INT,
    UnitPrice DECIMAL(18,2),
    TaxRate	DECIMAL(18,3),
    CustomerName NVARCHAR(100),
	CityName NVARCHAR(50),
	StateProvinceName NVARCHAR(50),
	CountryName NVARCHAR(60),
	StockItemName NVARCHAR(100),
	SupplierName NVARCHAR(50),
	LogonName NVARCHAR(50)
);

CREATE TABLE dbo.Products_Stage(
	ProductName NVARCHAR(100) NULL,
	ProductColour NVARCHAR(20) NULL,
	ProductBrand NVARCHAR(50) NULL,
	ProductSize NVARCHAR(20) NULL,
);

CREATE TABLE dbo.Salesperson_Stage (
    FullName NVARCHAR(50),
	PreferredName NVARCHAR(50),
	LogonName NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	EmailAddress NVARCHAR(256)
);

-- extract
GO
CREATE PROCEDURE dbo.Supplier_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;
	
	TRUNCATE TABLE dbo.Supplier_Stage

	INSERT INTO dbo.Supplier_Stage (
		SupplierName,
		PhoneNumber,
		FaxNumber,
		WebsiteUrl,
		SupplierCategoryName
	)
	SELECT s.SupplierName,
		   s.PhoneNumber,
		   s.FaxNumber,
		   s.WebsiteURL,
		   sc.SupplierCategoryName
	FROM WideWorldImporters.Purchasing.Suppliers s
		LEFT JOIN WideWorldImporters.Purchasing.SupplierCategories sc
		ON s.SupplierCategoryID = sc.SupplierCategoryID

	SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;

GO
CREATE PROCEDURE dbo.Customers_Extract
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Customers_Stage;

    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM WideWorldImporters.Application.Cities ci
        LEFT JOIN WideWorldImporters.Application.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN WideWorldImporters.Application.Countries co
            ON sp.CountryID = co.CountryID ) 
    INSERT INTO dbo.Customers_Stage (
        CustomerName,
        CustomerCategoryName,
        DeliveryCityName,
        DeliveryStateProvinceCode,
        DeliveryStateProvinceName,
        DeliveryCountryName,
        DeliveryFormalName,
        PostalCityName,
        PostalStateProvinceCode,
        PostalStateProvinceName,
        PostalCountryName,
        PostalFormalName )
    SELECT cust.CustomerName,
           cat.CustomerCategoryName,
           dc.CityName,
           dc.StateProvinceCode,
           dc.StateProvinceName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.StateProvinceCode,
           pc.StateProvinceName,
           pc.CountryName,
           pc.FormalName
    FROM WideWorldImporters.Sales.Customers cust
    LEFT JOIN WideWorldImporters.Sales.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CityDetails dc
        ON cust.DeliveryCityID = dc.CityID
    LEFT JOIN CityDetails pc
        ON cust.PostalCityID = pc.CityID;

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END; --END OF PROCEDURE Customers_Extract
GO

CREATE PROCEDURE dbo.Orders_Extract
	@OrderDate DATE
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @RowCt INT;
	
	TRUNCATE TABLE dbo.Orders_Stage;
	
	WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM WideWorldImporters.Application.Cities ci
        LEFT JOIN WideWorldImporters.Application.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN WideWorldImporters.Application.Countries co
            ON sp.CountryID = co.CountryID ),
	CustomerDetails AS (
		SELECT
			cust.CustomerID,
			cust.CustomerName,
			cd.CityName,
			cd.StateProvinceName,
			cd.CountryName
		FROM WideWorldImporters.Sales.Customers cust
		LEFT JOIN CityDetails cd
			ON DeliveryCityID = cd.CityID),
	StockItemDetails AS(
		SELECT
			ol.OrderLineID,
			ol.OrderID,
			si.StockItemName,
			sup.SupplierName
		FROM WideWorldImporters.Sales.OrderLines ol
		INNER JOIN WideWorldImporters.Warehouse.StockItems si
			ON si.StockItemID = ol.StockItemID
		INNER JOIN WideWorldImporters.Purchasing.Suppliers sup
			ON sup.SupplierID = si.SupplierID)
	INSERT INTO dbo.Orders_Stage(
		OrderDate,
		Quantity,
		UnitPrice,
		TaxRate,
		CustomerName,
		CityName,
		StateProvinceName,
		CountryName,
		StockItemName,
		SupplierName,
		LogonName
	)
	SELECT
		o.OrderDate,
		ol.Quantity,
		ol.UnitPrice,
		ol.TaxRate,
		cud.CustomerName,
		cud.CityName,
		cud.StateProvinceName,
		cud.CountryName,
		sid.StockItemName,
		sid.SupplierName,
		p.LogonName
	FROM WideWorldImporters.Sales.Orders o
	INNER JOIN WideWorldImporters.Sales.OrderLines ol
		ON o.OrderID = ol.OrderID
	LEFT JOIN CustomerDetails cud
		ON o.CustomerID = cud.CustomerID
	LEFT JOIN StockItemDetails sid
		ON o.OrderID = sid.OrderID
	INNER JOIN WideWorldImporters.Application.People p
		ON p.PersonID = o.SalespersonPersonID
	WHERE o.OrderDate = @OrderDate;
	
	SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END; --END OF PROCEDURE Orders_Extract
GO
------------------------------
CREATE OR ALTER PROCEDURE dbo.Products_Extract
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
	DECLARE @RowCt INT;

	
    TRUNCATE TABLE dbo.Products_Stage;


	INSERT INTO dbo.Products_Stage (
		ProductName,
		ProductBrand,
		ProductSize,
		ProductColour) 
	SELECT s.StockItemName, 
		   s.Brand,
		   s.Size,
		   c.ColorName
	FROM WideWorldImporters.Warehouse.StockItems s
	LEFT JOIN  WideWorldImporters.Warehouse.Colors c
		ON s.ColorID = c.ColorID


	SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;

GO

CREATE PROCEDURE dbo.Salesperson_Extract
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Salesperson_Stage;

	INSERT INTO dbo.Salesperson_Stage(
	       FullName,
	       PreferredName,
		   LogonName,
		   PhoneNumber,
		   FaxNumber,
		   EmailAddress
	)
    SELECT FullName,
	       PreferredName,
		   LogonName,
		   PhoneNumber,
		   FaxNumber,
		   EmailAddress
	FROM WideWorldImporters.Application.People
	WHERE IsSalesperson='1';

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0 
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END; --END OF PROCEDURE Salesperson_Extract
GO

/*
EXEC Products_Extract;
SELECT * FROM Products_Stage;
EXEC dbo.Salesperson_Extract;
SELECT * FROM Salesperson_Stage;
EXEC Supplier_Extract;
SELECT * FROM Supplier_Stage;
*/
-- Requirement5
/* CREATING SEQUENCE TO MAINTAIN THE SURROGATE KEY */
CREATE SEQUENCE dbo.LocationKey START WITH 1;
CREATE SEQUENCE dbo.SalespersonKey START WITH 1;
CREATE SEQUENCE dbo.SupplierKey START WITH 1;
CREATE SEQUENCE dbo.CustomerKey START WITH 1;
CREATE SEQUENCE dbo.ProductKey START WITH 1;
GO
-- Transform



CREATE TABLE dbo.Customers_Preload (
	CustomerKey INT NOT NULL,
	CustomerName VARCHAR(100) NULL,
	CustomerCategoryName VARCHAR(50) NULL,
	DeliveryCityName VARCHAR(50) NULL,
	DeliveryStateProvCode VARCHAR(5) NULL,
	DeliveryCountryName VARCHAR(50) NULL,
	PostalCityName VARCHAR(50) NULL,
	PostalStateProvCode VARCHAR(50) NULL,
	PostalCountryName VARCHAR(50) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
	CONSTRAINT PK_Customer_Preload PRIMARY KEY CLUSTERED (CustomerKey)
);

GO
CREATE PROCEDURE dbo.Customers_Transform    -- Type 2 SCD
	@StartDate DATE
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
	
    TRUNCATE TABLE dbo.Customers_Preload;

    --DECLARE @StartDate DATE = GETDATE();
	--DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
    DECLARE @EndDate DATE = DATEADD(dd,-1,@StartDate);

    BEGIN TRANSACTION;

	/*ADD UPDATED RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT NEXT VALUE FOR dbo.CustomerKey AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           @StartDate,
           NULL
    FROM dbo.Customers_Stage stg
    JOIN dbo.DimCustomers cu
        ON stg.CustomerName = cu.CustomerName-- grab all records of stage table that has name match with the dimtable
        AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
          OR stg.DeliveryCityName <> cu.DeliveryCityName
          OR stg.DeliveryStateProvinceCode <> cu.DeliveryStateProvCode
          OR stg.DeliveryCountryName <> cu.DeliveryCountryName
          OR stg.PostalCityName <> cu.PostalCityName
          OR stg.PostalStateProvinceCode <> cu.PostalStateProvCode
          OR stg.PostalCountryName <> cu.PostalCountryName;
		  -- by this point, preload table has all the changed records, these are updated records,
		  -- next is add the old records and expire them


	/*ADD EXISTING RECORDS, AND EXPIRE AS NECESSARY*/
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
		   -- if pl.CustomerName is NULL, there is no change to this record, so keep it as-is
		   -- if pl.CustomerName is not NULL, then thecurrent record already exists in the customerPreload tableand is being updated,
		   -- in this case, the EndDate value for the previous record in the table needs to be updated to reflect the fact that the current record is expired,
		   -- To do this, the @EndDate value is assigned to EndDate.
           CASE 
               WHEN pl.CustomerName IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimCustomers cu
    LEFT JOIN dbo.Customers_Preload pl    
        ON pl.CustomerName = cu.CustomerName
        AND cu.EndDate IS NULL;--no already expired records
    
	-- By this point, preload table has all the unchanged records, and expired all the changed records


	/*CREATE NEW RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT NEXT VALUE FOR dbo.CustomerKey AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           @StartDate,
           NULL
    FROM dbo.Customers_Stage stg --stage table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimCustomers cu WHERE stg.CustomerName = cu.CustomerName );

	--by this point, the preload has new customers that were not in dim table

	/*EXPRIRE MISSING RECORDS*/
    INSERT INTO dbo.Customers_Preload 
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           @EndDate
    FROM dbo.DimCustomers cu--dim table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName )
          AND cu.EndDate IS NULL;
	--expire all records that noit in the stage table, and still add these to preload to keep track
    COMMIT TRANSACTION;
END; --END OF PROCEDURE Customers_Transform
GO


-- supplier preload table and procedure
CREATE TABLE dbo.Supplier_Preload (
	SupplierKey INT NOT NULL,
	SupplierName NVARCHAR(100) NULL,
	PhoneNumber NVARCHAR(20) NULL,
    FaxNumber NVARCHAR(20) NULL,
    WebsiteUrl NVARCHAR(100) NULL,
	SupplierCategoryName NVARCHAR(50) NULL,
    StartDate DATE NOT NULL,
	EndDate DATE NULL,
    CONSTRAINT PK_Supplier_Preload PRIMARY KEY CLUSTERED ( SupplierKey )
);
GO

CREATE PROCEDURE dbo.Supplier_Transform
	@StartDate DATE
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	TRUNCATE TABLE dbo.Supplier_Preload;
    DECLARE @EndDate DATE = DATEADD(dd,-1,@StartDate);

    BEGIN TRANSACTION;
	/*ADD UPDATED RECORDS*/
	INSERT INTO dbo.Supplier_Preload 
    SELECT NEXT VALUE FOR dbo.SupplierKey AS SupplierKey,
           stg.SupplierName,
           stg.PhoneNumber,
		   stg.FaxNumber,
		   stg.WebsiteUrl,
		   stg.SupplierCategoryName,
           @StartDate,
           NULL
    FROM dbo.Supplier_Stage stg
    JOIN dbo.DimSuppliers s
        ON stg.SupplierName = s.SupplierName-- grab all records of stage table that has name match with the dimtable
        AND s.EndDate IS NULL
    WHERE stg.PhoneNumber <> s.PhoneNumber
          OR stg.FaxNumber <> s.FaxNumber
		  OR stg.WebsiteUrl <> s.WebsiteUrl
          OR stg.SupplierCategoryName <> s.SupplierCategoryName;
		  -- by this point, preload table has all the changed records, these are updated records,
		  -- next is add the old records and expire them

	/*ADD EXISTING RECORDS, AND EXPIRE AS NECESSARY*/
	INSERT INTO dbo.Supplier_Preload 
    SELECT s.SupplierKey,
           s.SupplierName,
           s.PhoneNumber,
           s.FaxNumber,
		   s.WebsiteUrl,
           s.SupplierCategoryName,
           s.StartDate,
           CASE 
               WHEN pl.SupplierName IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimSuppliers s
    LEFT JOIN dbo.Supplier_Preload pl    
        ON pl.SupplierName =s.SupplierName
        AND s.EndDate IS NULL;

-- By this point, preload table has all the unchanged records, and expired all the changed records
	/*CREATE NEW RECORDS*/
	INSERT INTO dbo.Supplier_Preload 
    SELECT NEXT VALUE FOR dbo.SupplierKey AS SupplierKey,
           stg.SupplierName,
           stg.PhoneNumber,
           stg.FaxNumber,
		   stg.WebsiteUrl,
           stg.SupplierCategoryName,
           @StartDate,
           NULL
    FROM dbo.Supplier_Stage stg --stage table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimSuppliers s WHERE stg.SupplierName = s.SupplierName );

	--by this point, the preload has new customers that were not in dim table
	/*EXPRIRE MISSING RECORDS*/
	INSERT INTO dbo.Supplier_Preload 
    SELECT s.SupplierKey,
           s.SupplierName,
           s.PhoneNumber,
           s.FaxNumber,
		   s.WebsiteUrl,
		   s.SupplierCategoryName,
           s.StartDate,
           @EndDate
    FROM dbo.DimSuppliers s--dim table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.Supplier_Stage stg WHERE stg.SupplierName = s.SupplierName )
          AND s.EndDate IS NULL;
	--expire all records that not in the stage table, and still add these to preload to keep track

    COMMIT TRANSACTION;
END; --END OF PROCEDURE Supplier_Transform

GO
--Products preload table and procedure
CREATE TABLE dbo.Products_Preload (
	ProductKey INT NOT NULL,
	ProductName VARCHAR(100) NULL,
	ProductColour NVARCHAR(20) NULL,
	ProductBrand NVARCHAR(50) NULL,
	ProductSize NVARCHAR(20) NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NULL,
	CONSTRAINT PK_Products_Preload PRIMARY KEY CLUSTERED ( ProductKey )
);
GO

CREATE PROCEDURE dbo.Products_Transform    -- Type 2
	@StartDate DATE
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
	
    TRUNCATE TABLE dbo.Products_Preload;

    --DECLARE @StartDate DATE = GETDATE();
	--DECLARE @EndDate DATE = DATEADD(dd,-1,GETDATE());
    DECLARE @EndDate DATE = DATEADD(dd,-1,@StartDate);

    BEGIN TRANSACTION;

	/*ADD UPDATED RECORDS*/
	INSERT INTO dbo.Products_Preload 
    SELECT NEXT VALUE FOR dbo.ProductKey AS ProductKey,
           stg.ProductName,
           stg.ProductColour,
		   stg.ProductBrand,
		   stg.ProductSize,
           @StartDate,
           NULL
    FROM dbo.Products_Stage stg
    JOIN dbo.DimProducts p
        ON stg.ProductName = p.ProductName-- grab all records of stage table that has name match with the dimtable
        AND p.EndDate IS NULL
    WHERE stg.ProductColour <> p.ProductColour
          OR stg.ProductBrand <> p.ProductBrand
          OR stg.ProductSize <> p.ProductSize;
		  -- by this point, preload table has all the changed records, these are updated records,
		  -- next is add the old records and expire them

	/*ADD EXISTING RECORDS, AND EXPIRE AS NECESSARY*/
	INSERT INTO dbo.Products_Preload 
    SELECT p.ProductKey,
           p.ProductName,
           p.ProductColour,
           p.ProductBrand,
           p.ProductSize,
           p.StartDate,
           CASE 
               WHEN pl.ProductName IS NULL THEN NULL
               ELSE @EndDate
           END AS EndDate
    FROM dbo.DimProducts p
    LEFT JOIN dbo.Products_Preload pl    
        ON pl.ProductName = p.ProductName
        AND p.EndDate IS NULL;


-- By this point, preload table has all the unchanged records, and expired all the changed records
	/*CREATE NEW RECORDS*/
	INSERT INTO dbo.Products_Preload 
    SELECT NEXT VALUE FOR dbo.ProductKey AS ProductKey,
           stg.ProductName,
           stg.ProductColour,
           stg.ProductBrand,
           stg.ProductSize,
           @StartDate,
           NULL
    FROM dbo.Products_Stage stg --stage table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.DimProducts p WHERE stg.ProductName = p.ProductName );

	--by this point, the preload has new customers that were not in dim table

	/*EXPRIRE MISSING RECORDS*/
	INSERT INTO dbo.Products_Preload 
    SELECT p.ProductKey,
           p.ProductName,
           p.ProductColour,
           p.ProductBrand,
		   p.ProductSize,
           p.StartDate,
           @EndDate
    FROM dbo.DimProducts p--dim table
    WHERE NOT EXISTS ( SELECT 1 FROM dbo.Products_Stage stg WHERE stg.ProductName = p.ProductName )
          AND p.EndDate IS NULL;
	--expire all records that noit in the stage table, and still add these to preload to keep track

    COMMIT TRANSACTION;
END; --END OF PROCEDURE Product_Transform
GO

--Salesperson preload table and procedure
/* CREATING TARGET STAGING TABLES */
CREATE TABLE dbo.Salesperson_Preload (
	SalespersonKey INT NOT NULL,
        FullName NVARCHAR(50),
	PreferredName NVARCHAR(50),
	LogonName NVARCHAR(50),
	PhoneNumber NVARCHAR(20),
	FaxNumber NVARCHAR(20),
	EmailAddress NVARCHAR(256)
    CONSTRAINT PK_Salesperson_Preload PRIMARY KEY CLUSTERED ( SalespersonKey )
);
GO

CREATE PROCEDURE dbo.Salesperson_Transform    -- Type 1 SCD
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Salesperson_Preload;

    BEGIN TRANSACTION;
	
	/*CREATE NEW RECORD*/
    INSERT INTO dbo.Salesperson_Preload
    SELECT NEXT VALUE FOR dbo.SalespersonKey AS SalespersonKey,
           sps.FullName,
		   sps.PreferredName,
		   sps.LogonName,
		   sps.PhoneNumber,
		   sps.FaxNumber,
		   sps.EmailAddress
    FROM dbo.Salesperson_Stage sps
    WHERE NOT EXISTS ( SELECT 1 
                       FROM dbo.DimSalesPeople dsp
                       WHERE sps.FullName = dsp.FullName
					   AND sps.PreferredName = dsp.PreferredName
					   AND sps.LogonName = dsp.LogonName
					   AND sps.PhoneNumber = dsp.PhoneNumber
					   AND sps.FaxNumber = dsp.FaxNumber
					   AND sps.EmailAddress = dsp.EmailAddress);
	
	/*UPDATE EXITING RECORDS*/
    INSERT INTO dbo.Salesperson_Preload
    SELECT dsp.SalespersonKey,
		   sps.FullName,
		   sps.PreferredName,
		   sps.LogonName,
		   sps.PhoneNumber,
		   sps.FaxNumber,
		   sps.EmailAddress
    FROM dbo.Salesperson_Stage sps
    JOIN dbo.DimSalesPeople dsp
        ON sps.FullName = dsp.FullName
		   AND sps.PreferredName = dsp.PreferredName
		   AND sps.LogonName = dsp.LogonName
		   AND sps.PhoneNumber = dsp.PhoneNumber
		   AND sps.FaxNumber = dsp.FaxNumber
		   AND sps.EmailAddress = dsp.EmailAddress;

    COMMIT TRANSACTION;
END; --END OF PROCEDURE Salesperson_Transform
GO
/*
EXEC dbo.Supplier_Transform '2013-1-1';
SELECT * FROM Supplier_Preload;
--GO
--EXEC dbo.Salesperson_Transform;
--SELECT * FROM Salesperson_Preload;
*/

--location preload table and procedure
CREATE TABLE dbo.Locations_Preload( 
	LocationKey INT NOT NULL, 
	CityName NVARCHAR(50) NULL, 
	StateProvCode NVARCHAR(5) NULL, 
	StateProvName NVARCHAR(50) NULL, 
	CountryName NVARCHAR(60) NULL, 
	CountryFormalName NVARCHAR(60) NULL, 
	CONSTRAINT PK_Cities_Preload PRIMARY KEY CLUSTERED (LocationKey) );

GO

CREATE OR ALTER PROCEDURE dbo.Locations_Transform
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	TRUNCATE TABLE dbo.Locations_Preload;
BEGIN TRANSACTION;
--Use Sequence to create new surrogate keys (Create new records)
INSERT INTO dbo.Locations_Preload /* Column list excluded for brevity */
SELECT NEXT VALUE FOR dbo.LocationKey AS LocationKey,
	cu.DeliveryCityName,
	cu.DeliveryStateProvinceCode,
	cu.DeliveryStateProvinceName,
	cu.DeliveryCountryName,
	cu.DeliveryFormalName
	FROM dbo.Customers_Stage cu
	WHERE NOT EXISTS (SELECT 1
FROM dbo.DimLocations ci WHERE cu.DeliveryCityName = ci.CityName
AND cu.DeliveryStateProvinceName = ci.StateProvName AND cu.DeliveryCountryName = ci.CountryName );
--Use existing surrogate key if one exists (Add updated records)
INSERT INTO dbo.Locations_Preload/* Column list excluded for brevity */ 
SELECT ci.LocationKey, 
	cu.DeliveryCityName, 
	cu.DeliveryStateProvinceCode, 
	cu.DeliveryStateProvinceName, 
	cu.DeliveryCountryName, 
	cu.DeliveryFormalName 
	FROM dbo.Customers_Stage cu 
	JOIN dbo.DimLocations ci ON cu.DeliveryCityName=ci.CityName 
	AND cu.DeliveryStateProvinceName=ci.StateProvName 
	AND cu.DeliveryCountryName=ci.CountryName; 
	COMMIT TRANSACTION; 
END;
GO

--Order preload table and procedure
CREATE TABLE dbo.Orders_Preload (
	CustomerKey INT NOT NULL,
	LocationKey INT NOT NULL,
	ProductKey INT NOT NULL,
	SalespersonKey INT NOT NULL,
	SupplierKey	INT NOT NULL,
	DateKey INT NOT NULL,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(18, 2) NOT NULL,
	TaxRate DECIMAL(18, 3) NOT NULL,
	TotalBeforeTax DECIMAL(18, 2) NOT NULL,
	TotalAfterTax DECIMAL(18, 2) NOT NULL,
);

GO
CREATE PROCEDURE dbo.Orders_Transform
AS 
BEGIN; 
	SET NOCOUNT ON; 
	SET XACT_ABORT ON; 
	TRUNCATE TABLE dbo.Orders_Preload; 

	INSERT INTO dbo.Orders_Preload/* Columns excluded for brevity */ 
	SELECT cu.CustomerKey, 
			ci.LocationKey, 
			pr.ProductKey, 
			sp.SalespersonKey, 
			su.SupplierKey,
			CAST(YEAR(ord.OrderDate)*10000 +MONTH(ord.OrderDate)*100 +DAY(ord.OrderDate) AS INT), 
			SUM(ord.Quantity) AS Quantity, 
			AVG(ord.UnitPrice) AS UnitPrice, 
			AVG(ord.TaxRate) AS TaxRate, 
			SUM(ord.Quantity*ord.UnitPrice) AS TotalBeforeTax, 
			SUM(ord.Quantity*ord.UnitPrice*(1 +ord.TaxRate/100)) AS TotalAfterTax 
	FROM dbo.Orders_Stage ord 
	JOIN dbo.Customers_Preload cu 
			ON ord.CustomerName=cu.CustomerName 
	JOIN dbo.Locations_Preload ci
			ON ord.CityName=ci.CityName
			AND ord.StateProvinceName=ci.StateProvName 
			AND ord.CountryName=ci.CountryName 
	JOIN dbo.Products_Preload pr 
			ON ord.StockItemName=pr.ProductName 
	JOIN dbo.Salesperson_Preload sp 
			ON ord.LogonName =sp.LogonName
	JOIN dbo.Supplier_Preload su
			ON ord.SupplierName = su.SupplierName
	GROUP BY cu.CustomerKey,ci.LocationKey,pr.ProductKey,sp.SalespersonKey,su.SupplierKey,ord.OrderDate;
END;
GO

-- Requirement6

CREATE PROCEDURE dbo.Location_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE dl
    FROM dbo.DimLocations dl
    JOIN dbo.Locations_Preload pl
        ON dl.LocationKey = pl.LocationKey;

    INSERT INTO dbo.DimLocations 
    SELECT * 
    FROM dbo.Locations_Preload;

    COMMIT TRANSACTION;
END;
GO

--EXEC dbo.Location_Load;
--SELECT * FROM DimLocations;

CREATE PROCEDURE dbo.Orders_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    INSERT INTO dbo.FactOrders 
    SELECT * 
    FROM dbo.Orders_Preload;

END;
GO

CREATE PROCEDURE dbo.Customer_Load
AS
BEGIN;
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION;

	DELETE cu
	FROM dbo.DimCustomers cu
	JOIN dbo.Customers_Preload pl
		ON cu.CustomerKey = pl.CustomerKey;

	INSERT INTO dbo.DimCustomers
	SELECT *
	FROM dbo.Customers_Preload

	COMMIT TRANSACTION;
END;

GO

CREATE PROCEDURE dbo.Products_Load
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION;

	DELETE p
	FROM dbo.DimProducts p
	JOIN dbo.Products_Preload pl
		ON p.ProductKey = pl.ProductKey;

	INSERT INTO dbo.DimProducts
	SELECT *
	FROM dbo.Products_Preload

	COMMIT TRANSACTION;
END;

GO

CREATE PROCEDURE dbo.Salesperson_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE dsp
    FROM dbo.DimSalesPeople dsp
    JOIN dbo.Salesperson_Preload sppl
        ON dsp.SalespersonKey = sppl.SalespersonKey;

    INSERT INTO dbo.DimSalesPeople
    SELECT * 
    FROM dbo.Salesperson_Preload;

    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE dbo.Supplier_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE s
    FROM dbo.DimSuppliers s
    JOIN dbo.Supplier_Preload sp
        ON s.SupplierKey = sp.SupplierKey;

    INSERT INTO dbo.DimSuppliers
    SELECT * 
    FROM dbo.Supplier_Preload;

    COMMIT TRANSACTION;
END;
GO

/*
EXEC dbo.Supplier_Load;
SELECT * FROM DimSuppliers
GO
*/
-- Requirement7

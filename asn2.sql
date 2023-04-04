USE master;
--DROP DATABASE WWI_DM;
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



CREATE OR ALTER PROCEDURE dbo.DimDate_Load (@DateValue DATE)
AS
BEGIN
    INSERT INTO dbo.DimDate
    SELECT CAST( YEAR(@DateValue) * 10000 + MONTH(@DateValue) * 100 + DAY(@DateValue) AS INT),
           @DateValue,
           YEAR(@DateValue),
		   DATEPART(qq,@DateValue),
           MONTH(@DateValue),
           DAY(@DateValue),
           DATEADD(DAY,1,EOMONTH(@DateValue,-1)),
           EOMONTH(@DateValue),
           DATENAME(mm,@DateValue),
           DATENAME(dw,@DateValue);
END;


CREATE INDEX IX_FactOrders_CustomerKey ON dbo.FactOrders(CustomerKey);
CREATE INDEX IX_FactOrders_CityKey ON dbo.FactOrders(LocationKey);
CREATE INDEX IX_FactOrders_ProductKey ON dbo.FactOrders(ProductKey);
CREATE INDEX IX_FactOrders_SalespersonKey ON dbo.FactOrders(SalespersonKey);
CREATE INDEX IX_FactOrders_DateKey ON dbo.FactOrders(DateKey);



GO

SELECT * FROM FactOrders

-- Requirement1

CREATE TABLE dbo.DimSuppliers(
	SupplierKey INT NOT NULL,
	SupplierName NVARCHAR(100) NULL,
	PhoneNumber NVARCHAR(20) NULL,
    FaxNumber NVARCHAR(20) NULL,
    WebsiteUrl NVARCHAR(100) NULL,
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

EXEC DimDate_Load

SELECT * FROM dbo.DimDate;
GO

-- Requirement3



-- Requirement4


-- stage tables
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


--EXEC Products_Extract;
--SELECT * FROM Products_Stage;
--EXEC dbo.Salesperson_Extract;
--SELECT * FROM Salesperson_Stage;
-- Requirement5
GO
/* CREATING SEQUENCE TO MAINTAIN THE SURROGATE KEY */
CREATE SEQUENCE dbo.CityKey START WITH 1;
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
	INSERT INTO dbo.Customers_Preload 
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
END; --END OF PROCEDURE Customers_Transform
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

--EXEC dbo.Salesperson_Transform;
--SELECT * FROM Salesperson_Preload;
--GO


-- Requirement6

CREATE PROCEDURE dbo.Cities_Load
AS
BEGIN;

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE ci
    FROM dbo.DimCities ci
    JOIN dbo.Cities_Preload pl
        ON ci.CityKey = pl.CityKey;

    INSERT INTO dbo.DimCities 
    SELECT * 
    FROM dbo.Cities_Preload;

    COMMIT TRANSACTION;
END;
GO

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

GO;

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

--EXEC dbo.Salesperson_Load;
--SELECT * FROM DimSalesPeople;
--GO

-- Requirement7

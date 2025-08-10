/* =========================
   Base de datos y esquemas SCRIPT  CP04010 JOSUE  SALVADOR CASTILLO 
    DENTRO  DE LA BASE DE DATOS HE MANEJADO UNA  ETAPA DE STAGEING Y LA ETAPA DE   DW  QUE EL ESQUEMA  STAGING  SE UTILIZA  PARA 
	COMO PRECARGA  Y LIMPIEZA DE LOS DATOS 
   ========================= */
IF DB_ID('SalesDW') IS NULL CREATE DATABASE SalesDW;
GO
USE SalesDW;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dw')  EXEC('CREATE SCHEMA dw');
GO

/* =========================
   1) Tablas STAGING 
   ========================= */
CREATE TABLE stg.Ventas(
  OrderNumber      NVARCHAR(50)  NOT NULL,
  OrderDate        DATE          NOT NULL,
  ShipDate         DATE          NULL,
  CustomerStateID  INT           NULL,
  ProductID        INT           NOT NULL,
  Quantity         INT           NOT NULL,
  UnitPrice        DECIMAL(18,4) NOT NULL,
  DiscountAmount   DECIMAL(18,4) NULL,
  PromotionCode    NVARCHAR(50)  NULL
);

CREATE TABLE stg.Productos(
  ProductID       INT           NOT NULL,
  ProductSKU      NVARCHAR(50)  NULL,
  ProductName     NVARCHAR(200) NULL,
  ProductCategory NVARCHAR(100) NULL,
  ItemGroup       NVARCHAR(100) NULL,
  KitType         NVARCHAR(100) NULL,
  Channels        NVARCHAR(100) NULL,
  Demographic     NVARCHAR(100) NULL,
  RetailPrice     DECIMAL(18,4) NULL,
  Photo           VARBINARY(MAX) NULL
);

CREATE TABLE stg.Estados(
  StateID   INT           NOT NULL,
  StateCode NVARCHAR(10)  NULL,
  StateName NVARCHAR(100) NULL,
  TimeZone  NVARCHAR(50)  NULL,
  RegionID  INT           NULL
);

CREATE TABLE stg.Regiones(
  RegionID   INT           NOT NULL,
  RegionName NVARCHAR(100) NULL
);

CREATE TABLE stg.OficinasVentas(
  SalesOfficeID INT NOT NULL,
  AddressLine1  NVARCHAR(100) NULL,
  AddressLine2  NVARCHAR(100) NULL,
  City          NVARCHAR(100) NULL,
  StateID       INT           NULL,
  PostalCode    NVARCHAR(20)  NULL,
  Telephone     NVARCHAR(50)  NULL,
  Facsimile     NVARCHAR(50)  NULL,
  Email         NVARCHAR(200) NULL
);

GO
/* =========================
   2) Dimensiones (DW)
   ========================= */
CREATE TABLE dw.DimFechas(
  DateKey   INT PRIMARY KEY, -- yyyymmdd
  [Date]    DATE NOT NULL,
  [Year]    INT NOT NULL,
  [Quarter] TINYINT NOT NULL,
  [Month]   TINYINT NOT NULL,
  MonthName NVARCHAR(20) NOT NULL,
  [Day]     TINYINT NOT NULL,
  DayOfWeek TINYINT NOT NULL,
  DayName   NVARCHAR(20) NOT NULL,
  IsWeekend BIT NOT NULL
);

CREATE TABLE dw.DimRegiones(
  RegionSK      BIGINT PRIMARY KEY,
  RegionID      INT            NULL,
  RegionName    NVARCHAR(100)  NULL,
  EffectiveFrom DATETIME2(0)   NOT NULL,
  EffectiveTo   DATETIME2(0)   NOT NULL,
  IsCurrent     BIT            NOT NULL
);

CREATE TABLE dw.DimEstados(
  StateSK       BIGINT PRIMARY KEY,
  StateID       INT            NULL,
  StateCode     NVARCHAR(10)   NULL,
  StateName     NVARCHAR(100)  NULL,
  TimeZone      NVARCHAR(50)   NULL,
  RegionSK      BIGINT         NULL,
  EffectiveFrom DATETIME2(0)   NOT NULL,
  EffectiveTo   DATETIME2(0)   NOT NULL,
  IsCurrent     BIT            NOT NULL
);

CREATE TABLE dw.DimOficinasVentas(
  SalesOfficeSK  BIGINT PRIMARY KEY,
  SalesOfficeID  INT            NULL,
  AddressLine1   NVARCHAR(100)  NULL,
  AddressLine2   NVARCHAR(100)  NULL,
  City           NVARCHAR(100)  NULL,
  StateSK        BIGINT         NULL,
  PostalCode     NVARCHAR(20)   NULL,
  Telephone      NVARCHAR(50)   NULL,
  Facsimile      NVARCHAR(50)   NULL,
  Email          NVARCHAR(200)  NULL,
  EffectiveFrom  DATETIME2(0)   NOT NULL,
  EffectiveTo    DATETIME2(0)   NOT NULL,
  IsCurrent      BIT            NOT NULL
);

CREATE TABLE dw.DimProductos(
  ProductSK       BIGINT PRIMARY KEY,
  ProductID       INT            NULL,
  ProductSKU      NVARCHAR(50)   NULL,
  ProductName     NVARCHAR(200)  NULL,
  ProductCategory NVARCHAR(100)  NULL,
  ItemGroup       NVARCHAR(100)  NULL,
  KitType         NVARCHAR(100)  NULL,
  Channels        NVARCHAR(100)  NULL,
  Demographic     NVARCHAR(100)  NULL,
  RetailPrice     DECIMAL(18,4)  NULL,
  EffectiveFrom   DATETIME2(0)   NOT NULL,
  EffectiveTo     DATETIME2(0)   NOT NULL,
  IsCurrent       BIT            NOT NULL
);

CREATE TABLE dw.DimPromociones(
  PromotionSK   BIGINT PRIMARY KEY,
  PromotionCode NVARCHAR(50)  NULL,
  IsDiscounted  BIT           NOT NULL,
  EffectiveFrom DATETIME2(0)  NOT NULL,
  EffectiveTo   DATETIME2(0)  NOT NULL,
  IsCurrent     BIT           NOT NULL
);

CREATE TABLE dw.DimPedidos(
  OrderNumber NVARCHAR(50) NOT NULL PRIMARY KEY
);

GO
/* =========================
   3) Tabla de Hechos (DW)
   ========================= */
CREATE TABLE dw.HechosVentas(
  FactSalesID    BIGINT IDENTITY(1,1) PRIMARY KEY,
  OrderNumber    NVARCHAR(50) NOT NULL,
  OrderDateKey   INT NOT NULL,
  ShipDateKey    INT NULL,
  ProductSK      BIGINT NOT NULL,
  StateSK        BIGINT NULL,
  SalesOfficeSK  BIGINT NULL,
  PromotionSK    BIGINT NULL,
  Quantity       INT NOT NULL,
  UnitPrice      DECIMAL(18,4) NOT NULL,
  DiscountAmount DECIMAL(18,4) NULL,
  NetAmount AS (Quantity * (UnitPrice - ISNULL(DiscountAmount,0))) PERSISTED,

  CONSTRAINT FK_HechosVentas_DimFechas_Order  FOREIGN KEY(OrderDateKey)  REFERENCES dw.DimFechas(DateKey),
  CONSTRAINT FK_HechosVentas_DimFechas_Ship   FOREIGN KEY(ShipDateKey)   REFERENCES dw.DimFechas(DateKey),
  CONSTRAINT FK_HechosVentas_DimProductos     FOREIGN KEY(ProductSK)     REFERENCES dw.DimProductos(ProductSK),
  CONSTRAINT FK_HechosVentas_DimEstados       FOREIGN KEY(StateSK)       REFERENCES dw.DimEstados(StateSK),
  CONSTRAINT FK_HechosVentas_DimOficinas      FOREIGN KEY(SalesOfficeSK) REFERENCES dw.DimOficinasVentas(SalesOfficeSK),
  CONSTRAINT FK_HechosVentas_DimPromociones   FOREIGN KEY(PromotionSK)   REFERENCES dw.DimPromociones(PromotionSK)
);

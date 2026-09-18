/****dim_date*********/

CREATE TABLE dbo.DimDate
(
    DateKey        INT NOT NULL PRIMARY KEY,  
    FullDate       DATE NOT NULL,
	DayNumber      TINYINT NOT NULL,
    MonthNumber    TINYINT NOT NULL,
    MonthName      VARCHAR(20) NOT NULL,
    QuarterNumber  TINYINT NOT NULL,
    YearNumber     SMALLINT NOT NULL,
	DayOfWeekNumber TINYINT NOT NULL,  -- 1 = Sunday, 7 = Saturday
    DayName        VARCHAR(20) NOT NULL,
	IsWeekend      BIT NOT NULL
);

DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate   DATE = '2019-12-31';

WITH N AS
(
    SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
)
INSERT INTO dbo.DimDate
(
    DateKey,
    FullDate,
    DayNumber,
    MonthNumber,
    MonthName,
    QuarterNumber,
    YearNumber,
    DayOfWeekNumber,
    DayName,
    IsWeekend
)
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY, n, @StartDate), 'yyyyMMdd')) AS DateKey,
    DATEADD(DAY, n, @StartDate) AS FullDate,

    DAY(DATEADD(DAY, n, @StartDate)) AS DayNumber,
    MONTH(DATEADD(DAY, n, @StartDate)) AS MonthNumber,
    DATENAME(MONTH, DATEADD(DAY, n, @StartDate)) AS MonthName,
    DATEPART(QUARTER, DATEADD(DAY, n, @StartDate)) AS QuarterNumber,
    YEAR(DATEADD(DAY, n, @StartDate)) AS YearNumber,

    DATEPART(WEEKDAY, DATEADD(DAY, n, @StartDate)) AS DayOfWeekNumber,
    DATENAME(WEEKDAY, DATEADD(DAY, n, @StartDate)) AS DayName,

    CASE 
        WHEN DATEPART(WEEKDAY, DATEADD(DAY, n, @StartDate)) IN (1,7)
        THEN 1 ELSE 0
    END AS IsWeekend
FROM N;
INSERT INTO DIMDATE VALUES(-1,'1900-01-01',1,1,'UNKNOWN',1,1,1,'UNKNOWN',0);


/*******************DIM_CUSTOMER and Dim_Seller***********************/
drop table [dbo].[Dim_Customer];
drop table [dbo].[Dim_Seller];

CREATE TABLE [dbo].[Dim_Customer](
	[Customer_key] [int] IDENTITY(1,1) NOT NULL,
    [customer_id] nvarchar(100) not null,
    [customer_unique_id] nvarchar(100) not null,
    [geography_key] int not null,
	CreatedDate datetime2 not null,
CONSTRAINT pk_Dim_Customer primary key(Customer_key),
constraint fk_Dim_Customer_geography foreign key(geography_key) references [dbo].[Dim_Geography](geography_key),
constraint uq_Dim_Customer unique(customer_id));


CREATE TABLE [dbo].[Dim_Seller](
	[Seller_key] [int] IDENTITY(1,1) NOT NULL,
    [seller_id] nvarchar(100) not null,
    [geography_key] int not null,
	CreatedDate datetime2 not null,
CONSTRAINT pk_Dim_Seller primary key(Seller_key),
constraint fk_Dim_Seller_geography foreign key(geography_key) references [dbo].[Dim_Geography](geography_key),
constraint uq_Dim_Seller unique(seller_id));


/*********data insert********/

Insert into [dbo].[Dim_Customer]
([customer_id],
 [customer_unique_id],
 [geography_key],
 CreatedDate
 )
 SELECT
 [customer_id],
 [customer_unique_id],
 [geography_key],
 GETDATE()
 FROM [dbo].[Raw_Customer] RC
 LEFT JOIN [dbo].[Dim_Geography] DG
 ON RC.customer_state = DG.state
 and RC.[customer_zip_code_prefix] = DG.zip_code_prefix;
 
 /*********Dim_Seller*********/
 Insert into [dbo].[Dim_Seller]
([seller_id],
 [geography_key],
 CreatedDate
 )
 SELECT
 [seller_id],
 COALESCE([geography_key],9999),
 GETDATE()
 FROM [dbo].[raw_sellers] RS
 LEFT JOIN [dbo].[Dim_Geography] DG
 --ON RS.[seller_city] = DG.city
 ON RS.[seller_state] = DG.state
 AND RS.seller_zip_code_prefix = DG.zip_code_prefix;

/*********DIM_Geography*****/
CREATE TABLE [dbo].[Dim_Geography](
	[geography_key] [int] IDENTITY(1,1) NOT NULL,
	[zip_code_prefix] [varchar](5) NULL,
	[city] [nvarchar](100) NULL,
	[state] [char](2) NULL,
	[region] [nvarchar](100) NULL,
CONSTRAINT pk_Dim_Geography primary key(geography_key),
constraint uq_Dim_Geography UNIQUE( zip_code_prefix,city, state));



WITH Geo_Ranking AS
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS State_Count,
        ROW_NUMBER() OVER
        (
            PARTITION BY 
                geolocation_zip_code_prefix,
                geolocation_city
            ORDER BY 
                COUNT(*) DESC
               -- LEN(geolocation_city) asc,
               -- geolocation_city ASC
        ) AS rn
    FROM dbo.raw_geolocation --where geolocation_zip_code_prefix ='21550'
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
) SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state
INTO dbo.[Stg_Geolocation_cleaned]
FROM Geo_Ranking
WHERE rn = 1 ;


WITH Geo_Ranking_1 AS
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS City_Count,
        ROW_NUMBER() OVER
        (
            PARTITION BY 
                geolocation_zip_code_prefix,
                geolocation_state
            ORDER BY 
                COUNT(*) DESC,
                LEN(geolocation_city) asc,
                geolocation_city ASC
        ) AS rn
    FROM dbo.[Stg_Geolocation_cleaned]
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
)
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state
INTO dbo.[Stg_Geolocation_cleaned_final]
FROM Geo_Ranking_1
WHERE rn = 1 ;


Insert into [dbo].[Dim_Geography]
(
[zip_code_prefix],
[city],
[state],
[region]
)
Select
DISTINCT
geolocation_zip_code_prefix,
geolocation_city,
geolocation_state,
CASE
    WHEN RL.geolocation_state IN ('SP','RJ','MG','ES') THEN 'Southeast'
    WHEN RL.geolocation_state IN ('PR','SC','RS') THEN 'South'
    WHEN RL.geolocation_state IN ('BA','PE','CE','PB','RN','AL','SE','PI','MA') THEN 'Northeast'
    WHEN RL.geolocation_state IN ('GO','MT','MS','DF') THEN 'Central-West'
    WHEN RL.geolocation_state IN ('AM','PA','RO','RR','AP','AC','TO') THEN 'North'
END AS region
from dbo.[Stg_Geolocation_cleaned_final] RL
WHERE NOT EXISTS
(
SELECT 1 FROM [dbo].[Dim_Geography] DG
 WHERE DG.zip_code_prefix = RL.[geolocation_zip_code_prefix]
 AND DG.[city] = RL.geolocation_city
AND DG.state = RL.geolocation_state
);

select * from dbo.[Stg_Geolocation_cleaned_final] where [geolocation_zip_code_prefix] ='80630'

/******source from customer and seller data for missing geography info***********/

Insert into [dbo].[Dim_Geography]
(
[zip_code_prefix],
[city],
[state],
[region]
)
 SELECT DISTINCT
    customer_zip_code_prefix,[customer_city],[customer_state],
	CASE
    WHEN [customer_state] IN ('SP','RJ','MG','ES') THEN 'Southeast'
    WHEN [customer_state] IN ('PR','SC','RS') THEN 'South'
    WHEN [customer_state] IN ('BA','PE','CE','PB','RN','AL','SE','PI','MA') THEN 'Northeast'
    WHEN [customer_state] IN ('GO','MT','MS','DF') THEN 'Central-West'
    WHEN [customer_state] IN ('AM','PA','RO','RR','AP','AC','TO') THEN 'North'
END AS region

FROM dbo.raw_customer where customer_zip_code_prefix in (
select customer_zip_code_prefix FROM dbo.raw_customer 
EXCEPT

SELECT DISTINCT
    geolocation_zip_code_prefix
FROM dbo.raw_geolocation)

--Insert into [dbo].[Dim_Geography]
--(
--[zip_code_prefix],
--[city],
--[state],
--[region]
--)
union 
SELECT DISTINCT
    [seller_zip_code_prefix],[seller_city],[seller_state],
	CASE
    WHEN [seller_state] IN ('SP','RJ','MG','ES') THEN 'Southeast'
    WHEN [seller_state] IN ('PR','SC','RS') THEN 'South'
    WHEN [seller_state] IN ('BA','PE','CE','PB','RN','AL','SE','PI','MA') THEN 'Northeast'
    WHEN [seller_state] IN ('GO','MT','MS','DF') THEN 'Central-West'
    WHEN [seller_state] IN ('AM','PA','RO','RR','AP','AC','TO') THEN 'North'
END AS region

FROM dbo.raw_sellers where [seller_zip_code_prefix] in (
select [seller_zip_code_prefix] FROM dbo.raw_sellers
EXCEPT

SELECT DISTINCT
    geolocation_zip_code_prefix
FROM dbo.raw_geolocation);
/************dim_product********/

DROP TABLE dbo.Dim_Products
CREATE TABLE dbo.Dim_Products
(Product_key int identity not null,
[product_id] nvarchar(100) not null,
[product_category_name] nvarchar(100)  null,
[product_category_name_english] nvarchar(100) null,
[product_name_length] [int] NULL,
[product_description_length] [int] NULL,
[product_photos_qty] [int] NULL,
[product_weight_g] [int] NULL,
[product_length_cm] [int] NULL,
[product_height_cm] [int] NULL,
[product_width_cm] [int] NULL,
CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
UpdatedDate DATETIME2 NULL
constraint pk_Dim_Products primary key(Product_key),
constraint uq_Dim_Products unique(product_id));

Insert into dbo.Dim_Products
([product_id],
[product_category_name],
[product_category_name_english],
[product_name_length],
[product_description_length],
[product_photos_qty],
[product_weight_g],
[product_length_cm],
[product_height_cm],
[product_width_cm]
)
select
[product_id],
COALESCE(NULLIF(RP.[product_category_name],''),'UNDEFINED'),
COALESCE(PC.[product_category_name_english],'UNDEFINED'),
[product_name_length],
[product_description_length],
[product_photos_qty],
[product_weight_g],
[product_length_cm],
[product_height_cm],
[product_width_cm]
from [dbo].[raw_products] RP
LEFT join [dbo].[dim_product_category] PC
ON RP.[product_category_name] = PC.[product_category_name];
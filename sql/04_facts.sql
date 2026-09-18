****fact_payment***/
 DROP TABLE [dbo].[Fact_Payments];

CREATE TABLE [dbo].[Fact_Payments]
(payment_key int identity not null,
[order_id] nvarchar(100) not null,
[payment_sequential] int not null,
[payment_type] nvarchar(50),
[payment_installments] int,
[payment_value] decimal(10,2),
Order_Purchased_date_key int not null,
CreatedDate DATETIME2(0) NOT NULL DEFAULT GETDATE(),
UpdatedDate DATETIME2(0) NULL
constraint PK_Fact_Payments PRIMARY KEY(payment_key),
constraint fk_Fact_Payments_date foreign key(Order_Purchased_date_key) references [dbo].[DimDate]([DateKey]),
CONSTRAINT UQ_Fact_Payments UNIQUE(order_id,[payment_sequential]));

INSERT INTO [dbo].[Fact_Payments]
([order_id],
[payment_sequential],
[payment_type],
[payment_installments],
[payment_value],
[Order_Purchased_date_key]
)
SELECT 
ROP.[order_id],
[payment_sequential],
[payment_type],
[payment_installments],
[payment_value],
COALESCE(DD.[DateKey],-1) AS [Order_Purchased_date_key]

FROM [dbo].[Raw_Order_Payments] ROP
INNER JOIN [dbo].[Raw_Orders] RO
ON ROP.order_id = RO.order_id
LEFT JOIN [dbo].[DimDate] DD
ON CAST(RO.[order_purchase_timestamp] AS DATE) = DD.FullDate
WHERE NOT EXISTS(
SELECT 1 FROM [dbo].[Fact_Payments] FP
WHERE FP.[order_id] = ROP.[order_id]
AND FP.[payment_sequential] = ROP.[payment_sequential]
);

SELECT COUNT(*) FROM [dbo].[Fact_Payments];
SELECT COUNT(*) FROM [dbo].[Raw_Order_Payments];

/*************/
CREATE TABLE dbo.Fact_Sales
(Sale_id int identity not null,
[order_id] nvarchar(100) not null,
[order_item_id] int not null,
Product_key int not null,
Customer_key int not null,
Seller_key int not null,
[order_status] nvarchar(50),
Order_Approved_date_key int not null,
Order_Purchased_date_key int not null,
Order_delivered_Carrier_date_key int not null,
Order_delivered_Customer_date_key int not null,
Order_estimated_delivery_date_key int not null,
shipping_limit_date_key int not null,
price decimal(10,2) not null,
[freight_value] decimal(10,2) not null,
Delivery_Days int,
Delivery_Delay_Days int,
CreatedDate DATETIME2(0) NOT NULL DEFAULT GETDATE(),
constraint pk_Fact_Sales primary key(Sale_id),
constraint fk_Fact_Sales_product foreign key(Product_key) references [dbo].[Dim_Products](Product_key),
constraint fk_Fact_Sales_customer foreign key(Customer_key) references [dbo].[Dim_Customer](Customer_key),
constraint fk_Fact_Sales_seller foreign key([Seller_key]) references [dbo].[Dim_Seller]([Seller_key]),
constraint fk_Fact_Sales_date foreign key(Order_Approved_date_key) references [dbo].[DimDate]([DateKey]),
constraint fk_Fact_Sales_date1 foreign key(Order_Purchased_date_key) references [dbo].[DimDate]([DateKey]),
constraint fk_Fact_Sales_date2 foreign key(Order_delivered_Carrier_date_key) references [dbo].[DimDate]([DateKey]),
constraint fk_Fact_Sales_date3 foreign key(Order_delivered_Customer_date_key) references [dbo].[DimDate]([DateKey]),
constraint fk_Fact_Sales_date4 foreign key(Order_estimated_delivery_date_key) references [dbo].[DimDate]([DateKey]),
constraint fk_Fact_Sales_date5 foreign key(shipping_limit_date_key) references [dbo].[DimDate]([DateKey]),
constraint uq_Fact_Sales unique ([order_id],[order_item_id]) );



INSERT INTO dbo.Fact_Sales 
([order_id],
[order_item_id],
[Product_key],
[Customer_key],
[Seller_key],
[order_status],
[Order_Approved_date_key],
[Order_Purchased_date_key],
[Order_delivered_Carrier_date_key],
[Order_delivered_Customer_date_key],
[Order_estimated_delivery_date_key],
[shipping_limit_date_key],
[price],
[freight_value],
[Delivery_Days],
[Delivery_Delay_Days],
[CreatedDate]
)
SELECT
ROI.[order_id],
ROI.[order_item_id],
COALESCE(DP.[Product_key],-1),
COALESCE(DC.[Customer_key],-1),
COALESCE(DS.[Seller_key],-1),
RO.[order_status],
COALESCE(DD1.[DateKey],-1) AS [Order_Approved_date_key],
COALESCE(DD.[DateKey],-1) AS [Order_Purchased_date_key],
COALESCE(DD2.[DateKey],-1) AS [Order_delivered_Carrier_date_key],
COALESCE(DD3.[DateKey],-1) AS [Order_delivered_Customer_date_key],
COALESCE(DD4.[DateKey],-1) AS [Order_estimated_delivery_date_key],
COALESCE(DD5.[DateKey],-1) AS [shipping_limit_date_key],
ROI.price,
ROI.[freight_value],
DATEDIFF(DAY,RO.[order_purchase_timestamp],RO.[order_delivered_customer_date]) AS [Delivery_Days] ,
DATEDIFF(DAY,RO.[order_estimated_delivery_date],RO.[order_delivered_customer_date]) [Delivery_Delay_Days],
GETDATE()
 FROM [dbo].[Raw_Order_Items] ROI
INNER JOIN [dbo].[Raw_Orders] RO
ON ROI.order_id = RO.order_id
LEFT JOIN [dbo].[Dim_Customer] DC
ON RO.customer_id =DC.[customer_id]
LEFT JOIN [dbo].[Dim_Products] DP
ON ROI.[product_id] = DP.product_id
LEFT JOIN [dbo].[Dim_Seller] DS
ON ROI.[seller_id] = DS.[seller_id]
LEFT JOIN [dbo].[DimDate] DD
ON CAST(RO.[order_purchase_timestamp] AS DATE) = DD.FullDate
LEFT JOIN [dbo].[DimDate] DD1
ON CAST(RO.[order_approved_at] AS DATE) = DD1.FullDate
LEFT JOIN [dbo].[DimDate] DD2
ON CAST(RO.[order_delivered_carrier_date] AS DATE) = DD2.FullDate
LEFT JOIN [dbo].[DimDate] DD3
ON CAST(RO.[order_delivered_customer_date] AS DATE) = DD3.FullDate
LEFT JOIN [dbo].[DimDate] DD4
ON CAST(RO.[order_estimated_delivery_date] AS DATE) = DD4.FullDate
LEFT JOIN [dbo].[DimDate] DD5
ON CAST(ROI.[shipping_limit_date] AS DATE) = DD5.FullDate;

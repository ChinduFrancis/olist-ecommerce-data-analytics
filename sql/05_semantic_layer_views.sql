ALTER VIEW dbo.VW_Sales_Analysis AS
SELECT
FS.[order_id],
FS.[order_item_id],
DP.[product_id],
DP.[product_category_name],
DP.[product_category_name_english],
DC.[customer_id],
DC.[customer_unique_id],
DG.[zip_code_prefix] AS Customer_zipcode,
DG.[city] AS Customer_city,
DG.[state] AS Customer_State,
DG.[region] AS Customer_region,
DS.[seller_id]  ,
DG1.[zip_code_prefix] AS Seller_zipcode,
DG1.[city] AS Seller_city,
DG1.[state] AS Seller_State,
DG1.[region] AS Seller_region,
FS.[order_status],
FS.[price],
FS.[freight_value],
FS.[Delivery_Days],
FS.[Delivery_Delay_Days],
DD.FullDate AS Purchase_date,
DD.[YearNumber] AS PurchaseYear,
DD.[MonthNumber] AS PurchaseMonth,
DD.[QuarterNumber] AS PurchaseQuarter,
DD1.FullDate AS Approved_date,
DD2.FullDate AS Carrier_Delivery_date,
DD3.FullDate AS Customer_Delivery_date,
DD4.FullDate AS Estimated_delivery_date,
DD5.FullDate AS Shipping_Limit_date

FROM [dbo].[Fact_Sales] FS
LEFT JOIN [dbo].[Dim_Customer] DC
ON FS.[Customer_key] =DC.[Customer_key]
LEFT JOIN [dbo].[Dim_Geography] DG
ON DC.[geography_key] = DG.[geography_key]
LEFT JOIN [dbo].[Dim_Products] DP
ON FS.[Product_key] = DP.[Product_key]
LEFT JOIN [dbo].[Dim_Seller] DS
ON FS.[Seller_key] = DS.[Seller_key]
LEFT JOIN [dbo].[Dim_Geography] DG1
ON DS.[geography_key] = DG1.[geography_key]
LEFT JOIN [dbo].[DimDate] DD
ON FS.[Order_Purchased_date_key] = DD.[DateKey]
LEFT JOIN [dbo].[DimDate] DD1
ON FS.[Order_Approved_date_key] = DD1.[DateKey]
LEFT JOIN [dbo].[DimDate] DD2
ON FS.[Order_delivered_Carrier_date_key] = DD2.[DateKey]
LEFT JOIN [dbo].[DimDate] DD3
ON FS.[Order_delivered_Customer_date_key] = DD3.[DateKey]
LEFT JOIN [dbo].[DimDate] DD4
ON FS.[Order_estimated_delivery_date_key] = DD4.[DateKey]
LEFT JOIN [dbo].[DimDate] DD5
ON FS.[shipping_limit_date_key] = DD5.[DateKey]
;



/****views for analysing Product performance*/
CREATE OR ALTER VIEW dbo.VW_Product_Performance
AS
SELECT
    product_category_name,
    product_category_name_english,
    COUNT(*) AS Items_Sold,
    COUNT(DISTINCT order_id) AS Orders,
    SUM(price) AS Product_Revenue,
    SUM(freight_value) AS Freight_Revenue,
    SUM(price + freight_value) AS Total_Revenue,
    AVG(price) AS Average_Product_Price,
    AVG(Delivery_Days) AS Average_Delivery_Days
FROM dbo.VW_Sales_Analysis
GROUP BY
    product_category_name,
    product_category_name_english;

SELECT * FROM dbo.VW_Product_Performance ORDER BY Total_Revenue DESC

	
/****** Object:  View [dbo].[view_Sales_KPI]	****/
CREATE OR ALTER VIEW dbo.[view_Sales_KPI] as
select 
count(distinct order_id) as Total_Orders,
count(distinct customer_unique_id) as Total_Customers,
sum(price) as Total_Revenue,
sum(freight_value) as Total_Freight_vale,
sum(price+freight_value) as Total_Order_Value,
cast(avg(price) as decimal(10,2)) as Average_Order_Value
from [dbo].[VW_Sales_Analysis]
;	


/****** Object:  View [dbo].[VW_Product_Sales]**/
CREATE OR ALTER VIEW [dbo].[VW_Product_Sales]
AS
select
product_id,
product_category_name,
product_category_name_english,
PurchaseYear,
PurchaseMonth,
sum(price) as Total_Revenue,
sum(freight_value) as Total_Freight_vale,
sum(price+freight_value) as Total_Order_Value,
cast(avg(price) as decimal(10,2)) as Average_Order_Value
from [dbo].[VW_Sales_Analysis]
group by  product_id,
product_category_name,
product_category_name_english,
PurchaseYear,
PurchaseMonth;
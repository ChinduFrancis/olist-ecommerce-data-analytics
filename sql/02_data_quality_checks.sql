/* Data Profiling*/

/*FIRST VALIDATE WHETHER COUNT OF ROWS MATCH WITH THE SOURCE FILE COUNT*/
SELECT COUNT(*) AS Geo_Location_Count FROM [dbo].[Raw_Geolocation]; --1000163
SELECT COUNT(*) AS Customer_Count FROM [dbo].[Raw_Customer];--99441
SELECT COUNT(*) as  Seller_Count FROM [dbo].[raw_sellers]; --3095
SELECT COUNT(*) as Order_Count FROM [dbo].[Raw_Orders];--99441
SELECT COUNT(*) as Order_Item_Count FROM [dbo].[Raw_Order_Items];--112650
SELECT COUNT(*) as  Payment_Count FROM [dbo].[Raw_Order_Payments];--103886
SELECT COUNT(*) as Product_Count FROM [dbo].[raw_products];--32951
SELECT COUNT(*) as Product_Category_Count FROM [dbo].[dim_product_category];--71
SELECT COUNT(*) as Product_Review_Count FROM [dbo].[Raw_Review];--99224
--Count of rows match with source file count.



/*Duplicate value check for key columns*/
Select [customer_id], count(*) from [dbo].[Raw_Customer] group by [customer_id] having count(*)>1;
Select [seller_id], count(*) from [dbo].[raw_sellers] group by [seller_id] having count(*)>1;
Select [order_id], count(*) from [dbo].[Raw_Orders] group by [order_id] having count(*)>1;
Select [product_id], count(*) from [dbo].[raw_products] group by [product_id] having count(*)>1;
Select [order_id],[payment_sequential], count(*) from [dbo].[Raw_Order_Payments] group by [order_id],payment_sequential having count(*)>1;
select [product_category_name],COUNT(*) from [dbo].[dim_product_category] GROUP BY [product_category_name] having count(*)>1;
Select [review_id],[order_id], count(*) from [dbo].[Raw_Review] group by [review_id],[order_id] having count(*)>1;
--Validated duplicate rows for key columns.There are no duplicate records for key columns

SELECT MIN(order_purchase_timestamp),MAX(order_purchase_timestamp)FROM  [dbo].[Raw_Orders];

/*Validating relationship between staging tables*/

/*1.Checking whether all orders have a product category*/
select [product_category_name],count(*) from [dbo].[raw_products] group by [product_category_name]   having count(*)>1 order by count(*) desc
select * from [dbo].[raw_products] where [product_category_name] = '';

Select  
COUNT(DISTINCT rp.product_id) AS ProductsWithoutCategory,
COUNT(DISTINCT roi.order_id) AS OrdersAffected,
COUNT(*) AS OrderItemsAffected 
from [dbo].[Raw_Order_Items] roi
inner join [dbo].[raw_products] rp
on roi.[product_id] = rp.[product_id]
and rp.[product_category_name] = '';

/*
Findings : 
There are 610 products for which product category name is not defined
There are 1451 distinct order_ids where product_category information is not available.
*/


--2.Order and Order Item

Select  count(ro.order_id) from [dbo].[Raw_Orders] ro
left join [dbo].[Raw_Order_Items] roi
on ro.order_id = roi.order_id
where roi.order_id is  null  
--for 775 Order_ids, order item details are not available.

Select order_status,count(ro.order_status) as status_count from [dbo].[Raw_Orders] ro
left join [dbo].[Raw_Order_Items] roi
on ro.order_id = roi.order_id
where roi.order_id is  null
group by order_status

--Other than 1 record, for which order item detail is not availble, majority belong to category unavailable/cancelled.So it is reasonable when line level details are not available.
/*Analysis: Nearly all of these orders have a status of unavailable or canceled, indicating that the absence of order item records is consistent with the business process.*/


Select distinct count(roi.order_id) from  [dbo].[Raw_Order_Items] roi
left join [dbo].[Raw_Orders] ro
on roi.order_id = ro.order_id
where ro.order_id is null 
--all order items present in order item table have a parent order id in order table.

/*3.PAYMENT AND ORDERITEM RELATIONSHIP*/
/*Expectation: The sum of payment_value for an order_id should match with the sum of price and freight_value  available in order_items*/

select
a.order_id,
a.price,
b. paid_amount
from 
(
select ro.order_id,sum(roi.price+roi.freight_value) as price 
from [dbo].[Raw_Orders] ro
inner join [dbo].[Raw_Order_Items] roi
on ro.order_id = roi.order_id
group by ro.order_id)a
left join 
( select rp.order_id,sum(payment_value) as paid_amount from  [dbo].[Raw_Order_Payments] rp group by order_id)b
on a.order_id =b.order_id
where a.price <> b. paid_amount

WITH OrderAmount AS
(
    SELECT
        order_id,
        SUM(price + freight_value) AS OrderAmount
    FROM dbo.Raw_Order_Items
    GROUP BY order_id
),
PaymentAmount AS
(
    SELECT
        order_id,
        SUM(payment_value) AS PaidAmount
    FROM dbo.Raw_Order_Payments
    GROUP BY order_id
)
SELECT
    oa.order_id,
    oa.OrderAmount,
    pa.PaidAmount,
    oa.OrderAmount - pa.PaidAmount AS Difference
FROM OrderAmount oa
LEFT JOIN PaymentAmount pa
    ON oa.order_id = pa.order_id
WHERE ABS(oa.OrderAmount - pa.PaidAmount) > 0.01
order by difference desc

/*Finding: There are 303 order ids out of total 99400 orderids where the payment amount doesnt reconcile to the price which is about .3% of total records.
            This suggest high level of data quality of records*/


WITH OrderAmount AS
(
    SELECT
        order_id,
        SUM(price + freight_value) AS OrderAmount
    FROM dbo.Raw_Order_Items
    GROUP BY order_id
),
PaymentAmount AS
(
    SELECT
        order_id,
        SUM(payment_value) AS PaidAmount
    FROM dbo.Raw_Order_Payments
    GROUP BY order_id
)
SELECT
   ro.[order_status],count(*) as Ordercount
  FROM OrderAmount oa
 JOIN PaymentAmount pa
    ON oa.order_id = pa.order_id
join [dbo].[Raw_Orders] ro
on oa.order_id = ro.order_id
WHERE ABS(oa.OrderAmount - pa.PaidAmount) > 0.01
group by ro.[order_status]
order by Ordercount desc

/*4.Verify whether all orders have a valid customer id*/

Select [order_id],ro.[customer_id]
from [dbo].[Raw_Orders] ro
left join [dbo].[Raw_Customer] rc
on ro.customer_id = rc.customer_id
where  rc.customer_id is null
--0 records returned
/*Verified that every order has a corresponding customer record.*/

/*5.Verify whether all orders have a valid seller id*/
Select [order_id],roi.[seller_id]
from [dbo].[Raw_Order_Items] roi
left join [dbo].[raw_sellers] rs
on roi.[seller_id] = rs.[seller_id]
where  rs.[seller_id] is null
/*Verified that every order has a corresponding seller record.*/

/*6.Verify whether all orders have a valid product id*/
Select [order_id],roi.[product_id]
from [dbo].[Raw_Order_Items] roi
left join [dbo].[raw_products] rp
on roi.[product_id] = rp.[product_id]
where  rp.[product_id] is null
/*Verified that every order has a corresponding product record.*/

/*7.Verify whether all reviews have a valid order id*/
Select rr.[review_id],
rr.[order_id] from [dbo].[Raw_Review] rr
left join [dbo].[Raw_Orders] ro
on rr.[order_id] = ro.[order_id]
where  ro.[order_id] is null
/*Every review references a valid order in the Raw_Orders table.*/

/*8.Verify whether all payments have a valid order id*/
Select rp.[order_id]
 from [dbo].[Raw_Order_Payments]rp
left join [dbo].[Raw_Orders] ro
on rp.[order_id] = ro.[order_id]
where  ro.[order_id] is null
/*Every payment references a valid order in the Raw_Orders table.*/
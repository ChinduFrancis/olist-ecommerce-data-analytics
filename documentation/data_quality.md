**# Data Quality Assessment and Cleansing**



**## Overview**



Before building the dimensional model, the Olist datasets were profiled to identify data quality issues that could affect the accuracy, consistency, and reliability of analytical reporting.



The original CSV files were loaded directly into Microsoft SQL Server staging tables. Data quality checks and cleansing activities were performed on the staging data, while the original source data was preserved unchanged.



The validated and cleansed staging data was subsequently used to populate the fact and dimension tables that support the Power BI semantic layer.



**## Data Quality Process**



```text

Olist CSV Files

\&#x20;      │

\&#x20;      ▼

SQL Server Staging Tables

\&#x20;      │

\&#x20;      ▼

Data Quality Assessment \\\& Cleansing

\&#x20;      │

\&#x20;      ├── Data Standardization

\&#x20;      ├── Completeness Checks

\&#x20;      ├── Duplicate Checks

\&#x20;      ├── Referential Integrity Checks

\&#x20;      └── Financial Reconciliation

\&#x20;      │

\&#x20;      ▼

Clean / Validated Data

\&#x20;      │

\&#x20;      ▼

Fact \\\& Dimension Tables

\&#x20;      │

\&#x20;      ▼

Semantic Layer Views

\&#x20;      │

\&#x20;      ▼

Power BI

```



**## 1. City Name Standardization**



\### Issue



The geolocation dataset contained multiple city-name variations for the same ZIP code and state combination.



These variations were primarily caused by:



\- Spelling inconsistencies

\- Abbreviations

\- Formatting differences

\- Typographical errors



\### Example



| ZIP Code | City | State |

|---|---|---|

| 69919 | rio bracnco | AC |

| 69919 | rio branco | AC |



\### Resolution



A rule-based standardization approach was implemented to create a cleaned version of the geolocation dataset without modifying the original source data.



For each ZIP code and state combination, city names were ranked using the following criteria:



1\. \*\*Highest occurrence frequency\*\* — the city name appearing most frequently was selected.

2\. \*\*Shortest city name length\*\* — used as a secondary tie-breaker when multiple names had the same frequency.

3\. \*\*Alphabetical order\*\* — used as the final tie-breaker when frequency and length were identical.



The highest-ranked city name was retained in the cleaned geolocation staging table:



`stg\\\_geolocation\\\_clean`



This table was subsequently used to populate the `Dim\\\_Geography` dimension.



\### Methodology Note



This is a heuristic, rule-based standardization technique, rather than an authoritative correction.



The approach assumes that the most frequently occurring representation of a city name is the most reliable. Deterministic tie-breaking rules ensure that the ETL process produces consistent results.



This approach:



\- Preserves the original source data.

\- Avoids maintaining a manual lookup table.

\- Produces consistent geography values.

\- Provides a standardized geography reference for analytical reporting.



**## 2. Conflicting State for the Same ZIP Code and City**



\### Issue



Some ZIP code and city combinations were associated with multiple states in the geolocation dataset.



\### Example



| ZIP Code | City | State |

|---|---|---|

| 21550 | rio de janeiro | RJ |

| 21550 | rio de janeiro | AC |



\### Validation



The following query was used to identify ZIP code and city combinations associated with multiple states:



```sql

SELECT

\&#x20;   geolocation\\\_zip\\\_code\\\_prefix,

\&#x20;   geolocation\\\_city,

\&#x20;   COUNT(DISTINCT geolocation\\\_state) AS State\\\_Count

FROM dbo.raw\\\_geolocation

GROUP BY

\&#x20;   geolocation\\\_zip\\\_code\\\_prefix,

\&#x20;   geolocation\\\_city

HAVING COUNT(DISTINCT geolocation\\\_state) > 1;

```



\### Resolution



A frequency-based ranking approach was applied.



For each ZIP code and city combination:



\- The state occurring most frequently in the source data was retained.

\- Lower-frequency conflicting mappings were excluded from the cleaned geography staging data.



This provided a deterministic method for resolving conflicting geography assignments while preserving the original source data.



**## 3. Missing Geography Reference Records**



\### Issue



A comparison between the customer data and the geolocation reference identified ZIP code prefixes that were present in the customer dataset but absent from the geolocation dataset.



\### Validation



```sql

SELECT DISTINCT customer\\\_zip\\\_code\\\_prefix

FROM dbo.raw\\\_customers



EXCEPT



SELECT DISTINCT geolocation\\\_zip\\\_code\\\_prefix

FROM dbo.raw\\\_geolocation;

```



\### Findings



A total of \*\*157 customer ZIP code prefixes\*\* were not available in the geolocation reference dataset.



\### Resolution



The missing geography records were incorporated into the Geography dimension using the available customer attributes:



\- Customer ZIP code prefix

\- City

\- State



The original geolocation source data remained unchanged.



**## 4. Seller Geography Validation**



\### Issue



Some seller records failed to map to the Geography dimension because of inconsistencies between seller geography attributes and the standardized geography reference.



\### Resolution



Seller records were mapped to the Geography dimension using a combination of:



\- ZIP code prefix

\- State



This combination proved more reliable than city names because city names contained spelling inconsistencies in the source data.



Any records that could not be mapped were assigned to an \*\*Unknown Geography\*\* member.



This approach maintains referential integrity while ensuring that unmatched seller records remain available for analysis.



**## 5. Clean Geography Staging Layer**



To avoid modifying the original source data, a dedicated cleaned geography staging layer was introduced.



The cleansing process followed the sequence below:



1\. Load raw geolocation data into the staging area.

2\. Identify inconsistent city names and conflicting ZIP code–city–state mappings.

3\. Resolve conflicts using frequency-based ranking.

4\. Create the cleaned geography staging table.

5\. Load the Geography dimension from the cleaned staging data.

6\. Load Customer and Seller dimensions by referencing the Geography dimension.



This approach preserves the integrity of the original source data while ensuring that the dimensional model is built on standardized and validated geography information.



**## 6. Handling Missing Product Category Names**



\### Issue



The product dataset contained NULL or blank values in the `product\\\_category\\\_name` attribute.



Product category is an important descriptive attribute used for product-level analysis and reporting, so missing category values needed to be handled before loading the `Dim\\\_Product` dimension.



Additionally, the product category translation reference did not contain English translations for every Portuguese category available in the product source data.



\### Resolution



A default category value of `UNDEFINED` was assigned when product category information was missing or unavailable.



The cleansing logic included:



\- Replacing NULL or blank Portuguese category names with `UNDEFINED`.

\- Replacing missing English category translations with `UNDEFINED`.

\- Preserving the original product data without modification.

\- Applying the cleansing logic during the dimension-loading process.



**## 7. NULL and Duplicate Key Checks**



NULL and duplicate-value checks were performed on key columns across the staging datasets.



The purpose of these checks was to identify:



\- Missing key values

\- Duplicate business keys

\- Potential primary-key violations

\- Records that could affect referential integrity



These checks were performed before loading the dimensional model.



**## 8. Product Category Availability for Orders**



\### Objective



The relationship between orders, order items, products, and product categories was validated to identify orders for which product category information was unavailable.



\### Findings



The analysis identified:



\- \*\*610 products\*\* for which product category information was not defined.

\- \*\*1,451 distinct orders\*\* for which product-category information was unavailable.



\### Resolution



Missing product categories were handled using the `UNDEFINED` category described in Section 6.



This allows affected records to remain in the analytical model while maintaining a consistent dimension value rather than introducing NULL category members.



**## 9. Order and Order-Item Relationship**



\### Objective



The relationship between orders and order items was validated to identify orders without corresponding order-item detail.



\### Findings



Only \*\*one order\*\* was identified without corresponding order-item detail.



The majority of orders associated with missing order-item information belonged to statuses such as:



\- `unavailable`

\- `canceled`



\### Analysis



The absence of order-item records is therefore largely consistent with the business process for orders that were unavailable or canceled.



The remaining exception was identified for further review rather than being automatically removed from the dataset.



**## 10. Payment and Order-Item Reconciliation**



\### Objective



The payment and order-item datasets were reconciled at the `order\\\_id` level to identify potential inconsistencies between recorded payment amounts and corresponding order-item values.



\### Validation Logic



For each order, the Order Amount was calculated as:



```text

SUM(price + freight\\\_value)

```



from the order-item data.



The Paid Amount was calculated as:



```text

SUM(payment\\\_value)

```



from the payment data.



The two amounts were then compared at the `order\\\_id` level.



A tolerance of `0.01` was applied to account for minor rounding differences.



\### SQL Validation



```sql

WITH OrderAmount AS

(

\&#x20;   SELECT

\&#x20;       order\\\_id,

\&#x20;       SUM(price + freight\\\_value) AS OrderAmount

\&#x20;   FROM dbo.Raw\\\_Order\\\_Items

\&#x20;   GROUP BY order\\\_id

),

PaymentAmount AS

(

\&#x20;   SELECT

\&#x20;       order\\\_id,

\&#x20;       SUM(payment\\\_value) AS PaidAmount

\&#x20;   FROM dbo.Raw\\\_Order\\\_Payments

\&#x20;   GROUP BY order\\\_id

)

SELECT

\&#x20;   oa.order\\\_id,

\&#x20;   oa.OrderAmount,

\&#x20;   pa.PaidAmount,

\&#x20;   oa.OrderAmount - pa.PaidAmount AS Difference

FROM OrderAmount oa

LEFT JOIN PaymentAmount pa

\&#x20;   ON oa.order\\\_id = pa.order\\\_id

WHERE ABS(oa.OrderAmount - pa.PaidAmount) > 0.01

ORDER BY Difference DESC;

```



**### Findings**



Out of \*\*99,400 orders\*\*, \*\*303 orders\*\* showed a difference greater than the `0.01` tolerance.



This represents approximately \*\*0.3% of orders\*\*.



\### Analysis



The reconciliation indicates a high level of consistency between the payment and order-item datasets, with only a small proportion of orders showing a difference greater than the defined tolerance.



The identified exceptions were retained rather than modifying the original source values.



\## 11. Order Customer and Seller Validation



\### Objective



The order data was validated to ensure that orders could be associated with valid customer and seller identifiers.



The following relationships were reviewed:



\- `Order → Customer`

\- `Order Item → Seller`



The checks were used to identify potential orphan records and ensure that the dimensional model could maintain appropriate referential relationships between orders, customers, and sellers.



Records requiring special handling were reviewed before loading the fact tables.



**## Data Quality Summary**



The data quality assessment focused on the following areas:



| Area | Validation / Cleansing |

|---|---|

| Geography | City-name standardization and conflicting state resolution |

| Completeness | NULL, missing geography and missing product-category checks |

| Uniqueness | Duplicate key checks |

| Referential Integrity | Customer, seller, product and order-item relationships |

| Financial Consistency | Payment vs. order-item reconciliation |

| Standardization | Geography and product-category standardization |

| Exception Handling | Unknown Geography and Undefined Product Category |



The overall approach was designed to preserve the original source data while creating validated and standardized data for analytical modeling.



The cleaned staging layer provided the foundation for the subsequent fact and dimension tables and the semantic layer consumed by Power BI.




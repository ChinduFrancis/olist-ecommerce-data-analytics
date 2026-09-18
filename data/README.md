**Dataset**

This project uses the Brazilian E-Commerce Public Dataset by Olist.

The original dataset contains multiple CSV files covering orders, customers, sellers, products, payments, reviews, and geolocation data.

The raw CSV files are not included in this repository. They were downloaded separately and loaded into Microsoft SQL Server as the source layer for this project.



**Source Data**

The dataset can be obtained from the original Olist dataset source.

The CSV files used in this project include:

•	olist\_customers\_dataset.csv

•	olist\_geolocation\_dataset.csv

•	olist\_order\_items\_dataset.csv

•	olist\_order\_payments\_dataset.csv

•	olist\_order\_reviews\_dataset.csv

•	olist\_orders\_dataset.csv

•	olist\_products\_dataset.csv

•	olist\_sellers\_dataset.csv

•	product\_category\_name\_translation.csv



**Data Flow**

Olist CSV Files

&#x20;      ↓

Staging Tables

&#x20;      ↓

Data Quality Checks

&#x20;      ↓

Fact \& Dimension Tables

&#x20;      ↓

Semantic Layer Views

&#x20;      ↓

Power BI






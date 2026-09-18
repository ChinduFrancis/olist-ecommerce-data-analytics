CREATE TABLE dbo.Raw_Review (
    review_id NVARCHAR(100) NOT NULL,
    order_id NVARCHAR(100) NOT NULL,
    review_score INT NULL,
    review_comment_title  NVARCHAR(300) NULL,
    review_comment_message NVARCHAR(300) NULL,
    review_creation_date date,
	review_answer_timestamp datetime2(0)
  
);

CREATE TABLE dbo.Raw_Orders (
   	order_id nvarchar(200) NOT NULL,
	customer_id nvarchar(100) not null,
	order_status nvarchar(50) not null,
	order_purchase_timestamp datetime2(7),
	order_approved_at datetime2(7),
	order_delivered_carrier_date datetime2(7),
	order_delivered_customer_date datetime2(7),
	order_estimated_delivery_date datetime2(7)
 CONSTRAINT [PK_Raw_Orders] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

select * from dbo.Raw_Orders

CREATE TABLE dbo.Raw_products (
    product_id NVARCHAR(100) NOT NULL,
    product_category_name NVARCHAR(100) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL,

    CONSTRAINT PK_raw_products PRIMARY KEY (product_id)
);

CREATE TABLE dbo.raw_sellers (
    seller_id NVARCHAR(100) NOT NULL,
    seller_zip_code_prefix VARCHAR(10) NULL,
    seller_city NVARCHAR(100) NULL,
    seller_state CHAR(2) NULL,

    CONSTRAINT PK_raw_sellers PRIMARY KEY (seller_id)
);
CREATE TABLE dbo.dim_product_category (
    product_category_name NVARCHAR(100) NOT NULL,
    product_category_name_english NVARCHAR(100) NOT NULL,

    CONSTRAINT PK_dim_product_category 
    PRIMARY KEY (product_category_name)
);
drop TABLE dbo.Raw_Review
CREATE TABLE dbo.Raw_Review (
    review_id NVARCHAR(100) NOT NULL,
    order_id NVARCHAR(100) NOT NULL,
    review_score INT NULL,
    review_comment_title  NVARCHAR(300) NULL,
    review_comment_message NVARCHAR(300) NULL,
    review_creation_date date,
	review_answer_timestamp datetime2(0)
  
);



CREATE TABLE dbo.Raw_Order_Items (
    order_id NVARCHAR(100) NOT NULL,
	order_item_id int not null,
    product_id NVARCHAR(100) NOT NULL,
    seller_id NVARCHAR(100) NOT NULL,
    shipping_limit_date datetime2(0),
    price decimal(10, 2),
	freight_value decimal(10, 2)
    CONSTRAINT PK_Raw_Order_Items 
    PRIMARY KEY (order_id,order_item_id)
);

CREATE TABLE dbo.Raw_Order_Payments (
    order_id NVARCHAR(100) NOT NULL,
	payment_sequential int not null,
    payment_type NVARCHAR(50) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value decimal(10, 2)
	CONSTRAINT PK_Raw_Order_Payments 
    PRIMARY KEY (order_id,payment_sequential)
);


CREATE TABLE [dbo].[Raw_Customer](
	[customer_id] [nvarchar](100) NOT NULL,
	[customer_unique_id] [nvarchar](100) NOT NULL,
	[customer_zip_code_prefix] [nchar](10) NOT NULL,
	[customer_city] [nchar](50) NOT NULL,
	[customer_state] [nchar](2) NOT NULL,
 CONSTRAINT [PK_Raw_Customer] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
DROP TABLE IF EXISTS silver.supplychaindataset;

CREATE TABLE silver.supplychaindataset (
    -- payment Type
    payment_type TEXT,

    -- Shipping
    days_for_shipping_real INTEGER,
    days_for_shipment_scheduled INTEGER,
    shipping_mode TEXT,
    shipping_date DATE,

    -- Delivery
    delivery_status TEXT,
    late_delivery_risk INTEGER,

    -- Customer
    customer_id INTEGER,
    customer_fname TEXT,
    customer_lname TEXT,
    customer_segment TEXT,
    customer_city TEXT,
    customer_country TEXT,
    customer_state TEXT,
    customer_street TEXT,
    customer_zipcode TEXT,

    -- Department
    department_id INTEGER,
    department_name TEXT,

    -- Location
    latitude NUMERIC(18, 10),
    longitude NUMERIC(18, 10),
    market TEXT,

    -- Order
    order_id INTEGER,
    order_customer_id INTEGER,
    order_date DATE,
    order_status TEXT,
    order_city TEXT,
    order_country TEXT,
    order_region TEXT,
    order_state TEXT,
    order_zipcode TEXT,

    -- Order Item
    order_item_id INTEGER,
    order_item_cardprod_id INTEGER,
    order_item_quantity INTEGER,
    order_item_discount NUMERIC(10, 2),
    order_item_discount_rate NUMERIC(10, 4),
    order_item_product_price NUMERIC(10, 2),
    order_item_profit_ratio NUMERIC(10, 4),
    order_item_total NUMERIC(10, 2),
    order_profit_per_order NUMERIC(10, 2),

    -- Sales & Revenue
    sales NUMERIC(10, 2),
    benefit_per_order NUMERIC(10, 2),
    sales_per_customer NUMERIC(10, 2),

    -- Product
    product_card_id INTEGER,
    product_category_id INTEGER,
    category_id INTEGER,
    category_name TEXT,
    product_name TEXT,
    product_price NUMERIC(10, 2),
    product_status INTEGER
);

INSERT INTO silver.supplychaindataset
SELECT
    -- payment
    TRIM("Type") AS payment_type,

    -- Shipping
    "Days for shipping (real)"::INTEGER,
    "Days for shipment (scheduled)"::INTEGER,
    TRIM("Shipping Mode"),
    TRIM("shipping date (DateOrders)")::DATE,

    -- Delivery
    TRIM("Delivery Status"),
    "Late_delivery_risk"::INTEGER,

    -- Customer
    "Customer Id"::INTEGER,
    INITCAP(TRIM("Customer Fname")),
    INITCAP(TRIM("Customer Lname")),
    TRIM("Customer Segment"),
    INITCAP(TRIM("Customer City")),
    TRIM("Customer Country"),
    TRIM("Customer State"),
    TRIM("Customer Street"),
    TRIM("Customer Zipcode"),

    -- Department
    "Department Id"::INTEGER,
    TRIM("Department Name"),

    -- Location
    "Latitude"::NUMERIC(18, 10),
    "Longitude"::NUMERIC(18, 10),
    TRIM("Market"),

    -- Order
    "Order Id"::INTEGER,
    "Order Customer Id"::INTEGER,
    TRIM("order date (DateOrders)")::DATE,
    TRIM("Order Status"),
    INITCAP(TRIM("Order City")),
    TRIM("Order Country"),
    TRIM("Order Region"),
    TRIM("Order State"),
    TRIM("Order Zipcode"),

    -- Order Item
    "Order Item Id"::INTEGER,
    "Order Item Cardprod Id"::INTEGER,
    "Order Item Quantity"::INTEGER,
    "Order Item Discount"::NUMERIC(10, 2),
    "Order Item Discount Rate"::NUMERIC(10, 4),
    "Order Item Product Price"::NUMERIC(10, 2),
    "Order Item Profit Ratio"::NUMERIC(10, 4),
    "Order Item Total"::NUMERIC(10, 2),
    "Order Profit Per Order"::NUMERIC(10, 2),

    -- Sales & Revenue
    "Sales"::NUMERIC(10, 2),
    "Benefit per order"::NUMERIC(10, 2),
    "Sales per customer"::NUMERIC(10, 2),

    -- Product
    "Product Card Id"::INTEGER,
    "Product Category Id"::INTEGER,
    "Category Id"::INTEGER,
    TRIM("Category Name"),
    TRIM("Product Name"),
    "Product Price"::NUMERIC(10, 2),
    "Product Status"::INTEGER

FROM bronze."supplychaindataset";

SELECT * FROM silver.supplychaindataset;





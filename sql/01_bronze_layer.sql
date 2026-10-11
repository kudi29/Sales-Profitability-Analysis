CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

DROP TABLE IF EXISTS bronze."supplychaindataset";

CREATE TABLE bronze."supplychaindataset" (
    "Type" TEXT,
    "Days for shipping (real)" TEXT,
    "Days for shipment (scheduled)" TEXT,
    "Benefit per order" TEXT,
    "Sales per customer" TEXT,
    "Delivery Status" TEXT,
    "Late_delivery_risk" TEXT,
    "Category Id" TEXT,
    "Category Name" TEXT,
    "Customer City" TEXT,
    "Customer Country" TEXT,
    "Customer Id" TEXT,
    "Customer Fname" TEXT,
    "Customer Lname" TEXT,
    "Customer Segment" TEXT,
    "Customer State" TEXT,
    "Customer Street" TEXT,
    "Customer Zipcode" TEXT,
    "Department Id" TEXT,
    "Department Name" TEXT,
    "Latitude" TEXT,
    "Longitude" TEXT,
    "Market" TEXT,
    "Order City" TEXT,
    "Order Country" TEXT,
    "Order Customer Id" TEXT,
    "order date (DateOrders)" TEXT,
    "Order Id" TEXT,
    "Order Item Cardprod Id" TEXT,
    "Order Item Discount" TEXT,
    "Order Item Discount Rate" TEXT,
    "Order Item Id" TEXT,
    "Order Item Product Price" TEXT,
    "Order Item Profit Ratio" TEXT,
    "Order Item Quantity" TEXT,
    "Sales" TEXT,
    "Order Item Total" TEXT,
    "Order Profit Per Order" TEXT,
    "Order Region" TEXT,
    "Order State" TEXT,
    "Order Status" TEXT,
    "Order Zipcode" TEXT,
    "Product Card Id" TEXT,
    "Product Category Id" TEXT,
    "Product Name" TEXT,
    "Product Price" TEXT,
    "Product Status" TEXT,
    "shipping date (DateOrders)" TEXT,
    "Shipping Mode" TEXT,
    "extra1" TEXT,
    "extra2" TEXT,
    "extra3" TEXT,
    "extra4" TEXT,
    "extra5" TEXT
);

COPY bronze."supplychaindataset"
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/supply_chain_project/DataCoSupplyChainDataset.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'LATIN1'
);

-- Clean up the extra columns after loading
ALTER TABLE bronze."supplychaindataset"
    DROP COLUMN "extra1",
    DROP COLUMN "extra2",
    DROP COLUMN "extra3",
    DROP COLUMN "extra4",
    DROP COLUMN "extra5";
	
SELECT 
	*
FROM bronze."supplychaindataset";







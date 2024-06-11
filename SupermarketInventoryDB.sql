-- PostgreSQL dump
-- Version: 12.4
-- Host: localhost
-- Generation Time: Jun 05, 2024 at 04:38 PM

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- Database: supermarketinvetorydb

-- Table structure for table category

CREATE TABLE category (
    categoryID serial PRIMARY KEY,
    categoryName varchar(30) NOT NULL
);

-- Dumping data for table category

INSERT INTO category (categoryID, categoryName) VALUES
(1, 'nyama');

-- Table structure for table supplier

CREATE TABLE supplier (
    supplierID serial PRIMARY KEY,
    supplierFName varchar(30) NOT NULL,
    supplierLName varchar(30) NOT NULL
);

-- Dumping data for table supplier

INSERT INTO supplier (supplierID, supplierFName, supplierLName) VALUES
(1, 'gwakila', 'eliah');

-- Table structure for table product

CREATE TABLE product (
    productId serial PRIMARY KEY,
    productName varchar(30) NOT NULL,
    categoryID int REFERENCES category(categoryID) ON DELETE CASCADE ON UPDATE CASCADE,
    supplierID int REFERENCES supplier(supplierID) ON DELETE CASCADE ON UPDATE CASCADE,
    unitMeasure varchar(30),
    totalUnit int,
    unitPrice int,
    costPrice int DEFAULT 0,
    sellingPrice int DEFAULT 0,
    expireDate date
);

-- Dumping data for table product

INSERT INTO product (productId, productName, categoryID, supplierID, unitMeasure, totalUnit, unitPrice, costPrice, sellingPrice, expireDate) VALUES
(3, 'nyama ya kuk', 1, 1, 'kg', 1, 8000, 8000, 12000, '2024-06-07'),
(4, 'nyama ya ngombe', 1, NULL, 'kg', 2, 8000, 16000, 24000, '2024-06-07'),
(5, 'mchele', 1, 1, 'kg', -3, 2000, -6000, -9000, '2024-06-07');

-- Triggers for table product

CREATE OR REPLACE FUNCTION trg_before_insert_costPrice()
RETURNS TRIGGER AS $$
BEGIN
    NEW.costPrice := NEW.unitPrice * NEW.totalUnit;
    NEW.sellingPrice := NEW.costPrice * 1.5;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_insert_costPrice
BEFORE INSERT ON product
FOR EACH ROW
EXECUTE FUNCTION trg_before_insert_costPrice();

CREATE OR REPLACE FUNCTION trg_before_update_costPrice()
RETURNS TRIGGER AS $$
BEGIN
    NEW.costPrice := NEW.unitPrice * NEW.totalUnit;
    NEW.sellingPrice := NEW.costPrice * 1.5;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_update_costPrice
BEFORE UPDATE ON product
FOR EACH ROW
EXECUTE FUNCTION trg_before_update_costPrice();

CREATE OR REPLACE FUNCTION notification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.totalUnit <= 1 THEN
        INSERT INTO productstatus (productId, messege)
        VALUES (NEW.productId, NEW.productName || ' inakaribia kuisha wasiliana na wasambazaji wetu');
    ELSE
        DELETE FROM productstatus WHERE productId = NEW.productId;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notification
AFTER UPDATE ON product
FOR EACH ROW
EXECUTE FUNCTION notification();

-- Table structure for table customer

CREATE TABLE customer (
    customerID serial PRIMARY KEY,
    firstname varchar(30) NOT NULL,
    lastname varchar(30) NOT NULL
);

-- Dumping data for table customer

INSERT INTO customer (customerID, firstname, lastname) VALUES
(1, 'alex', 'ziya');

-- Table structure for table customercontact

CREATE TABLE customercontact (
    contactId serial PRIMARY KEY,
    customerID int REFERENCES customer(customerID) ON DELETE CASCADE ON UPDATE CASCADE,
    phoneNumber varchar(15) UNIQUE,
    email varchar(30) UNIQUE
);

-- Table structure for table inventory

CREATE TABLE inventory (
    inventoryID serial PRIMARY KEY,
    productId int REFERENCES product(productId) ON DELETE CASCADE ON UPDATE CASCADE,
    quantity int NOT NULL,
    lastUpdated date
);

-- Table structure for table productstatus

CREATE TABLE productstatus (
    notificationID serial PRIMARY KEY,
    productId int REFERENCES product(productId) ON DELETE CASCADE ON UPDATE CASCADE,
    messege text
);

-- Dumping data for table productstatus

INSERT INTO productstatus (notificationID, productId, messege) VALUES
(4, 3, 'nyama ya kuk inakaribia kuisha wasiliana na wasambazaji wetu'),
(7, 5, 'mchele inakaribia kuisha wasiliana na wasambazaji wetu');

-- Table structure for table sales

CREATE TABLE sales (
    saleID serial PRIMARY KEY,
    productId int REFERENCES product(productId) ON DELETE CASCADE ON UPDATE CASCADE,
    customerID int REFERENCES customer(customerID) ON DELETE CASCADE ON UPDATE CASCADE,
    quantitySolid int DEFAULT 0,
    dateOfSale timestamp,
    totalAmount int
);

-- Dumping data for table sales

INSERT INTO sales (saleID, productId, customerID, quantitySolid, dateOfSale, totalAmount) VALUES
(1, 3, 1, 3, '2024-06-04 21:00:00', NULL),
(2, 3, 1, 3, '2024-06-04 21:00:00', NULL),
(3, 3, 1, 4, '2024-06-05 21:00:00', NULL),
(4, 5, 1, 3, '2024-06-04 21:00:00', NULL),
(5, 5, 1, 40, '2024-06-04 21:00:00', NULL),
(6, 5, 1, 30, '2024-06-04 21:00:00', NULL),
(7, 5, 1, 8, '2024-06-04 21:00:00', NULL),
(8, 5, 1, 1, '2024-06-05 21:00:00', NULL),
(9, 5, 1, 5, '2024-06-05 21:00:00', NULL),
(10, 4, 1, -6, '2024-06-04 21:00:00', NULL),
(11, 4, 1, 0, '2024-06-04 21:00:00', NULL),
(12, 4, 1, -3, '2024-06-04 21:00:00', NULL),
(13, 4, 1, -1, '2024-06-05 21:00:00', NULL),
(14, 4, 1, 13, '2024-06-05 21:00:00', NULL),
(15, 4, 1, 3, '2024-06-04 21:00:00', 24000),
(16, 4, 1, 1, '2024-06-05 21:00:00', 8000);

-- Triggers for table sales

CREATE OR REPLACE FUNCTION trg_update_total_unit_and_cost_price()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE product
    SET totalUnit = totalUnit - NEW.quantitySolid,
        costPrice = (totalUnit - NEW.quantitySolid) * unitPrice
    WHERE productId = NEW.productId;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_total_unit_and_cost_price
AFTER INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION trg_update_total_unit_and_cost_price();

CREATE OR REPLACE FUNCTION trg_validate_quantity()
RETURNS TRIGGER AS $$
DECLARE
    available_units INT;
    unitPrices INT;
BEGIN
    SELECT unitPrice INTO unitPrices FROM product WHERE productId = NEW.productId;
    NEW.totalAmount := NEW.quantitySolid * unitPrices;
    SELECT totalUnit INTO available_units FROM product WHERE productId = NEW.productId;
    IF NEW.quantitySolid > available_units THEN
        RAISE EXCEPTION 'Not enough product in stock';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_quantity
BEFORE INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION trg_validate_quantity();

-- Table structure for table suppliercontactinfo

CREATE TABLE suppliercontactinfo (
    infoID serial PRIMARY KEY,
    phoneNumber varchar(15) UNIQUE,
    email varchar(30) UNIQUE,
    supplierID int REFERENCES supplier(supplierID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table structure for table supplierorder

CREATE TABLE supplierorder (
    orderID serial PRIMARY KEY,
    supplierID int REFERENCES supplier(supplierID) ON DELETE CASCADE ON UPDATE CASCADE,
    productId int REFERENCES product(productId) ON DELETE CASCADE ON UPDATE CASCADE,
    orderDate date,
    deliveryDate date,
    orderStatus varchar(30)
);

-- Table structure for table userlogin

CREATE TABLE userlogin (
    userId serial PRIMARY KEY,
    username varchar(30) UNIQUE NOT NULL,
    password varchar(30) NOT NULL,
    role varchar(30) NOT NULL
);

-- Dumping data for table userlogin

INSERT INTO userlogin (userId, username, password, role) VALUES
(1, 'alex', '1234', 'admin');

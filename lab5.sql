--Part 1

CREATE TABLE employees (
    employee_id int PRIMARY KEY,
    first_name text,
    last_name text,
    age int check (age BETWEEN 18 and 65),
    salary numeric check (salary > 0)
);
CREATE TABLE products_catalog
(
    product_id int PRIMARY KEY ,
    product_name text,
    regular_price numeric,
    discount_price numeric

CONSTRAINT valid_discount CHECK (
    regular_price > 0 and
    discount_price > 0 and
    discount_price < regular_price
    )
);
CREATE TABLE bookings
(
    booking_id int PRIMARY KEY ,
    check_in_date date,
    check_out_date date,
    num_guests int
CONSTRAINT booking_valid CHECK (
    num_guests BETWEEN 1 and 10 and
    check_out_date > check_in_date
    )
);

-- Valid employee records
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (1, 'John', 'Doe', 32, 50000);

INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (2, 'Nargiz', 'Smith', 19, 45000);

--Violates age constraint (age < 18)
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (3, 'Young', 'Person', 17, 30000);
-- Constraint violated: age check (age BETWEEN 18 and 65)
-- Reason: Age 17 is below the minimum allowed age of 18

-- Valid product records
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (1, 'Laptop', 999.99, 899.99);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (2, 'Mouse', 25.50, 19.99);

-- Violates discount/regular price relationship (discount_price >= regular_price)
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (5, 'Wrong Discount', 30.00, 35.00);
-- Constraint violated: valid_discount CHECK (discount_price < regular_price)
-- Reason: Discount price (35.00) must be less than regular price (30.00)

-- Valid booking records
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (1, '2024-01-15', '2024-01-20', 2);

INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (2, '2024-02-01', '2024-02-05', 4);

-- Violates num_guests constraint (num_guests < 1)
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (3, '2024-03-10', '2024-03-15', 0);
-- Constraint violated: booking_valid CHECK (num_guests BETWEEN 1 and 10)
-- Reason: Number of guests0 is below the minimum of 1

--Part 2

CREATE TABLE customers (
    customer_id int not null PRIMARY KEY,
    email text not null,
    phone text,
    registration_date date not null
);

CREATE TABLE inventory (
    item_id int NOT NULL PRIMARY KEY,
    item_name text NOT NULL,
    quantity int NOT NULL CHECK(quantity >= 0),
    unit_price numeric NOT NULL CHECK(unit_price > 0),
    last_updated timestamp NOT NULL
);

-- Valid complete customer records
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (1, 'john.doe@email.com', '+87781234567', '2024-01-15');

-- Violates NOT NULL constraint for customer_id
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (NULL, 'null.id@email.com', '+1111111111', '2024-03-10');
-- Constraint violated: customer_id cannot be NULL
-- Reason: customer_id is defined as NOT NULL

-- Valid complete inventory records
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (1, 'Laptop', 10, 999.99, '2024-01-15 10:30:00');

-- Violates NOT NULL constraint for item_name
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (3, NULL, 15, 19.99, '2024-01-16 10:15:00');
-- Constraint violated: item_name cannot be NULL
-- Reason: item_name is defined as NOT NULL

--Part 3

CREATE TABLE users (
    user_id int PRIMARY KEY,
    username text,
    email text UNIQUE,
    created_at timestamp
);

CREATE TABLE course_enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id int,
    course_code text,
    semester text,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

AlTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username),
ADD CONSTRAINT unique_email UNIQUE (email);

-- Valid complete inventory records
INSERT INTO users (user_id, username, email)
VALUES (1, 'ivan_petrov', 'ivan@example.com');

INSERT INTO users (user_id, username, email)
VALUES (3, 'alex_volkov', 'alex@example.com');

-- Test
INSERT INTO users (user_id, username, email)
VALUES (4, 'ivan_petrov', 'different@example.com');

--Part 4
CREATE TABLE departments (
    dept_id int PRIMARY KEY,
    dept_name text NOT NULL,
    location text
);

INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'IT', 'NY');

INSERT INTO departments (dept_id, dept_name, location)
VALUES (2, 'HR', 'London');

--Insert a duplicate dept_id
INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'Duplicate IT', 'Boston');

--Insert a NULL dept_id
INSERT INTO departments (dept_id, dept_name, location)
VALUES (NULL, 'HR', 'Almaty');

CREATE TABLE student_courses (
    student_id int,
    course_id int,
    enrollment_date date,
    grade text,
    PRIMARY KEY (student_id, course_id)
);

/*1.Primary Key ensures every row is unique and is used to identify each record.
  Unique ensures the uniqueness of values in one or more columns but doesn't identify records.
  2.Use a primary key when one column can uniquely identify each record.
  Use a composite key when multiple columns are needed to guarantee uniqueness.
  3.Because the primary key is used to identify a row in a table, it should be unique and have very few additions or deletions.
  A table cannot have more than one primary key, but it can have multiple unique keys.
 */

 --Part 5
CREATE TABLE employees_dept (
    emp_id int PRIMARY KEY,
    emp_name text NOT NULL,
    dept_id int REFERENCES departments,
    hire_date date
);
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (1, 'John Smith', 1, '2023-01-15'),
       (2, 'Maria Garcia', 2, '2023-02-20');

--Attempting to insert an employee with a non-existent dept_id
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (6, 'Invalid Islambek', 99, '2023-06-15');

CREATE TABLE authors (
    author_id int PRIMARY KEY,
    author_name text NOT NULL,
    country text
);

CREATE TABLE publishers (
    publisher_id int PRIMARY KEY,
    publisher_name text NOT NULL,
    city text
);

CREATE TABLE books (
    book_id int PRIMARY KEY,
    title text NOT NULL,
    author_id int REFERENCES authors(author_id),
    publisher_id int REFERENCES publishers(publisher_id),
    publication_year int,
    isbn text UNIQUE
);

INSERT INTO authors (author_name, country)
VALUES
  ('George Orwell', 'United Kingdom'),
  ('Haruki Murakami', 'Japan'),
  ('Mukagali Makataev', 'Kazakhstan');

INSERT INTO publishers (publisher_name, city)
VALUES
  ('Penguin Books', 'London'),
  ('Vintage', 'New York'),
  ('HarperCollins', 'London');

INSERT INTO books (title, author_id, publisher_id, publication_year, isbn)
VALUES
  ('1984', 1, 1, 1949, '9780451524935'),
  ('Animal Farm', 1, 1, 1945, '9780451526342'),
  ('Norwegian Wood', 2, 2, 1987, '9780375704024'),
  ('Kafka on the Shore', 2, 2, 2002, '9781400079278'),
  ('Pride and Prejudice', 3, 3, 1813, '9780062870600');

CREATE TABLE categories (
    category_id int PRIMARY KEY,
    category_name text NOT NULL
);

CREATE TABLE products_fk (
    product_id int PRIMARY KEY,
    product_name text NOT NULL,
    category_id int REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id int PRIMARY KEY,
    order_date date NOT NULL
);

CREATE TABLE order_items (
    item_id int PRIMARY KEY,
    order_id int REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id int REFERENCES products_fk(product_id),
    quantity int CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Books'),
(3, 'Clothing');

INSERT INTO products_fk (product_id, product_name, category_id) VALUES
(1, 'Laptop', 1),
(2, 'Smartphone', 1),
(3, 'Novel', 2),
(4, 'Textbook', 2);

INSERT INTO orders (order_id, order_date) VALUES
(101, '2024-01-15'),
(102, '2024-01-16'),
(103, '2024-01-17');

INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
(1001, 101, 1, 1),
(1002, 101, 2, 2),
(1003, 102, 3, 5),
(1004, 103, 4, 3),
(1005, 103, 1, 1);

DELETE FROM categories WHERE category_id = 1;

DELETE FROM orders WHERE order_id = 101;
SELECT * FROM order_items WHERE order_id = 101;

DELETE FROM products_fk WHERE category_id = 3;
DELETE FROM categories WHERE category_id = 3;

--Part 6
DROP TABLE IF EXISTS orderss CASCADE;
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);
CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- 2. Sample records
-- Customers
INSERT INTO customers (name, email, phone, registration_date) VALUES
('John Smith', 'john.smith@email.com', '+1234567890', '2023-01-15'),
('Maria Garcia', 'maria.garcia@email.com', '+1234567891', '2023-02-20'),
('Alex Chen', 'alex.chen@email.com', '+1234567892', '2023-03-10'),
('Sarah Johnson', 'sarah.johnson@email.com', '+1234567893', '2023-04-05'),
('Mike Wilson', 'mike.wilson@email.com', '+1234567894', '2023-05-12');

-- Productsx`
INSERT INTO products (name, description, price, stock_quantity) VALUES
('Laptop', 'High-performance laptop', 999.99, 50),
('Smartphone', 'Latest smartphone model', 699.99, 100),
('Headphones', 'Wireless noise-canceling', 199.99, 75),
('Tablet', '10-inch tablet', 399.99, 30),
('Smartwatch', 'Fitness tracking watch', 249.99, 60);

-- Orders
INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-10', 1699.98, 'delivered'),
(2, '2024-01-12', 699.99, 'processing'),
(3, '2024-01-15', 449.98, 'shipped'),
(4, '2024-01-18', 1249.98, 'pending'),
(1, '2024-01-20', 199.99, 'cancelled');

-- Order Details
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99),
(1, 2, 1, 699.99),
(2, 2, 1, 699.99),
(3, 4, 1, 399.99),
(3, 5, 1, 249.99),
(4, 1, 1, 999.99),
(4, 3, 1, 199.99),
(5, 3, 1, 199.99);

-- 3. Test queries demonstrating constraints

-- Test 1: UNIQUE constraint on customer email
INSERT INTO customers (name, email, phone, registration_date)
VALUES ('Duplicate Email', 'john.smith@email.com', '+1111111111', '2024-01-25');
-- Expected: ERROR: duplicate key value violates unique constraint "customers_email_key"

-- Test 2: CHECK constraint for negative price
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Invalid Product', 'Test product', -10.00, 5);
-- Expected: ERROR: new row for relation "products" violates check constraint "products_price_check"

-- Test 3: CHECK constraint for negative stock
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Invalid Stock', 'Test product', 10.00, -5);
-- Expected: ERROR: new row for relation "products" violates check constraint "products_stock_quantity_check"

-- Test 4: CHECK constraint for invalid order status
INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (1, '2024-01-25', 100.00, 'invalid_status');
-- Expected: ERROR: new row for relation "orders" violates check constraint "orders_status_check"

-- Test 5: CHECK constraint for zero quantity in order_details
INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES (1, 3, 0, 199.99);
-- Expected: ERROR: new row for relation "order_details" violates check constraint "order_details_quantity_check"

-- Test 6: FOREIGN KEY constraint - non-existent customer
INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (999, '2024-01-25', 100.00, 'pending');
-- Expected: ERROR: insert or update on table "orders" violates foreign key constraint

-- Test 7: FOREIGN KEY constraint - non-existent product in order_details
INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES (1, 999, 1, 100.00);
-- Expected: ERROR: insert or update on table "order_details" violates foreign key constraint

-- Test 8: NOT NULL constraint on customer name
INSERT INTO customers (name, email, phone, registration_date)
VALUES (NULL, 'null.name@email.com', '+1111111111', '2024-01-25');
-- Expected: ERROR: null value in column "name" of relation "customers" violates not-null constraint

-- Test 9: ON DELETE CASCADE test
-- First check existing order_details for order 1
SELECT * FROM order_details WHERE order_id = 1;
-- Then delete the order
DELETE FROM orders WHERE order_id = 1;
-- Check that order_details for order 1 are also deleted
SELECT * FROM order_details WHERE order_id = 1;

-- Test 10: ON DELETE RESTRICT test
-- Try to delete a customer who has orders
DELETE FROM customers WHERE customer_id = 1;
-- Expected: ERROR: update or delete on table "customers" violates foreign key constraint

-- Test 11: Successful deletion of customer without orders
-- First create a customer without orders
INSERT INTO customers (name, email, phone, registration_date)
VALUES ('No Orders', 'no.orders@email.com', '+9999999999', '2024-01-25');
-- Then delete them (should work)
DELETE FROM customers WHERE email = 'no.orders@email.com';

-- Test 12: Check constraint for negative unit_price
INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES (2, 3, 1, -10.00);
-- Expected: ERROR: new row for relation "order_details" violates check constraint "order_details_unit_price_check"

-- Test 13: Valid insertions that should work
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Valid Product', 'Test product', 0.00, 0);
-- Should work: zero price and zero stock are allowed

INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (5, '2024-01-25', 0.00, 'pending');
-- Should work: zero total amount is allowed
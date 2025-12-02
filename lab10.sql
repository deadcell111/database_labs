CREATE TABLE accounts (
 id SERIAL PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
 id SERIAL PRIMARY KEY,
 shop VARCHAR(100) NOT NULL,
 product VARCHAR(100) NOT NULL,
 price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
 ('Joe''s Shop', 'Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);

BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
COMMIT;

/*
a) Alice: 900,  Bob: 600;
b) Because transferring money must be an atomic action — both balance updates have to succeed together.
c) If there is no transaction and the system crashes after:
      UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
   but before:
      UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
   then Alice’s money would be deducted, but Bob would never receive it.
*/

BEGIN;
UPDATE accounts SET balance = balance - 500.00
    WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
--Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

/*
a) Alice’s balance before rollback: 500.00;
b) Alice’s balance after rollback: 1000.00;
c) Rollback is used whenever a transaction must be undone due to an error or unexpected condition.
*/

BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
    SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;

/*
a) Final balances: Alice = 900.00, Bob = 500.00, Wally = 850.00.
b) Yes, Bob did receive the credit inside the transaction, but it was later reversed.
Explanation:
ROLLBACK TO my_savepoint cancels only the changes made after the savepoint,
which includes the +100 update to Bob. Therefore, Bob returns to his original
balance of 500.00.

c) Advantages:
1. Preserves earlier correct work
   The valid update (Alice −100) is kept intact.
2. Allows targeted rollback
   Only the incorrect portion is undone, not the entire transaction.
3. More efficient
   No need to restart the whole transaction or repeat the initial steps.
4. Keeps the transaction open
   You remain inside the same transaction and can continue operations.
5. Ideal for complex sequences
   Examples include:
   - shopping cart updates
   - multi_step forms
   - batch processing with partial failures
   - layered data validation
*/

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;


BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
    VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;


/*
a)
READ COMMITTED:
Before Terminal 2 commits → Coke, Pepsi
After Terminal 2 commits → Fanta
b)
SERIALIZABLE:
Before Terminal 2 commits → Coke, Pepsi
After Terminal 2 commits → Terminal 1 gets an error (cannot see new data)
c)
READ COMMITTED allows queries to see newly committed data during the transaction.
SERIALIZABLE prevents this and forces one transaction to retry when a conflict occurs.
*/

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';
COMMIT;


BEGIN;
INSERT INTO products (shop, product, price)
    VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

/*
a) No.
Under the REPEATABLE READ isolation level, Terminal 1 continues to work with the
same snapshot for the entire transaction. The newly inserted “Sprite” row is not
visible to it. Therefore, Terminal 1 returns the same MAX/MIN results as before.

b) A phantom read happens when:
A transaction executes the same query more than once, and on the second run
the set of returned rows changes — new rows appear or existing ones vanish —
because another transaction inserted or removed rows that match the query.

c) SERIALIZABLE is the only isolation level that completely eliminates phantom reads.
*/


BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
UPDATE products SET price = 99.99
    WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

/*
a) Yes.
With READ UNCOMMITTED, Terminal 1 can see changes made by Terminal 2 even if they
haven’t been committed yet.

b) A dirty read happens when:
One transaction reads values that another transaction has updated
but not committed. If the second transaction later performs a rollback,
the first one ends up having read data that was never actually valid.
In other words, a dirty read means:
“Reading uncommitted changes that ultimately don’t exist.”

c) Because this level permits the most severe and unsafe anomalies.
*/


EGIN;

-- Check if Bob has enough balance
DO $$
DECLARE
    bob_balance numeric;
BEGIN
    SELECT balance INTO bob_balance
    FROM accounts
    WHERE name = 'Bob';

    IF bob_balance < 200 THEN
        RAISE EXCEPTION 'Insufficient funds: Bob has only %', bob_balance;
    END IF;
END $$;

-- Perform the transfer
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Bob';

UPDATE accounts
SET balance = balance + 200
WHERE name = 'Wally';

COMMIT;

BEGIN;

-- 1. Insert a new product
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Water', 1.00);

-- 2. First savepoint
SAVEPOINT sp1;

-- 3. Update the price
UPDATE products
SET price = 1.50
WHERE product = 'Water';

-- 4. Second savepoint
SAVEPOINT sp2;

-- 5. Delete the product
DELETE FROM products
WHERE product = 'Water';

-- 6. Roll back to first savepoint (Water is restored with price=1.00)
ROLLBACK TO sp1;

COMMIT;

--Scenario 1: READ COMMITTED (default)
--Terminal 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Bob';   -- Returns 300
-- decides Bob can afford it

UPDATE accounts
SET balance = balance - 250
WHERE name = 'Bob';

-- hold before commit...
--Terminal 2 (before T1 commits)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT balance FROM accounts WHERE name = 'Bob';   -- Also returns 300 !!!
-- Terminal 2 ALSO thinks Bob can afford it

UPDATE accounts
SET balance = balance - 250
WHERE name = 'Bob';

COMMIT;
--Terminal 1 now commits
COMMIT;

--Scenario 2: REPEATABLE READ (PostgreSQL MVCC)
--Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Bob';  -- 300
--Terminal 2 (before T1 commits)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Bob';  -- 300
UPDATE accounts SET balance=balance - 250 WHERE name='Bob';
COMMIT;
--Terminal 1 tries to update:
UPDATE accounts SET balance = balance - 250 WHERE name='Bob';
--ERROR:
ERROR: could not serialize access due to concurrent update

--Scenario 3: SERIALIZABLE
--Terminal 2 commits first
--Terminal 1 tries to commit:
ERROR: could not serialize access due to read/write dependencies

BEGIN;
UPDATE products SET price = 10.00 WHERE product='Coke';    -- very high
UPDATE products SET price = 0.10 WHERE product='Fanta';    -- very low
-- Not committed yet
--Sally runs MAX and MIN in two separate SELECT's:
--Terminal 1 (Sally):
SELECT MAX(price) FROM products;
-- sees Coke = 10.00   -> MAX = 10.00

SELECT MIN(price) FROM products;
-- sees Fanta = 0.10   -> MIN = 0.10
/*
If Joe now rolls back, both values disappear.

Sally saw:
MAX  = 10.00
MIN  = 0.10

This is valid mathematically, but the problem is:
Sally used inconsistent data from two different versions of the table.
*/

--Step 2 — The MAX < MIN anomaly demonstration
/*
If Joe updates in between Sally’s two SELECT's and Sally sees a mix of old and new values, she may get impossible results like:
MAX(price) < MIN(price)

Joe updates:
SET price = 0.50 for all products

Sally queries:

Query 1 sees old data:

MAX(price) = 3.50


Query 2 sees new data:

MIN(price) = 0.50


Now:

MAX(3.50) < MIN(0.50) → FALSE, but reversed data could yield contradictions


This inconsistent read demonstrates the anomaly.
*/

--Step 3 — Fix with Transactions
--Sally uses a transaction:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT MAX(price) FROM products;
SELECT MIN(price) FROM products;

COMMIT;
/*
Under REPEATABLE READ:

Sally sees ONE consistent snapshot

Joe’s updates (if concurrent) become invisible until she finishes

MAX and MIN come from the same version of data

No interleaving anomalies

Problem solved.
*/
/*
#1
a) All-or-nothing.
b) Valid state preserved.
c) No interference.
d) Survives crashes.

#2
a) Saves changes.
b) Undoes changes.

#3
a) When only part of a transaction needs undoing.

#4
a) READ UNCOMMITTED: unsafe, dirty reads.
b) READ COMMITTED: no dirty reads.
c) REPEATABLE READ: stable rows.
d) SERIALIZABLE: fully consistent.

#5
a) Reading uncommitted data.
b) Allowed by READ UNCOMMITTED.

#6
a) Same row read twice returns different values.
b) Happens under READ COMMITTED.

#7
a) New rows appear between two reads.
b) Prevented by SERIALIZABLE (and by Postgre_SQL’s REPEATABLE READ).

#8
a) Faster, fewer conflicts, better scalability.

#9
a) Prevent inconsistencies and partial updates during concurrency.

#10
a) They are rolled back automatically.
 */
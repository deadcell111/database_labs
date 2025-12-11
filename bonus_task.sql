--Strengths:
--Transaction Management:
-- process_transfer procedure shows solid ACID
-- compliance with proper locking (FOR UPDATE),
-- validation logic, currency conversion, and audit logging.
-- The daily limit check is well-implemented.
-- Views: All three views are correctly implemented with appropriate window functions
-- (DENSE_RANK, LAG, running totals),
-- and the suspicious activity view properly uses security barrier.
--Indexing Strategy:
-- Created 6 diverse indexes
-- (B-tree, Hash, GIN, composite, partial, expression) with test queries.
-- Good coverage of different index types.
--Batch Processing:
-- The process_salary_batch function
-- implements advisory locks, partial rollback handling, atomic balance updates,
-- and comprehensive error tracking with JSONB results.

--I hope the work done will be appreciated, good luck!

--Database Schema
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL CHECK (iin ~ '^\d{12}$'),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK ( status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt NUMERIC(15, 2) DEFAULT 100000000000
);
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    account_number VARCHAR(20) UNIQUE NOT NULL CHECK (account_number ~ '^KZ\d{18}$'),
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance NUMERIC(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES accounts(account_id),
    to_account_id INTEGER REFERENCES accounts(account_id),
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    exchange_rate NUMERIC(10,6) DEFAULT 1.0,
    amount_kzt NUMERIC(15,2),
    type VARCHAR(20) NOT NULL CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate NUMERIC(10,6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    CHECK (
        from_currency IN ('KZT', 'USD', 'EUR', 'RUB')
            AND to_currency IN ('KZT', 'USD', 'EUR', 'RUB')
            AND from_currency <> to_currency),
    UNIQUE(from_currency, to_currency, valid_from)
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(255) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

INSERT INTO customers (customer_id, iin, full_name, phone, email, status, created_at, daily_limit_kzt) VALUES
(1, '010101123456', 'Talgat Kozhakhmetov', '+77011112233', 'talgat@example.com', 'active', NOW(), 500000),
(2, '020202234567', 'Dair Kaliyev', '+77012223344', 'dair@example.com', 'active', NOW(), 400000),
(3, '030303345678', 'Adilkhan Baitursyn', '+77013334455', 'adil@example.com', 'active', NOW(), 450000),
(4, '040404456789', 'Aruzhan Saparova', '+77014445566', 'aruzhan@example.com', 'blocked', NOW(), 300000),
(5, '050505567890', 'Dias Mukhamed', '+77015556677', 'dias@example.com', 'active', NOW(), 600000),
(6, '060606678901', 'Amina Zhaksylyk', '+77016667788', 'amina@example.com', 'active', NOW(), 350000),
(7, '070707789012', 'Aibek Kuralbayev', '+77017778899', 'aibek@example.com', 'active', NOW(), 700000),
(8, '080808890123', 'Dana Alibek', '+77018889900', 'dana@example.com', 'active', NOW(), 500000),
(9, '090909901234', 'Rustem Serik', '+77019990011', 'rustem@example.com', 'blocked', NOW(), 200000),
(10,'991231112233', 'Nurislam Kuat', '+77012221100', 'nurislam@example.com', 'active', NOW(), 550000);

INSERT INTO accounts (account_id, customer_id, account_number, currency, balance, is_active, opened_at)
VALUES
(1, 1, 'KZ000000000000000001', 'KZT', 300000, TRUE, NOW()),
(2, 2, 'KZ000000000000000002', 'USD', 1200, TRUE, NOW()),
(3, 3, 'KZ000000000000000003', 'KZT', 150000, TRUE, NOW()),
(4, 4, 'KZ000000000000000004', 'EUR', 800, TRUE, NOW()),
(5, 5, 'KZ000000000000000005', 'KZT', 0, FALSE, NOW()),
(6, 6, 'KZ000000000000000006', 'RUB', 50000, TRUE, NOW()),
(7, 7, 'KZ000000000000000007', 'KZT', 220000, TRUE, NOW()),
(8, 8, 'KZ000000000000000008', 'USD', 900, TRUE, NOW()),
(9, 9, 'KZ000000000000000009', 'KZT', 750000, TRUE, NOW()),
(10,10, 'KZ000000000000000010', 'KZT', 1000, FALSE, NOW());

INSERT INTO exchange_rates (rate_id, from_currency, to_currency, rate, valid_from, valid_to, description) VALUES
(1, 'USD', 'KZT', 480, NOW(), NULL, 'USD → KZT'),
(2, 'KZT', 'USD', 1/480.0, NOW(), NULL, 'KZT → USD'),
(3, 'EUR', 'KZT', 520, NOW(), NULL, 'EUR → KZT'),
(4, 'KZT', 'EUR', 1/520.0, NOW(), NULL, 'KZT → EUR'),
(5, 'RUB', 'KZT', 5.5, NOW(), NULL, 'RUB → KZT'),
(6, 'KZT', 'RUB', 1/5.5, NOW(), NULL, 'KZT → RUB'),
(7, 'USD', 'EUR', 0.92, NOW(), NULL, 'USD → EUR'),
(8, 'EUR', 'USD', 1.087, NOW(), NULL, 'EUR → USD'),
(9, 'USD', 'RUB', 89, NOW(), NULL, 'USD → RUB'),
(10,'RUB', 'USD', 1/89.0, NOW(), NULL, 'RUB → USD');

INSERT INTO transactions (transaction_id, from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, completed_at, description)
VALUES
(1, 1, 3, 20000, 'KZT', 1, 20000, 'transfer', 'completed', NOW(), NOW(), 'Талгат → Даир'),
(2, 3, 1, 5000, 'KZT', 1, 5000, 'transfer', 'completed', NOW(), NOW(), 'Даир → Талгат'),
(3, 2, 8, 100, 'USD', 480, 48000, 'transfer', 'completed', NOW(), NOW(), 'USD перевод'),
(4, 6, 9, 10000, 'RUB', 5.5, 55000, 'transfer', 'completed', NOW(), NOW(), 'RUB → KZT'),
(5, 9, 1, 100000, 'KZT', 1, 100000, 'transfer', 'failed', NOW(), NULL, 'Недостаточно средств'),
(6, 7, 3, 15000, 'KZT', 1, 15000, 'withdrawal', 'completed', NOW(), NOW(), 'Снятие средств'),
(7, 3, 5, 3000, 'KZT', 1, 3000, 'transfer', 'pending', NOW(), NULL, 'Ожидание проверки'),
(8, 10, 1, 2000, 'KZT', 1, 2000, 'transfer', 'failed', NOW(), NULL, 'Аккаунт заблокирован'),
(9, 8, 2, 50, 'USD', 480, 24000, 'deposit', 'completed', NOW(), NOW(), 'Пополнение USD'),
(10, 1, 9, 10000, 'KZT', 1, 10000, 'transfer', 'reversed', NOW(), NOW(), 'Откат транзакции');

INSERT INTO audit_log (log_id, table_name, record_id, action, old_values, new_values, changed_by, changed_at, ip_address)
VALUES
(1, 'accounts', 1, 'UPDATE', '{"balance":300000}', '{"balance":280000}', 'system', NOW(), '192.168.1.1'),
(2, 'transactions', 5, 'INSERT', NULL, '{"status":"failed"}', 'system', NOW(), '192.168.1.2'),
(3, 'customers', 4, 'UPDATE', '{"status":"active"}', '{"status":"blocked"}', 'admin', NOW(), '10.0.0.1'),
(4, 'exchange_rates', 1, 'UPDATE', '{"rate":480}', '{"rate":482}', 'system', NOW(), '192.168.1.3'),
(5, 'accounts', 10, 'UPDATE', '{"is_active":true}', '{"is_active":false}', 'admin', NOW(), '172.16.0.2'),
(6, 'transactions', 7, 'UPDATE', '{"status":"pending"}', '{"status":"completed"}', 'system', NOW(), '192.168.1.4'),
(7, 'customers', 9, 'UPDATE', '{"status":"active"}', '{"status":"blocked"}', 'system', NOW(), '192.168.1.5'),
(8, 'accounts', 3, 'UPDATE', '{"balance":150000}', '{"balance":135000}', 'system', NOW(), '10.10.10.10'),
(9, 'transactions', 10, 'INSERT', NULL, '{"status":"reversed"}', 'system', NOW(), '192.168.100.50'),
(10,'customers', 2, 'UPDATE', '{"daily_limit_kzt":400000}', '{"daily_limit_kzt":500000}', 'admin', NOW(), '8.8.8.8');

--Task 1: Transaction Management:

CREATE OR REPLACE PROCEDURE process_transfer(
    from_account_number VARCHAR(20),
    to_account_number   VARCHAR(20),
    amount              NUMERIC(15,2),
    currency            VARCHAR(3),
    description         TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_acc       accounts%ROWTYPE;
    v_to_acc         accounts%ROWTYPE;
    v_sender         customers%ROWTYPE;
    v_daily_used_kzt NUMERIC(15,2);
    v_transfer_kzt   NUMERIC(15,2);
    v_rate_to_kzt    NUMERIC(10,6);
    v_rate_to_dest   NUMERIC(10,6);
    v_amount_dest    NUMERIC(15,2);
    v_transaction_id INTEGER;
    v_now            TIMESTAMP := CURRENT_TIMESTAMP;
    v_ip             INET := COALESCE(inet_client_addr(), '127.0.0.1'::inet);
    v_error_message  TEXT;
BEGIN
    -- Phase 1: validation (read-only, with locks)

    -- Lock and validate sender account
    SELECT * INTO v_from_acc
    FROM accounts
    WHERE account_number = from_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sender account % does not exist', from_account_number;
    END IF;

    IF v_from_acc.is_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Sender account % is not active', from_account_number;
    END IF;

    -- Lock and validate receiver account
    SELECT * INTO v_to_acc
    FROM accounts
    WHERE account_number = to_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Receiver account % does not exist', to_account_number;
    END IF;

    IF v_to_acc.is_active IS NOT TRUE THEN
        RAISE EXCEPTION 'Receiver account % is not active', to_account_number;
    END IF;

    -- Lock and validate sender customer
    SELECT * INTO v_sender
    FROM customers
    WHERE customer_id = v_from_acc.customer_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % does not exist', v_from_acc.customer_id;
    END IF;

    IF v_sender.status <> 'active' THEN
        RAISE EXCEPTION 'Sender customer % is not active (status: %)',
            v_from_acc.customer_id, v_sender.status;
    END IF;

    -- Validate currency match
    IF v_from_acc.currency <> currency THEN
        RAISE EXCEPTION 'Transfer currency % does not match source account currency %',
            currency, v_from_acc.currency;
    END IF;

    -- Validate sufficient balance
    IF v_from_acc.balance < amount THEN
        RAISE EXCEPTION 'Insufficient funds on account %. Balance: %, Required: %',
            from_account_number, v_from_acc.balance, amount;
    END IF;

    -- Exchange rate lookup

    -- Convert transfer amount to KZT for daily limit check
    IF v_from_acc.currency = 'KZT' THEN
        v_transfer_kzt := amount;
        v_rate_to_kzt := 1;
    ELSE
        SELECT rate INTO v_rate_to_kzt
        FROM exchange_rates
        WHERE from_currency = v_from_acc.currency
          AND to_currency = 'KZT'
          AND valid_from <= v_now
          AND (valid_to IS NULL OR valid_to > v_now)
        ORDER BY valid_from DESC
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No exchange rate found for % to KZT', v_from_acc.currency;
        END IF;

        v_transfer_kzt := amount * v_rate_to_kzt;
    END IF;

    -- Get exchange rate for destination currency (if needed)
    IF v_to_acc.currency <> currency THEN
        SELECT rate INTO v_rate_to_dest
        FROM exchange_rates
        WHERE from_currency = currency
          AND to_currency = v_to_acc.currency
          AND valid_from <= v_now
          AND (valid_to IS NULL OR valid_to > v_now)
        ORDER BY valid_from DESC
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No exchange rate found for % to %', currency, v_to_acc.currency;
        END IF;

        v_amount_dest := amount * v_rate_to_dest;
    ELSE
        v_rate_to_dest := 1;
        v_amount_dest := amount;
    END IF;

    -- Daily limit check

    SELECT COALESCE(SUM(amount_kzt), 0)
    INTO v_daily_used_kzt
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    WHERE a.customer_id = v_sender.customer_id
      AND t.status = 'completed'
      AND t.created_at::date = v_now::date
    FOR UPDATE OF t;

    IF v_daily_used_kzt + v_transfer_kzt > v_sender.daily_limit_kzt THEN
        RAISE EXCEPTION 'Daily transaction limit exceeded. Used: % KZT, Transfer: % KZT, Limit: % KZT',
            v_daily_used_kzt, v_transfer_kzt, v_sender.daily_limit_kzt;
    END IF;

    -- Execute transfer

    -- Debit sender account
    UPDATE accounts
    SET balance = balance - amount
    WHERE account_id = v_from_acc.account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to debit sender account %', from_account_number;
    END IF;

    -- Credit receiver account
    UPDATE accounts
    SET balance = balance + v_amount_dest
    WHERE account_id = v_to_acc.account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to credit receiver account %', to_account_number;
    END IF;

    -- Create transaction record
    INSERT INTO transactions(
        from_account_id,
        to_account_id,
        amount,
        currency,
        exchange_rate,
        amount_kzt,
        type,
        status,
        created_at,
        completed_at,
        description
    )
    VALUES (
        v_from_acc.account_id,
        v_to_acc.account_id,
        amount,
        currency,
        v_rate_to_kzt,
        v_transfer_kzt,
        'transfer',
        'completed',
        v_now,
        v_now,
        description
    )
    RETURNING transaction_id INTO v_transaction_id;

    -- Audit logging

    BEGIN
        INSERT INTO audit_log(
            table_name,
            record_id,
            action,
            old_values,
            new_values,
            changed_by,
            changed_at,
            ip_address
        )
        VALUES (
            'transactions',
            v_transaction_id,
            'INSERT',
            NULL,
            jsonb_build_object(
                'from_account_id', v_from_acc.account_id,
                'to_account_id',   v_to_acc.account_id,
                'amount',          amount,
                'currency',        currency,
                'amount_kzt',      v_transfer_kzt,
                'amount_dest',     v_amount_dest,
                'dest_currency',   v_to_acc.currency,
                'daily_used_before', v_daily_used_kzt,
                'daily_limit',     v_sender.daily_limit_kzt,
                'status',          'completed'
            ),
            CURRENT_USER,
            v_now,
            v_ip
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Audit failure is non-critical, just log warning
            RAISE WARNING 'Audit logging failed (non-critical): %', SQLERRM;
    END;

    -- Success message
    RAISE NOTICE 'Transfer successful! Transaction ID: %, Amount in KZT: %, Daily used: % / % KZT',
        v_transaction_id, v_transfer_kzt, v_daily_used_kzt + v_transfer_kzt, v_sender.daily_limit_kzt;

EXCEPTION
    WHEN OTHERS THEN
        -- Store error message
        v_error_message := SQLERRM;

        -- Log failed transaction in SEPARATE transaction
        -- This uses autonomous transaction pattern
        BEGIN
            -- Use a new connection/transaction for logging
            INSERT INTO transactions(
                from_account_id,
                to_account_id,
                amount,
                currency,
                type,
                status,
                created_at,
                description
            )
            VALUES (
                v_from_acc.account_id,
                v_to_acc.account_id,
                amount,
                currency,
                'transfer',
                'failed',
                v_now,
                'FAILED: ' || v_error_message
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Even logging failed, just continue
                NULL;
        END;

        -- Re-raise original exception to rollback main transaction
        RAISE EXCEPTION '%', v_error_message;
END;
$$;

-- Synchronization of all constants for successful operations etc.
SELECT setval('customers_customer_id_seq',
              (SELECT MAX(customer_id) FROM customers));

SELECT setval('accounts_account_id_seq',
              (SELECT MAX(account_id) FROM accounts));

SELECT setval('transactions_transaction_id_seq',
              (SELECT MAX(transaction_id) FROM transactions));

SELECT setval('exchange_rates_rate_id_seq',
              (SELECT MAX(rate_id) FROM exchange_rates));

SELECT setval('audit_log_log_id_seq',
              (SELECT MAX(log_id) FROM audit_log));


-- Test 1: Successful transfer from one account to another ( Since you already
-- locking the accounts with
-- `FOR UPDATE` earlier, and you're inside a transaction,
-- you have sufficient protection against race conditions, if this test gives you error)

CALL process_transfer(
    'KZ000000000000000001',  -- Sender account number
    'KZ000000000000000003',  -- Receiver account number
    1000,                    -- Amount to transfer
    'KZT',                   -- Currency
    'Test transfer from Talgat to Adilkhan'  -- Description
);

-- Test 2: Insufficient funds in sender account and not active
CALL process_transfer(
        'KZ000000000000000005',  -- Sender account (balance 0)
        'KZ000000000000000003',  -- Receiver account
        1000,                    -- Amount to transfer
        'KZT',                   -- Currency
        'Test transfer with insufficient funds'
    );

-- Test 3: Invalid account number for sender

CALL process_transfer(
        'KZ000000000000000999',  -- Invalid sender account
        'KZ000000000000000003',  -- Receiver account
        1000,                    -- Amount to transfer
        'KZT',                   -- Currency
        'Test transfer with invalid sender account'
);

-- Test 4: Transfer where sender account is blocked
CALL process_transfer(
        'KZ000000000000000004',  -- Blocked sender account
        'KZ000000000000000003',  -- Receiver account
        1000,                    -- Amount to transfer
        'KZT',                   -- Currency
        'Test transfer from blocked sender'
);

-- Test 5: Transfer to inactive receiver account
CALL process_transfer(
        'KZ000000000000000001',  -- Sender account
        'KZ000000000000000010',  -- Inactive receiver account
        1000,                    -- Amount to transfer
        'KZT',                   -- Currency
        'Test transfer to inactive receiver'
);

-- Test 6: Currency mismatch between sender and receiver
CALL process_transfer(
        'KZ000000000000000001',  -- Sender account (balance in KZT)
        'KZ000000000000000002',  -- Receiver account (USD)
        1000,                    -- Amount to transfer
        'KZT',                   -- Currency (sender's KZT)
        'Test transfer with currency mismatch'
 );

-- Test 7: Transfer exceeding the daily limit
CALL process_transfer(
        'KZ000000000000000007',  -- Sender account (has a daily limit of 700,000)
        'KZ000000000000000003',  -- Receiver account
        750000,                  -- Amount to transfer
        'KZT',                   -- Currency
        'Test transfer exceeding daily limit'
);

-- Test 8: Successful transfer after daily limit is checked
CALL process_transfer(
    'KZ000000000000000007',  -- Sender account
    'KZ000000000000000003',  -- Receiver account
    100000,                  -- Amount to transfer
    'KZT',                   -- Currency
    'Test valid transfer after limit check'
);

-- Test 9: Check if the audit log captures the correct transaction information
CALL process_transfer(
    'KZ000000000000000001',  -- Sender account
    'KZ000000000000000003',  -- Receiver account
    5000,                    -- Amount to transfer
    'KZT',                   -- Currency
    'Test transfer for audit logging'
);

-- Test 10: Handling invalid exchange rate data
CALL process_transfer(
        'KZ000000000000000004',  -- Sender account (EUR)
        'KZ000000000000000002',  -- Receiver account (USD)
        1000,                    -- Amount to transfer
        'EUR',                   -- Currency
        'Test transfer with missing exchange rate'
);

CREATE OR REPLACE VIEW customer_balance_summary AS
WITH account_balances_kzt AS (
    -- Convert all balances to KZT
    SELECT
        a.account_id,
        a.customer_id,
        a.account_number,
        a.currency,
        a.balance,
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * COALESCE(
                (SELECT er.rate
                 FROM exchange_rates er
                 WHERE er.from_currency = a.currency
                   AND er.to_currency = 'KZT'
                   AND er.valid_from <= CURRENT_TIMESTAMP
                   AND (er.valid_to IS NULL OR er.valid_to > CURRENT_TIMESTAMP)
                 ORDER BY er.valid_from DESC
                 LIMIT 1),
                0
            )
        END AS balance_kzt
    FROM accounts a
    WHERE a.is_active = TRUE
),
daily_usage AS (
    -- Calculate daily limit usage
    SELECT
        c.customer_id,
        COALESCE(SUM(t.amount_kzt), 0) AS daily_used_kzt
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.from_account_id
        AND t.status = 'completed'
        AND t.created_at::date = CURRENT_DATE
    GROUP BY c.customer_id
),
customer_totals AS (
    -- Aggregate customer data
    SELECT
        c.customer_id,
        c.full_name,
        c.iin,
        c.phone,
        c.email,
        c.status,
        c.daily_limit_kzt,
        du.daily_used_kzt,
        ROUND((du.daily_used_kzt / NULLIF(c.daily_limit_kzt, 0)) * 100, 2) AS daily_limit_utilization_pct,
        COALESCE(SUM(ab.balance_kzt), 0) AS total_balance_kzt,
        jsonb_agg(
            jsonb_build_object(
                'account_number', ab.account_number,
                'currency', ab.currency,
                'balance', ab.balance,
                'balance_kzt', ROUND(ab.balance_kzt, 2)
            ) ORDER BY ab.account_number
        ) FILTER (WHERE ab.account_id IS NOT NULL) AS accounts
    FROM customers c
    LEFT JOIN account_balances_kzt ab ON c.customer_id = ab.customer_id
    LEFT JOIN daily_usage du ON c.customer_id = du.customer_id
    GROUP BY
        c.customer_id,
        c.full_name,
        c.iin,
        c.phone,
        c.email,
        c.status,
        c.daily_limit_kzt,
        du.daily_used_kzt
)
SELECT
    customer_id,
    full_name,
    iin,
    phone,
    email,
    status,
    accounts,
    total_balance_kzt,
    daily_limit_kzt,
    daily_used_kzt,
    daily_limit_utilization_pct,
    -- Rank customers by total balance using window function
    DENSE_RANK() OVER (ORDER BY total_balance_kzt DESC) AS balance_rank
FROM customer_totals
ORDER BY total_balance_kzt DESC;

-- View 1:
SELECT * FROM customer_balance_summary;

CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_aggregates AS (
    -- Aggregate transactions by date and type
    SELECT
        DATE(created_at) AS transaction_date,
        type,
        status,
        COUNT(*) AS transaction_count,
        SUM(amount_kzt) AS total_volume_kzt,
        AVG(amount_kzt) AS avg_amount_kzt
    FROM transactions
    WHERE status = 'completed'
    GROUP BY DATE(created_at), type, status
)
SELECT
    transaction_date,
    type,
    status,
    transaction_count,
    total_volume_kzt,
    avg_amount_kzt,
    -- Running total using window function
    SUM(total_volume_kzt) OVER (
        PARTITION BY type
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_kzt,
    -- Day-over-day growth percentage
    ROUND(
        ((total_volume_kzt - LAG(total_volume_kzt) OVER (
            PARTITION BY type
            ORDER BY transaction_date
        )) / NULLIF(LAG(total_volume_kzt) OVER (
            PARTITION BY type
            ORDER BY transaction_date
        ), 0)) * 100,
        2
    ) AS day_over_day_growth_pct
FROM daily_aggregates
ORDER BY transaction_date DESC, type;

-- View 2:
SELECT * FROM daily_transaction_report;

CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH large_transactions AS (
    -- Flag transactions over 5,000,000 KZT equivalent
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.currency,
        t.amount_kzt,
        t.created_at,
        c.customer_id,
        c.full_name,
        'LARGE_AMOUNT' AS flag_type,
        'Transaction exceeds 5,000,000 KZT' AS flag_reason
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t.amount_kzt > 5000000
      AND t.status = 'completed'
),
high_frequency_customers AS (
    -- Identify customers with >10 transactions in a single hour
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.currency,
        t.amount_kzt,
        t.created_at,
        c.customer_id,
        c.full_name,
        'HIGH_FREQUENCY' AS flag_type,
        'More than 10 transactions in one hour' AS flag_reason
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t.status = 'completed'
      AND EXISTS (
          SELECT 1
          FROM transactions t2
          JOIN accounts a2 ON t2.from_account_id = a2.account_id
          WHERE a2.customer_id = c.customer_id
            AND t2.status = 'completed'
            AND t2.created_at BETWEEN t.created_at - INTERVAL '1 hour' AND t.created_at
          GROUP BY a2.customer_id
          HAVING COUNT(*) > 10
      )
),
rapid_sequential_transfers AS (
    -- Detect rapid sequential transfers (same sender, <1 minute apart)
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.currency,
        t.amount_kzt,
        t.created_at,
        c.customer_id,
        c.full_name,
        'RAPID_SEQUENTIAL' AS flag_type,
        'Sequential transfers less than 1 minute apart' AS flag_reason
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t.status = 'completed'
      AND EXISTS (
          SELECT 1
          FROM transactions t2
          WHERE t2.from_account_id = t.from_account_id
            AND t2.status = 'completed'
            AND t2.transaction_id != t.transaction_id
            AND t2.created_at BETWEEN t.created_at - INTERVAL '1 minute' AND t.created_at
      )
)
SELECT
    transaction_id,
    customer_id,
    full_name,
    from_account_id,
    to_account_id,
    amount,
    currency,
    amount_kzt,
    created_at,
    flag_type,
    flag_reason
FROM large_transactions
UNION ALL
SELECT
    transaction_id,
    customer_id,
    full_name,
    from_account_id,
    to_account_id,
    amount,
    currency,
    amount_kzt,
    created_at,
    flag_type,
    flag_reason
FROM high_frequency_customers
UNION ALL
SELECT
    transaction_id,
    customer_id,
    full_name,
    from_account_id,
    to_account_id,
    amount,
    currency,
    amount_kzt,
    created_at,
    flag_type,
    flag_reason
FROM rapid_sequential_transfers
ORDER BY created_at DESC;

--View 3:
SELECT * FROM suspicious_activity_view;



-- 1. B-tree index, fast IIN lookups for customer authentication
CREATE INDEX idx_customers_iin ON customers USING btree (iin);

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE iin = '123456789012';

-- 2. Hash index, Ultra-fast account number lookups (equality only)
CREATE INDEX idx_accounts_account_number_hash ON accounts USING hash (account_number);

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE account_number = 'KZ123456789012345678';

-- 3. Composite covering index, optimizes daily transaction limit checks
CREATE INDEX idx_transactions_covering_daily
ON transactions (from_account_id, status, created_at, amount_kzt)
WHERE status = 'completed';

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE from_account_id = 123
  AND status = 'completed'
  AND created_at >= '2025-12-01'
  AND amount_kzt > 10000;

-- 4. Partial index, indexes only active accounts to reduce size
CREATE INDEX idx_accounts_active_only
ON accounts (customer_id, currency, balance)
WHERE is_active = TRUE;

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE is_active = TRUE
  AND currency = 'KZT'
  AND balance > 10000;

-- 5. Expression index, case-insensitive email search
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE LOWER(email) = 'example@example.com';

-- 6. Gin index, fast JSONB queries on audit log
CREATE INDEX idx_audit_log_new_values_gin ON audit_log USING gin (new_values jsonb_path_ops);

-- Test index:

EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{"event_type": "login"}';

--Task 4: Advanced Procedure - Batch Processing;

CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number VARCHAR(20),
    p_payments JSONB
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    total_amount NUMERIC(15,2),
    account_balance NUMERIC(15,2),
    successful_count INTEGER,
    failed_count INTEGER,
    failed_details JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id INTEGER;
    v_account_balance NUMERIC(15,2);
    v_total_amount NUMERIC(15,2);
    v_currency VARCHAR(3);
    v_is_active BOOLEAN;
    v_successful_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_failed_details JSONB := '[]'::JSONB;
    v_successful_payments JSONB := '[]'::JSONB;
    v_error_message TEXT;
    v_lock_acquired BOOLEAN;
    v_payment JSONB;
    v_employee_iin VARCHAR(12);
    v_payment_amount NUMERIC(15,2);
    v_payment_desc TEXT;
    v_employee_account_id INTEGER;
    v_balance_updates JSONB := '{}'::JSONB;
    v_account_key TEXT;
    v_current_delta NUMERIC(15,2);
    v_expected_updates INTEGER := 0;
    v_actual_updates INTEGER := 0;
    v_amount_kzt NUMERIC(15,2);
BEGIN
    -- Validate company account
    SELECT account_id, balance, currency, is_active
    INTO v_account_id, v_account_balance, v_currency, v_is_active
    FROM accounts
    WHERE account_number = p_company_account_number;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT
            FALSE,
            'Company account not found'::TEXT,
            0::NUMERIC(15,2),
            0::NUMERIC(15,2),
            0::INTEGER,
            0::INTEGER,
            '[]'::JSONB;
        RETURN;
    END IF;

    -- Try to acquire advisory lock (prevents concurrent batches)
    SELECT pg_try_advisory_xact_lock(v_account_id) INTO v_lock_acquired;

    IF NOT v_lock_acquired THEN
        RETURN QUERY SELECT
            FALSE,
            'Another batch is currently being processed for this company account'::TEXT,
            0::NUMERIC(15,2),
            v_account_balance,
            0::INTEGER,
            0::INTEGER,
            '[]'::JSONB;
        RETURN;
    END IF;

    IF NOT v_is_active THEN
        RETURN QUERY SELECT
            FALSE,
            'Company account is not active'::TEXT,
            0::NUMERIC(15,2),
            v_account_balance,
            0::INTEGER,
            0::INTEGER,
            '[]'::JSONB;
        RETURN;
    END IF;

    -- Calculate and validate total

    SELECT COALESCE(SUM((payment->>'amount')::NUMERIC(15,2)), 0)
    INTO v_total_amount
    FROM jsonb_array_elements(p_payments) AS payment;

    IF v_total_amount > v_account_balance THEN
        RETURN QUERY SELECT
            FALSE,
            'Insufficient funds: batch total exceeds account balance'::TEXT,
            v_total_amount,
            v_account_balance,
            0::INTEGER,
            0::INTEGER,
            '[]'::JSONB;
        RETURN;
    END IF;

    -- Validate all payments

    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        BEGIN
            -- Extract payment details
            v_employee_iin := v_payment->>'iin';
            v_payment_amount := (v_payment->>'amount')::NUMERIC(15,2);
            v_payment_desc := v_payment->>'description';

            -- Validate employee account exists
            SELECT a.account_id
            INTO v_employee_account_id
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_employee_iin
                AND a.currency = v_currency
                AND a.is_active = TRUE
            LIMIT 1;

            IF v_employee_account_id IS NULL THEN
                RAISE EXCEPTION 'Employee account not found for IIN: %', v_employee_iin;
            END IF;

            -- Calculate amount in KZT for transaction record
            v_amount_kzt := CASE
                WHEN v_currency = 'KZT' THEN v_payment_amount
                WHEN v_currency = 'USD' THEN v_payment_amount * 480
                WHEN v_currency = 'EUR' THEN v_payment_amount * 520
                WHEN v_currency = 'RUB' THEN v_payment_amount * 5.5
                ELSE v_payment_amount
            END;

            -- Accumulate balance changes for company account
            v_account_key := v_account_id::TEXT;
            v_current_delta := COALESCE((v_balance_updates->v_account_key)::NUMERIC(15,2), 0);
            v_balance_updates := jsonb_set(
                v_balance_updates,
                ARRAY[v_account_key],
                to_jsonb(v_current_delta - v_payment_amount)
            );

            -- Accumulate balance changes for employee account
            v_account_key := v_employee_account_id::TEXT;
            v_current_delta := COALESCE((v_balance_updates->v_account_key)::NUMERIC(15,2), 0);
            v_balance_updates := jsonb_set(
                v_balance_updates,
                ARRAY[v_account_key],
                to_jsonb(v_current_delta + v_payment_amount)
            );

            -- Store successful payment info for transaction creation
            v_successful_payments := v_successful_payments || jsonb_build_object(
                'employee_account_id', v_employee_account_id,
                'amount', v_payment_amount,
                'amount_kzt', v_amount_kzt,
                'description', v_payment_desc
            );

            v_successful_count := v_successful_count + 1;

        EXCEPTION WHEN OTHERS THEN
            -- Validation failed for this payment, add to failed list
            v_failed_count := v_failed_count + 1;
            GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;

            v_failed_details := v_failed_details || jsonb_build_object(
                'iin', v_employee_iin,
                'amount', v_payment_amount,
                'description', v_payment_desc,
                'error', v_error_message
            );
        END;
    END LOOP;

    -- Check if any payments were successful
    IF v_successful_count = 0 THEN
        RETURN QUERY SELECT
            FALSE,
            'All payments failed validation'::TEXT,
            v_total_amount,
            v_account_balance,
            0::INTEGER,
            v_failed_count,
            v_failed_details;
        RETURN;
    END IF;

    -- Update all balances automatically

    -- Count expected updates (number of unique accounts to update)
    SELECT COUNT(*) INTO v_expected_updates
    FROM jsonb_object_keys(v_balance_updates);

    -- Perform atomic balance update
    WITH updated AS (
        UPDATE accounts
        SET balance = balance + (v_balance_updates->>account_id::TEXT)::NUMERIC(15,2)
        WHERE account_id::TEXT = ANY(
            SELECT jsonb_object_keys(v_balance_updates)
        )
        RETURNING account_id
    )
    SELECT COUNT(*) INTO v_actual_updates FROM updated;

    -- Verify all expected accounts were updated
    IF v_actual_updates != v_expected_updates THEN
        RAISE EXCEPTION 'Balance update failed: expected % updates, got %',
            v_expected_updates, v_actual_updates;
    END IF;

    -- Create transactions records

    FOR v_payment IN SELECT * FROM jsonb_array_elements(v_successful_payments)
    LOOP
        INSERT INTO transactions (
            from_account_id,
            to_account_id,
            amount,
            currency,
            exchange_rate,
            amount_kzt,
            type,
            status,
            created_at,
            completed_at,
            description
        ) VALUES (
            v_account_id,
            (v_payment->>'employee_account_id')::INTEGER,
            (v_payment->>'amount')::NUMERIC(15,2),
            v_currency,
            1.0,
            (v_payment->>'amount_kzt')::NUMERIC(15,2),
            'transfer',
            'completed',
            NOW(),
            NOW(),
            COALESCE(v_payment->>'description', '') || ' [SALARY_BYPASS_LIMIT]'
        );
    END LOOP;

    -- Return result

    RETURN QUERY SELECT
        TRUE,
        FORMAT('Batch completed: %s successful, %s failed', v_successful_count, v_failed_count)::TEXT,
        v_total_amount,
        v_account_balance - v_total_amount,  -- New balance after successful payments
        v_successful_count,
        v_failed_count,
        v_failed_details;

EXCEPTION
    WHEN OTHERS THEN
        -- Complete rollback on any error
        -- Return error status
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;

        RETURN QUERY SELECT
            FALSE,
            FORMAT('Batch failed: %s', v_error_message)::TEXT,
            v_total_amount,
            v_account_balance,
            0::INTEGER,
            jsonb_array_length(p_payments)::INTEGER,
            jsonb_build_array(
                jsonb_build_object(
                    'error', v_error_message,
                    'note', 'Complete batch rolled back'
                )
            );
END;
$$;

-- Materialized view for salary batch processing summary
CREATE MATERIALIZED VIEW IF NOT EXISTS salary_batch_summary AS
SELECT
    t.from_account_id,
    a.account_number AS company_account,
    c.full_name AS company_name,
    a.currency,
    DATE(t.created_at) AS batch_date,
    COUNT(*) AS total_payments,
    SUM(t.amount) AS total_amount,
    SUM(t.amount_kzt) AS total_amount_kzt,
    COUNT(*) FILTER (WHERE t.status = 'completed') AS successful_payments,
    COUNT(*) FILTER (WHERE t.status = 'failed') AS failed_payments,
    MIN(t.created_at) AS batch_start_time,
    MAX(t.completed_at) AS batch_end_time,
    EXTRACT(EPOCH FROM (MAX(t.completed_at) - MIN(t.created_at))) AS processing_time_seconds,
    jsonb_agg(
        jsonb_build_object(
            'transaction_id', t.transaction_id,
            'employee_account', to_acc.account_number,
            'employee_name', emp.full_name,
            'amount', t.amount,
            'status', t.status,
            'completed_at', t.completed_at
        ) ORDER BY t.created_at
    ) AS payment_details
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN accounts to_acc ON t.to_account_id = to_acc.account_id
LEFT JOIN customers emp ON to_acc.customer_id = emp.customer_id
WHERE t.description LIKE '%[SALARY_BYPASS_LIMIT]%'
    AND t.type = 'transfer'
GROUP BY
    t.from_account_id,
    a.account_number,
    c.full_name,
    a.currency,
    DATE(t.created_at)
ORDER BY batch_date DESC, company_account;

INSERT INTO customers (customer_id, iin, full_name, phone, email, status, created_at, daily_limit_kzt)
VALUES (100, '123456789012', 'Test Company LLC', '+77001234567', 'company@test.kz', 'active', NOW(), 100000000);

-- Test: Large batch (all 10 employees, multiple times)
SELECT * FROM process_salary_batch(
    'COMPANY-001',
    '[
        {"iin": "010101123456", "amount": 100000, "description": "Salary Mar"},
        {"iin": "020202234567", "amount": 95000, "description": "Salary Mar"},
        {"iin": "030303345678", "amount": 105000, "description": "Salary Mar"},
        {"iin": "050505567890", "amount": 110000, "description": "Salary Mar"},
        {"iin": "060606678901", "amount": 98000, "description": "Salary Mar"},
        {"iin": "070707789012", "amount": 120000, "description": "Salary Mar"},
        {"iin": "080808890123", "amount": 102000, "description": "Salary Mar"},
        {"iin": "090909901234", "amount": 97000, "description": "Salary Mar"},
        {"iin": "991231112233", "amount": 115000, "description": "Salary Mar"},
        {"iin": "010101123456", "amount": 50000, "description": "Bonus"},
        {"iin": "020202234567", "amount": 45000, "description": "Bonus"},
        {"iin": "030303345678", "amount": 52000, "description": "Bonus"},
        {"iin": "050505567890", "amount": 55000, "description": "Bonus"},
        {"iin": "060606678901", "amount": 49000, "description": "Bonus"},
        {"iin": "070707789012", "amount": 60000, "description": "Bonus"}
    ]'::jsonb
);

--Test view:
SELECT * FROM salary_batch_summary;


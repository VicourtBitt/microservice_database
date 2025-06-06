-- Create the stg_employee table
CREATE TABLE IF NOT EXISTS stg_employee (
    employee_id SERIAL PRIMARY KEY,
    employee_status BOOLEAN DEFAULT TRUE,
    employee_name VARCHAR(255) NOT NULL,
    employee_email VARCHAR(255) NOT NULL,
    employee_phone VARCHAR(255) NOT NULL,
    is_current BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE stg_employee IS 'This table stores information about employees';
COMMENT ON COLUMN stg_employee.employee_id IS 'This is the primary key for the table';
COMMENT ON COLUMN stg_employee.employee_name IS 'This is the name of the employee';
COMMENT ON COLUMN stg_employee.employee_email IS 'This is the email of the employee';
COMMENT ON COLUMN stg_employee.employee_phone IS 'This is the phone number of the employee';
COMMENT ON COLUMN stg_employee.employee_status IS 'This indicates if the employee is active or not';
COMMENT ON COLUMN stg_employee.last_updated IS 'This is the last time the record was updated';


-- Create the stg_client table with a foreign key constraint
CREATE TABLE IF NOT EXISTS stg_client (
    client_id SERIAL PRIMARY KEY,
    client_attendant_id INT NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    client_phone VARCHAR(255) NOT NULL,
    is_current BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_attendant_id FOREIGN KEY (client_attendant_id) REFERENCES stg_employee(employee_id)
);

COMMENT ON TABLE stg_client IS 'This table stores information about clients';
COMMENT ON COLUMN stg_client.client_id IS 'This is the primary key for the table';
COMMENT ON COLUMN stg_client.client_attendant_id IS 'This is the employee_id of the attendant';
COMMENT ON COLUMN stg_client.client_name IS 'This is the name of the client';
COMMENT ON COLUMN stg_client.client_email IS 'This is the email of the client';
COMMENT ON COLUMN stg_client.client_phone IS 'This is the phone number of the client';
COMMENT ON COLUMN stg_client.is_current IS 'This indicates if the client is current or not';
COMMENT ON COLUMN stg_client.last_updated IS 'This is the last time the record was updated';


-- Client Account Table
CREATE TABLE IF NOT EXISTS dim_client_account (
    account_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    account_balance DECIMAL(10, 2) NOT NULL,
    is_current BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_id FOREIGN KEY (client_id) REFERENCES stg_client(client_id)
); 

CREATE INDEX IF NOT EXISTS idx_dim_client_account_client_id ON dim_client_account(client_id);

COMMENT ON TABLE dim_client_account IS 'This table stores information about client accounts';
COMMENT ON COLUMN dim_client_account.account_id IS 'This is the primary key for the table';
COMMENT ON COLUMN dim_client_account.client_id IS 'This is the client_id of the client';
COMMENT ON COLUMN dim_client_account.account_balance IS 'This is the balance of the account';
COMMENT ON COLUMN dim_client_account.is_current IS 'This indicates if the account is current or not';
COMMENT ON COLUMN dim_client_account.registered_at IS 'This is the date the account was registered';
COMMENT ON COLUMN dim_client_account.last_updated IS 'This is the last time the record was updated';


-- Transaction Table
CREATE TABLE IF NOT EXISTS dim_transaction (
    transaction_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL,
    transaction_type VARCHAR(255) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_id FOREIGN KEY (account_id) REFERENCES dim_client_account(account_id)
);

CREATE INDEX IF NOT EXISTS idx_dim_transaction_account_date ON dim_transaction(account_id, transaction_date);

COMMENT ON TABLE dim_transaction IS 'This table stores information about transactions';
COMMENT ON COLUMN dim_transaction.transaction_id IS 'This is the primary key for the table';
COMMENT ON COLUMN dim_transaction.account_id IS 'This is the account_id of the account';
COMMENT ON COLUMN dim_transaction.transaction_amount IS 'This is the amount of the transaction';
COMMENT ON COLUMN dim_transaction.transaction_type IS 'This is the type of the transaction';
COMMENT ON COLUMN dim_transaction.transaction_date IS 'This is the date of the transaction';
COMMENT ON COLUMN dim_transaction.last_updated IS 'This is the last time the record was updated';


-- Call the function to update the account balance
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Call the procedure to update the account balance
    CALL update_account_balance_procedure(NEW.account_id, NEW.transaction_type, NEW.transaction_amount);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Update the account balance procedure
CREATE OR REPLACE PROCEDURE update_account_balance_procedure(p_account_id INT, p_transaction_type VARCHAR(255), p_transaction_amount DECIMAL(10, 2))
AS $$
BEGIN
    IF p_transaction_type = 'D' THEN
        UPDATE dim_client_account
        SET account_balance = account_balance - p_transaction_amount
        WHERE account_id = p_account_id;
    ELSIF p_transaction_type = 'C' THEN
        UPDATE dim_client_account
        SET account_balance = account_balance + p_transaction_amount
        WHERE account_id = p_account_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Create trigger on dim_transaction to update account balance after an insert
CREATE TRIGGER trg_update_account_balance
AFTER INSERT ON dim_transaction
FOR EACH ROW
EXECUTE FUNCTION update_account_balance();


-- LOGIN TABLES
CREATE TABLE IF NOT EXISTS dim_user_login (
    user_id SERIAL PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL UNIQUE,
    user_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

COMMENT ON TABLE dim_user_login IS 'This table stores information about users';
COMMENT ON COLUMN dim_user_login.user_id IS 'This is the primary key for the table';
COMMENT ON COLUMN dim_user_login.user_email IS 'This is the email of the user';
COMMENT ON COLUMN dim_user_login.user_hash IS 'This is the hashed password of the user';
COMMENT ON COLUMN dim_user_login.is_active IS 'This indicates if the user is active or not';
COMMENT ON COLUMN dim_user_login.last_updated IS 'This is the last time the record was updated';


-- JWT TABLE
CREATE TABLE IF NOT EXISTS dim_json_web_tokens (
    jwt_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    jwt_refresh_token VARCHAR(255) NOT NULL,
    jwt_refresh_expiration TIMESTAMP NOT NULL,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES dim_user_login(user_id)
);

CREATE INDEX IF NOT EXISTS idx_dim_json_web_tokens_user_id ON dim_json_web_tokens(user_id);

COMMENT ON TABLE dim_json_web_tokens IS 'This table stores information about JWT tokens';
COMMENT ON COLUMN dim_json_web_tokens.jwt_id IS 'This is the primary key for the table';
COMMENT ON COLUMN dim_json_web_tokens.user_id IS 'This is the user_id of the user';
COMMENT ON COLUMN dim_json_web_tokens.jwt_refresh_token IS 'This is the refresh token';
COMMENT ON COLUMN dim_json_web_tokens.jwt_refresh_expiration IS 'This is the expiration date of the refresh token';


-- Seed some information into each table (if they exist)
INSERT INTO stg_employee (employee_name, employee_email, employee_phone)
VALUES 
    ('John Doe', 'john.doe@email.com', '123-456-7890'),
    ('Victor Bittencourt', 'victor.bittencourt@email.com', '098-765-4321');


INSERT INTO stg_client (client_attendant_id, client_name, client_email, client_phone)
VALUES 
    (1, 'Nestor Preisler', 'nestor.preisler@email.com', '321-654-9870'),
    (2, 'Luisa Bittencourt', 'luisa.bittencourt@email.com', '456-789-0123');


INSERT INTO dim_client_account (client_id, account_balance)
VALUES 
    (1, 10000.00),
    (2, 2500.00);


INSERT INTO dim_transaction (account_id, transaction_amount, transaction_type)
VALUES 
    (1, 1000.00, 'D'),
    (2, 500.00, 'D');


INSERT INTO stg_employee (employee_status, employee_name, employee_email, employee_phone, is_current, last_updated)
SELECT 
    CASE WHEN (random() > 0.5) THEN TRUE ELSE FALSE END AS employee_status,
    'test' || gs AS employee_name,
    'test' || gs || '@email.com' AS employee_email,
    LPAD((trunc(random()*1000000000)::bigint)::text, 10, '0') AS employee_phone,
    CASE WHEN (random() > 0.2) THEN TRUE ELSE FALSE END AS is_current,
    now() - (random() * INTERVAL '365 days') AS last_updated
FROM generate_series(1, 1000) AS gs;


INSERT INTO public.stg_client (
    client_attendant_id, 
    client_name, 
    client_email, 
    client_phone, 
    is_current, 
    last_updated
)
SELECT 
    (trunc(random() * 1000 + 1))::int AS client_attendant_id,  -- Random attendant ID between 1 and 1000
    'client_test' || gs AS client_name,
    'client_test' || gs || '@email.com' AS client_email,
    LPAD((trunc(random() * 1000000000)::bigint)::text, 10, '0') AS client_phone,
    CASE WHEN random() > 0.1 THEN TRUE ELSE FALSE END AS is_current, -- 90% chance current
    now() - (random() * INTERVAL '365 days') AS last_updated
FROM generate_series(1, 1000) AS gs;


INSERT INTO public.dim_client_account (
    client_id, 
    account_balance, 
    is_current, 
    registered_at, 
    last_updated
)
SELECT 
    (trunc(random() * 1000 + 1))::int AS client_id,  -- Random client ID between 1 and 1000
    round((random() * 10000 + 100)::numeric, 2) AS account_balance, -- Random balance between 100.00 and 10,100.00
    CASE WHEN random() > 0.1 THEN TRUE ELSE FALSE END AS is_current, -- 90% chance of being current
    now() - (random() * INTERVAL '1000 days') AS registered_at, -- Random up to ~3 years ago
    now() - (random() * INTERVAL '365 days') AS last_updated -- Random update within last year
FROM generate_series(1, 1000) AS gs;


INSERT INTO public.dim_transaction (
    account_id,
    transaction_amount,
    transaction_type,
    transaction_date,
    last_updated
)
SELECT 
    (trunc(random() * 1000 + 1))::int AS account_id,  -- Random account ID between 1 and 1000
    round((random() * 500 + 1)::numeric, 2) AS transaction_amount, -- Random amount between 1.00 and 501.00
    CASE WHEN random() > 0.5 THEN 'C' ELSE 'D' END AS transaction_type, -- 'C' for credit, 'D' for debit
    now() - (random() * INTERVAL '365 days') AS transaction_date, -- Random date within last year
    now() - (random() * INTERVAL '365 days') AS last_updated -- Random update within last year
FROM generate_series(1, 10000) AS gs;


ALTER TABLE public.stg_employee
ADD COLUMN employee_team varchar(255);

ALTER TABLE public.stg_employee
ADD COLUMN employee_squad varchar(255);

-- Update employee_team with a random team
UPDATE public.stg_employee
SET employee_team = CASE
    WHEN random() < 0.33 THEN 'AlphaForce'
    WHEN random() < 0.66 THEN 'BetaCore'
    ELSE 'GammaOps'
END;

-- Update employee_squad based on assigned team
UPDATE public.stg_employee
SET employee_squad = CASE employee_team
    WHEN 'AlphaForce' THEN
        (ARRAY['Falcon', 'Lynx', 'Viper'])[floor(random() * 3 + 1)]
    WHEN 'BetaCore' THEN
        (ARRAY['Titan', 'Nova', 'Eclipse', 'Orion'])[floor(random() * 4 + 1)]
    WHEN 'GammaOps' THEN
        (ARRAY['Hydra', 'Kraken'])[floor(random() * 2 + 1)]
    ELSE NULL
END;

-- Grant privileges to app_user
GRANT ALL PRIVILEGES ON TABLE stg_employee TO app_user;
GRANT ALL PRIVILEGES ON TABLE stg_client TO app_user;
GRANT ALL PRIVILEGES ON TABLE dim_user_login TO app_user;
GRANT ALL PRIVILEGES ON TABLE dim_json_web_tokens TO app_user;
GRANT ALL PRIVILEGES ON TABLE dim_client_account TO app_user;
GRANT ALL PRIVILEGES ON TABLE dim_transaction TO app_user;
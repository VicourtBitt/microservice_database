-- Create the stg_employee table
CREATE TABLE IF NOT EXISTS stg_employee (
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(255) NOT NULL,
    employee_email VARCHAR(255) NOT NULL,
    employee_phone VARCHAR(255) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Create the stg_client table with a foreign key constraint
CREATE TABLE IF NOT EXISTS stg_client (
    client_id SERIAL PRIMARY KEY,
    client_attendant_id INT NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    client_phone VARCHAR(255) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_attendant_id FOREIGN KEY (client_attendant_id) REFERENCES stg_employee(employee_id)
);


-- Seed some information into each table (if they exist)
INSERT INTO stg_employee (employee_name, employee_email, employee_phone)
VALUES 
    ('John Doe', 'john.doe@email.com', '123-456-7890'),
    ('Victor Bittencourt', 'victor.bittencourt@email.com', '098-765-4321');


INSERT INTO stg_client (client_attendant_id, client_name, client_email, client_phone)
VALUES 
    (1, 'Nestor Preisler', 'nestor.preisler@email.com', '321-654-9870'),
    (2, 'Luisa Bittencourt', 'luisa.bittencourt@email.com', '456-789-0123');


-- Grant privileges to app_user
GRANT ALL PRIVILEGES ON TABLE stg_employee TO app_user;
GRANT ALL PRIVILEGES ON TABLE stg_client TO app_user;
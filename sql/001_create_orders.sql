-- Run this by hand on the prod DB before the first deployment (Dave has the password)
CREATE TABLE orders (
    id            BIGINT IDENTITY PRIMARY KEY,
    customer_name VARCHAR(200),
    product       VARCHAR(200),
    quantity      INT,
    unit_price    DECIMAL(19,2),
    created_at    DATETIME2
);

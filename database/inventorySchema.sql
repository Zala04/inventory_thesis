CREATE TABLE items (
    id INTEGER PRIMARY KEY,
    name TEXT,
    price NUMERIC,
    amount INTEGER,
    forecast_days NUMERIC,
    items_date DATE,
    model_name TEXT
);

CREATE TABLE sales (
    item_id INTEGER,
    sales_date DATE,
    amount_sold INTEGER,
    FOREIGN KEY (item_id) REFERENCES items(id)
);
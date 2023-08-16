CREATE TABLE accounts (created_at TIMESTAMPTZ DEFAULT NOW(), 
    name TEXT,
    city TEXT);
SELECT create_hypertable('accounts', 'created_at');
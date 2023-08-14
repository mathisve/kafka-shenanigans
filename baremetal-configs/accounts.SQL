CREATE TABLE accounts (created_at TIMESTAMPTZ DEFAULT NOW(), 
    username TEXT,
    city TEXT);
SELECT create_hypertable('accounts', 'created_at');
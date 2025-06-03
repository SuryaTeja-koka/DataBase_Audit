-- SQLite Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential SQLite monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE IF NOT EXISTS admin.sqlite_qrylog_metrics_smry (
    query_id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_start_date TEXT,  -- SQLite doesn't have a native DATE type
    user_name TEXT,
    user_id INTEGER,
    database_name TEXT,
    query_text TEXT,
    query_type TEXT,
    queue_start_time TEXT,  -- SQLite doesn't have a native TIMESTAMP type
    class_id INTEGER,
    slots_used INTEGER,
    queue_seconds INTEGER,
    exec_seconds INTEGER,
    total_seconds INTEGER,
    gating_efficiency REAL,
    gating_bin INTEGER,
    aborted INTEGER,  -- SQLite uses INTEGER for boolean (0 or 1)
    process_id INTEGER,
    transaction_id INTEGER,
    query_start_time TEXT,
    query_start_min REAL,
    query_start_hour REAL,
    disk_based TEXT,
    rr_scan TEXT,
    delayed_scan TEXT,
    steps_count INTEGER,
    total_bytes_churn_gb INTEGER,
    max_mem_held_gb INTEGER,
    event TEXT,
    workers_used INTEGER,
    query_cpu_time INTEGER,
    query_blocks_read INTEGER,
    query_execution_time INTEGER,
    burn_rate REAL,
    burn_rate_bin INTEGER,
    query_temp_blocks_to_disk INTEGER,
    segment_execution_time INTEGER,
    cpu_skew REAL,
    parallel_efficiency REAL,
    parallel_efficiency_disk REAL,
    effective_cpu REAL,
    skew_overhead REAL,
    scan_row_count INTEGER,
    join_row_count INTEGER,
    nested_loop_join_row_count INTEGER,
    total_rows_returned INTEGER,
    total_row_churn INTEGER,
    pe_bin INTEGER,
    log_date TEXT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sqlite_qrylog_query_start_date ON admin.sqlite_qrylog_metrics_smry(query_start_date);
CREATE INDEX IF NOT EXISTS idx_sqlite_qrylog_user_id ON admin.sqlite_qrylog_metrics_smry(user_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_qrylog_log_date ON admin.sqlite_qrylog_metrics_smry(log_date);

-- Table Size History Tracking Table
CREATE TABLE IF NOT EXISTS admin.sqlite_tablesize_history (
    log_date TEXT,
    table_owner TEXT,
    database_name TEXT,
    schema_name TEXT,
    table_name TEXT,
    node_number INTEGER,
    partition_number INTEGER,
    mb_count INTEGER,
    row_count INTEGER,
    value_count INTEGER,
    block_min_val INTEGER,
    block_max_val INTEGER,
    PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number)
);

CREATE INDEX IF NOT EXISTS idx_sqlite_tablesize_log_date ON admin.sqlite_tablesize_history(log_date);

-- Table Usage Tracking Table
CREATE TABLE IF NOT EXISTS admin.sqlite_tableusage (
    query_id INTEGER,
    query_start_date TEXT,
    database_name TEXT,
    schema_name TEXT,
    table_id INTEGER,
    table_name TEXT,
    log_date TEXT,
    PRIMARY KEY (query_id, table_id)
);

CREATE INDEX IF NOT EXISTS idx_sqlite_tableusage_query_start_date ON admin.sqlite_tableusage(query_start_date);
CREATE INDEX IF NOT EXISTS idx_sqlite_tableusage_log_date ON admin.sqlite_tableusage(log_date); 
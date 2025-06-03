-- IBM Db2 Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential IBM Db2 monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE admin.db2_qrylog_metrics_smry (
    query_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    query_start_date DATE,
    user_name VARCHAR(100),
    user_id INTEGER,
    database_name VARCHAR(32),
    query_text CLOB,
    query_type VARCHAR(15),
    queue_start_time TIMESTAMP,
    class_id INTEGER,
    slots_used INTEGER,
    queue_seconds BIGINT,
    exec_seconds BIGINT,
    total_seconds BIGINT,
    gating_efficiency DOUBLE,
    gating_bin INTEGER,
    aborted SMALLINT,
    process_id INTEGER,
    transaction_id BIGINT,
    query_start_time TIMESTAMP,
    query_start_min DOUBLE,
    query_start_hour DOUBLE,
    disk_based CHAR(1),
    rr_scan CHAR(1),
    delayed_scan CHAR(1),
    steps_count BIGINT,
    total_bytes_churn_gb BIGINT,
    max_mem_held_gb BIGINT,
    event VARCHAR(1024),
    workers_used INTEGER,
    query_cpu_time BIGINT,
    query_blocks_read BIGINT,
    query_execution_time BIGINT,
    burn_rate DOUBLE,
    burn_rate_bin INTEGER,
    query_temp_blocks_to_disk BIGINT,
    segment_execution_time BIGINT,
    cpu_skew DECIMAL(38,2),
    parallel_efficiency DECIMAL(38,33),
    parallel_efficiency_disk DECIMAL(38,33),
    effective_cpu DECIMAL(38,2),
    skew_overhead DECIMAL(38,2),
    scan_row_count BIGINT,
    join_row_count BIGINT,
    nested_loop_join_row_count BIGINT,
    total_rows_returned BIGINT,
    total_row_churn BIGINT,
    pe_bin INTEGER,
    log_date DATE
)
PARTITION BY RANGE (log_date) (
    STARTING FROM (CURRENT DATE - 180 DAYS) ENDING AT (CURRENT DATE + 30 DAYS) EVERY 30 DAYS
);

-- Create indexes for better query performance
CREATE INDEX idx_db2_qrylog_query_start_date ON admin.db2_qrylog_metrics_smry(query_start_date);
CREATE INDEX idx_db2_qrylog_user_id ON admin.db2_qrylog_metrics_smry(user_id);
CREATE INDEX idx_db2_qrylog_log_date ON admin.db2_qrylog_metrics_smry(log_date);

-- Table Size History Tracking Table
CREATE TABLE admin.db2_tablesize_history (
    log_date DATE,
    table_owner VARCHAR(50),
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_name VARCHAR(128),
    node_number SMALLINT,
    partition_number SMALLINT,
    mb_count INTEGER,
    row_count BIGINT,
    value_count BIGINT,
    block_min_val BIGINT,
    block_max_val BIGINT,
    PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number)
)
PARTITION BY RANGE (log_date) (
    STARTING FROM (CURRENT DATE - 180 DAYS) ENDING AT (CURRENT DATE + 30 DAYS) EVERY 30 DAYS
);

CREATE INDEX idx_db2_tablesize_log_date ON admin.db2_tablesize_history(log_date);

-- Table Usage Tracking Table
CREATE TABLE admin.db2_tableusage (
    query_id BIGINT,
    query_start_date DATE,
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_id INTEGER,
    table_name VARCHAR(128),
    log_date DATE,
    PRIMARY KEY (query_id, table_id)
)
PARTITION BY RANGE (log_date) (
    STARTING FROM (CURRENT DATE - 180 DAYS) ENDING AT (CURRENT DATE + 30 DAYS) EVERY 30 DAYS
);

CREATE INDEX idx_db2_tableusage_query_start_date ON admin.db2_tableusage(query_start_date);
CREATE INDEX idx_db2_tableusage_log_date ON admin.db2_tableusage(log_date); 
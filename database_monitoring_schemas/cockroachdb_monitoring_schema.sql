-- CockroachDB Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential CockroachDB monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE admin.cockroachdb_qrylog_metrics_smry (
    query_id BIGINT DEFAULT unique_rowid() PRIMARY KEY,
    query_start_date DATE,
    user_name STRING,
    user_id INT,
    database_name STRING,
    query_text STRING,
    query_type STRING,
    queue_start_time TIMESTAMP,
    class_id INT,
    slots_used INT,
    queue_seconds BIGINT,
    exec_seconds BIGINT,
    total_seconds BIGINT,
    gating_efficiency FLOAT8,
    gating_bin INT,
    aborted BOOL,
    process_id INT,
    transaction_id BIGINT,
    query_start_time TIMESTAMP,
    query_start_min FLOAT8,
    query_start_hour FLOAT8,
    disk_based STRING,
    rr_scan STRING,
    delayed_scan STRING,
    steps_count BIGINT,
    total_bytes_churn_gb BIGINT,
    max_mem_held_gb BIGINT,
    event STRING,
    workers_used INT,
    query_cpu_time BIGINT,
    query_blocks_read BIGINT,
    query_execution_time BIGINT,
    burn_rate FLOAT8,
    burn_rate_bin INT,
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
    pe_bin INT,
    log_date DATE,
    INDEX idx_query_start_date (query_start_date),
    INDEX idx_user_id (user_id),
    INDEX idx_log_date (log_date)
) PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES FROM (MINVALUE) TO (CURRENT_DATE - INTERVAL '180 days'),
    PARTITION p_current VALUES FROM (CURRENT_DATE - INTERVAL '180 days') TO (CURRENT_DATE + INTERVAL '30 days'),
    PARTITION p_future VALUES FROM (CURRENT_DATE + INTERVAL '30 days') TO (MAXVALUE)
);

-- Table Size History Tracking Table
CREATE TABLE admin.cockroachdb_tablesize_history (
    log_date DATE,
    table_owner STRING,
    database_name STRING,
    schema_name STRING,
    table_name STRING,
    node_number INT2,
    partition_number INT2,
    mb_count INT,
    row_count BIGINT,
    value_count BIGINT,
    block_min_val BIGINT,
    block_max_val BIGINT,
    PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number),
    INDEX idx_log_date (log_date)
) PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES FROM (MINVALUE) TO (CURRENT_DATE - INTERVAL '180 days'),
    PARTITION p_current VALUES FROM (CURRENT_DATE - INTERVAL '180 days') TO (CURRENT_DATE + INTERVAL '30 days'),
    PARTITION p_future VALUES FROM (CURRENT_DATE + INTERVAL '30 days') TO (MAXVALUE)
);

-- Table Usage Tracking Table
CREATE TABLE admin.cockroachdb_tableusage (
    query_id BIGINT,
    query_start_date DATE,
    database_name STRING,
    schema_name STRING,
    table_id INT,
    table_name STRING,
    log_date DATE,
    PRIMARY KEY (query_id, table_id),
    INDEX idx_query_start_date (query_start_date),
    INDEX idx_log_date (log_date)
) PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES FROM (MINVALUE) TO (CURRENT_DATE - INTERVAL '180 days'),
    PARTITION p_current VALUES FROM (CURRENT_DATE - INTERVAL '180 days') TO (CURRENT_DATE + INTERVAL '30 days'),
    PARTITION p_future VALUES FROM (CURRENT_DATE + INTERVAL '30 days') TO (MAXVALUE)
); 
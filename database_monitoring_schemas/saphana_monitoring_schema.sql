-- SAP HANA Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential SAP HANA monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE admin.saphana_qrylog_metrics_smry (
    query_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    query_start_date DATE,
    user_name NVARCHAR(100),
    user_id INTEGER,
    database_name NVARCHAR(32),
    query_text NCLOB,
    query_type NVARCHAR(15),
    queue_start_time TIMESTAMP,
    class_id INTEGER,
    slots_used INTEGER,
    queue_seconds BIGINT,
    exec_seconds BIGINT,
    total_seconds BIGINT,
    gating_efficiency DOUBLE,
    gating_bin INTEGER,
    aborted TINYINT,
    process_id INTEGER,
    transaction_id BIGINT,
    query_start_time TIMESTAMP,
    query_start_min DOUBLE,
    query_start_hour DOUBLE,
    disk_based NVARCHAR(1),
    rr_scan NVARCHAR(1),
    delayed_scan NVARCHAR(1),
    steps_count BIGINT,
    total_bytes_churn_gb BIGINT,
    max_mem_held_gb BIGINT,
    event NVARCHAR(1024),
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
    PARTITION p_old VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, -180)),
    PARTITION p_current VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, 30)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- Create indexes for better query performance
CREATE INDEX idx_saphana_qrylog_query_start_date ON admin.saphana_qrylog_metrics_smry(query_start_date);
CREATE INDEX idx_saphana_qrylog_user_id ON admin.saphana_qrylog_metrics_smry(user_id);
CREATE INDEX idx_saphana_qrylog_log_date ON admin.saphana_qrylog_metrics_smry(log_date);

-- Table Size History Tracking Table
CREATE TABLE admin.saphana_tablesize_history (
    log_date DATE,
    table_owner NVARCHAR(50),
    database_name NVARCHAR(128),
    schema_name NVARCHAR(128),
    table_name NVARCHAR(128),
    node_number SMALLINT,
    partition_number SMALLINT,
    mb_count INTEGER,
    row_count BIGINT,
    value_count BIGINT,
    block_min_val BIGINT,
    block_max_val BIGINT,
    CONSTRAINT pk_saphana_tablesize_history PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number)
)
PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, -180)),
    PARTITION p_current VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, 30)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

CREATE INDEX idx_saphana_tablesize_log_date ON admin.saphana_tablesize_history(log_date);

-- Table Usage Tracking Table
CREATE TABLE admin.saphana_tableusage (
    query_id BIGINT,
    query_start_date DATE,
    database_name NVARCHAR(128),
    schema_name NVARCHAR(128),
    table_id INTEGER,
    table_name NVARCHAR(128),
    log_date DATE,
    CONSTRAINT pk_saphana_tableusage PRIMARY KEY (query_id, table_id)
)
PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, -180)),
    PARTITION p_current VALUES LESS THAN (ADD_DAYS(CURRENT_DATE, 30)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

CREATE INDEX idx_saphana_tableusage_query_start_date ON admin.saphana_tableusage(query_start_date);
CREATE INDEX idx_saphana_tableusage_log_date ON admin.saphana_tableusage(log_date); 
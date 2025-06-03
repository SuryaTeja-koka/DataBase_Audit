-- Oracle Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential Oracle monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE admin.oracle_qrylog_metrics_smry (
    query_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    query_start_date DATE,
    user_name VARCHAR2(100),
    user_id NUMBER,
    database_name VARCHAR2(32),
    query_text CLOB,
    query_type VARCHAR2(15),
    queue_start_time TIMESTAMP,
    class_id NUMBER,
    slots_used NUMBER,
    queue_seconds NUMBER,
    exec_seconds NUMBER,
    total_seconds NUMBER,
    gating_efficiency BINARY_DOUBLE,
    gating_bin NUMBER,
    aborted NUMBER(1),
    process_id NUMBER,
    transaction_id NUMBER,
    query_start_time TIMESTAMP,
    query_start_min BINARY_DOUBLE,
    query_start_hour BINARY_DOUBLE,
    disk_based CHAR(1),
    rr_scan CHAR(1),
    delayed_scan CHAR(1),
    steps_count NUMBER,
    total_bytes_churn_gb NUMBER,
    max_mem_held_gb NUMBER,
    event VARCHAR2(1024),
    workers_used NUMBER,
    query_cpu_time NUMBER,
    query_blocks_read NUMBER,
    query_execution_time NUMBER,
    burn_rate BINARY_DOUBLE,
    burn_rate_bin NUMBER,
    query_temp_blocks_to_disk NUMBER,
    segment_execution_time NUMBER,
    cpu_skew NUMBER(38,2),
    parallel_efficiency NUMBER(38,33),
    parallel_efficiency_disk NUMBER(38,33),
    effective_cpu NUMBER(38,2),
    skew_overhead NUMBER(38,2),
    scan_row_count NUMBER,
    join_row_count NUMBER,
    nested_loop_join_row_count NUMBER,
    total_rows_returned NUMBER,
    total_row_churn NUMBER,
    pe_bin NUMBER,
    log_date DATE
)
PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), -6)),
    PARTITION p_current VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), 1)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- Create indexes for better query performance
CREATE INDEX idx_oracle_qrylog_query_start_date ON admin.oracle_qrylog_metrics_smry(query_start_date);
CREATE INDEX idx_oracle_qrylog_user_id ON admin.oracle_qrylog_metrics_smry(user_id);
CREATE INDEX idx_oracle_qrylog_log_date ON admin.oracle_qrylog_metrics_smry(log_date);

-- Table Size History Tracking Table
CREATE TABLE admin.oracle_tablesize_history (
    log_date DATE,
    table_owner VARCHAR2(50),
    database_name VARCHAR2(128),
    schema_name VARCHAR2(128),
    table_name VARCHAR2(128),
    node_number NUMBER,
    partition_number NUMBER,
    mb_count NUMBER,
    row_count NUMBER,
    value_count NUMBER,
    block_min_val NUMBER,
    block_max_val NUMBER,
    CONSTRAINT pk_oracle_tablesize_history PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number)
)
PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), -6)),
    PARTITION p_current VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), 1)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

CREATE INDEX idx_oracle_tablesize_log_date ON admin.oracle_tablesize_history(log_date);

-- Table Usage Tracking Table
CREATE TABLE admin.oracle_tableusage (
    query_id NUMBER,
    query_start_date DATE,
    database_name VARCHAR2(128),
    schema_name VARCHAR2(128),
    table_id NUMBER,
    table_name VARCHAR2(128),
    log_date DATE,
    CONSTRAINT pk_oracle_tableusage PRIMARY KEY (query_id, table_id)
)
PARTITION BY RANGE (log_date) (
    PARTITION p_old VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), -6)),
    PARTITION p_current VALUES LESS THAN (ADD_MONTHS(TRUNC(SYSDATE), 1)),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

CREATE INDEX idx_oracle_tableusage_query_start_date ON admin.oracle_tableusage(query_start_date);
CREATE INDEX idx_oracle_tableusage_log_date ON admin.oracle_tableusage(log_date); 
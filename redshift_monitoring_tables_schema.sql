-- Redshift Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential Redshift monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE IF NOT EXISTS admin.redshift_qrylog_metrics_smry
(
    query INTEGER ENCODE az64,
    query_start_date DATE ENCODE RAW,
    user_name CHAR(100) ENCODE lzo,
    user_id INTEGER ENCODE az64,
    db VARCHAR(32) ENCODE lzo,
    query_text VARCHAR(4000) ENCODE lzo,
    query_type VARCHAR(15) ENCODE lzo,
    queue_start_time TIMESTAMP WITHOUT TIME ZONE ENCODE az64,
    class INTEGER ENCODE az64,
    slots INTEGER ENCODE az64,
    queue_seconds BIGINT ENCODE az64,
    exec_seconds BIGINT ENCODE az64,
    total_seconds BIGINT ENCODE az64,
    gating_efficiency DOUBLE PRECISION ENCODE RAW,
    gating_bin INTEGER ENCODE az64,
    aborted INTEGER ENCODE az64,
    pid INTEGER ENCODE az64,
    xid BIGINT ENCODE az64,
    query_start_time TIMESTAMP WITHOUT TIME ZONE ENCODE az64,
    query_start_min DOUBLE PRECISION ENCODE RAW,
    query_start_hour DOUBLE PRECISION ENCODE RAW,
    disk_based VARCHAR(1) ENCODE lzo,
    rr_scan VARCHAR(1) ENCODE lzo,
    delayed_scan VARCHAR(1) ENCODE lzo,
    steps_count BIGINT ENCODE az64,
    total_bytes_churn_gb BIGINT ENCODE az64,
    max_mem_held_gb BIGINT ENCODE az64,
    event VARCHAR(1024) ENCODE lzo,
    slices_used BIGINT ENCODE az64,
    query_cpu_time BIGINT ENCODE az64,
    query_blocks_read BIGINT ENCODE az64,
    query_execution_time BIGINT ENCODE az64,
    burn_rate DOUBLE PRECISION ENCODE RAW,
    burn_rate_bin INTEGER ENCODE az64,
    query_temp_blocks_to_disk BIGINT ENCODE az64,
    segment_execution_time BIGINT ENCODE az64,
    cpu_skew NUMERIC(38,2) ENCODE az64,
    parallel_efficiency NUMERIC(38,33) ENCODE az64,
    parallel_efficiency_disk NUMERIC(38,33) ENCODE az64,
    effective_cpu NUMERIC(38,2) ENCODE az64,
    skew_overhead NUMERIC(38,2) ENCODE az64,
    scan_row_count BIGINT ENCODE az64,
    join_row_count BIGINT ENCODE az64,
    nested_loop_join_row_count BIGINT ENCODE az64,
    total_rows_returned BIGINT ENCODE az64,
    total_row_churn BIGINT ENCODE az64,
    pe_bin INTEGER ENCODE az64,
    log_date DATE ENCODE az64
)
DISTSTYLE KEY
DISTKEY (query)
SORTKEY (query_start_date);

-- Table Size History Tracking Table
CREATE TABLE IF NOT EXISTS admin.redshift_tablesize_history
(
    log_date DATE ENCODE RAW,
    table_owner VARCHAR(50) ENCODE lzo,
    database_name VARCHAR(128) ENCODE lzo,
    schema_name VARCHAR(128) ENCODE lzo,
    table_name VARCHAR(128) ENCODE lzo,
    node_number SMALLINT ENCODE az64,
    slice_number SMALLINT ENCODE az64,
    mb_count INTEGER ENCODE az64,
    row_count BIGINT ENCODE az64,
    value_count BIGINT ENCODE az64,
    block_min_val BIGINT ENCODE az64,
    block_max_val BIGINT ENCODE az64
)
DISTSTYLE EVEN
SORTKEY (log_date);

-- Table Usage Tracking Table
CREATE TABLE IF NOT EXISTS admin.redshift_tableusage
(
    query INTEGER ENCODE az64,
    query_start_date DATE ENCODE RAW,
    database_name VARCHAR(128) ENCODE lzo,
    schema_name VARCHAR(128) ENCODE lzo,
    table_id INTEGER ENCODE az64,
    table_name VARCHAR(128) ENCODE lzo,
    log_date DATE ENCODE az64
)
DISTSTYLE KEY
DISTKEY (query)
SORTKEY (query_start_date); 
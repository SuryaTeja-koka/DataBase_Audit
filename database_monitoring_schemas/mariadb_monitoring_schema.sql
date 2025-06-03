-- MariaDB Performance Monitoring Tables Schema
-- This file contains the schema definitions for essential MariaDB monitoring tables

-- Query Performance Metrics Summary Table
CREATE TABLE IF NOT EXISTS admin.mariadb_qrylog_metrics_smry (
    query_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    query_start_date DATE,
    user_name VARCHAR(100),
    user_id INT UNSIGNED,
    database_name VARCHAR(32),
    query_text TEXT,
    query_type VARCHAR(15),
    queue_start_time TIMESTAMP,
    class_id INT UNSIGNED,
    slots_used INT UNSIGNED,
    queue_seconds BIGINT UNSIGNED,
    exec_seconds BIGINT UNSIGNED,
    total_seconds BIGINT UNSIGNED,
    gating_efficiency DOUBLE,
    gating_bin INT UNSIGNED,
    aborted TINYINT(1),
    process_id INT UNSIGNED,
    transaction_id BIGINT UNSIGNED,
    query_start_time TIMESTAMP,
    query_start_min DOUBLE,
    query_start_hour DOUBLE,
    disk_based CHAR(1),
    rr_scan CHAR(1),
    delayed_scan CHAR(1),
    steps_count BIGINT UNSIGNED,
    total_bytes_churn_gb BIGINT UNSIGNED,
    max_mem_held_gb BIGINT UNSIGNED,
    event VARCHAR(1024),
    threads_used INT UNSIGNED,
    query_cpu_time BIGINT UNSIGNED,
    query_blocks_read BIGINT UNSIGNED,
    query_execution_time BIGINT UNSIGNED,
    burn_rate DOUBLE,
    burn_rate_bin INT UNSIGNED,
    query_temp_blocks_to_disk BIGINT UNSIGNED,
    segment_execution_time BIGINT UNSIGNED,
    cpu_skew DECIMAL(38,2),
    parallel_efficiency DECIMAL(38,33),
    parallel_efficiency_disk DECIMAL(38,33),
    effective_cpu DECIMAL(38,2),
    skew_overhead DECIMAL(38,2),
    scan_row_count BIGINT UNSIGNED,
    join_row_count BIGINT UNSIGNED,
    nested_loop_join_row_count BIGINT UNSIGNED,
    total_rows_returned BIGINT UNSIGNED,
    total_row_churn BIGINT UNSIGNED,
    pe_bin INT UNSIGNED,
    log_date DATE,
    INDEX idx_query_start_date (query_start_date),
    INDEX idx_user_id (user_id),
    INDEX idx_log_date (log_date)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(log_date)) (
    PARTITION p_old VALUES LESS THAN (TO_DAYS(NOW() - INTERVAL 6 MONTH)),
    PARTITION p_current VALUES LESS THAN (TO_DAYS(NOW() + INTERVAL 1 MONTH)),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Table Size History Tracking Table
CREATE TABLE IF NOT EXISTS admin.mariadb_tablesize_history (
    log_date DATE,
    table_owner VARCHAR(50),
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_name VARCHAR(128),
    node_number SMALLINT,
    partition_number SMALLINT,
    mb_count INT UNSIGNED,
    row_count BIGINT UNSIGNED,
    value_count BIGINT UNSIGNED,
    block_min_val BIGINT UNSIGNED,
    block_max_val BIGINT UNSIGNED,
    PRIMARY KEY (log_date, database_name, table_name, node_number, partition_number),
    INDEX idx_log_date (log_date)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(log_date)) (
    PARTITION p_old VALUES LESS THAN (TO_DAYS(NOW() - INTERVAL 6 MONTH)),
    PARTITION p_current VALUES LESS THAN (TO_DAYS(NOW() + INTERVAL 1 MONTH)),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Table Usage Tracking Table
CREATE TABLE IF NOT EXISTS admin.mariadb_tableusage (
    query_id BIGINT UNSIGNED,
    query_start_date DATE,
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_id INT UNSIGNED,
    table_name VARCHAR(128),
    log_date DATE,
    PRIMARY KEY (query_id, table_id),
    INDEX idx_query_start_date (query_start_date),
    INDEX idx_log_date (log_date)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(log_date)) (
    PARTITION p_old VALUES LESS THAN (TO_DAYS(NOW() - INTERVAL 6 MONTH)),
    PARTITION p_current VALUES LESS THAN (TO_DAYS(NOW() + INTERVAL 1 MONTH)),
    PARTITION p_future VALUES LESS THAN MAXVALUE
); 
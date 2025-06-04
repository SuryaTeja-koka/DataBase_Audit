-- File: redshift_monitoring_to_postgres.sql
-- Purpose: Replicate Redshift SVM/STM tables in RDS PostgreSQL and provide queries to analyze query performance,
--          including peak query execution times and logging of executed queries.
-- Notes: 
--   - Tables are adapted from Redshift to PostgreSQL syntax (e.g., removed Redshift-specific ENCODE, DISTSTYLE, DISTKEY, SORTKEY).
--   - Uses pg_stat_statements for query logging, assuming the extension is enabled.
--   - Handles duplicate key errors with ON CONFLICT and uses query_start_time for primary key granularity.
--   - Query 3 avoids pg_depend and uses query text parsing for table usage (approximation).
--   - Use DBeaver to execute these queries in your RDS PostgreSQL instance.
--   - Date: June 4, 2025, 12:52 PM PDT

-- Ensure the admin schema exists
CREATE SCHEMA IF NOT EXISTS admin;

-- Enable pg_stat_statements extension (run this once if not already enabled)
-- Note: Requires superuser privileges; contact your DBA if needed.
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Table 1: Query Performance Metrics Summary
-- Purpose: Store query execution details, mimicking Redshift's SVM tables
CREATE TABLE IF NOT EXISTS admin.redshift_qrylog_metrics_smry
(
    query_id BIGINT,
    query_start_date DATE,
    user_name VARCHAR(100),
    user_id INTEGER,
    db_name VARCHAR(32),
    query_text TEXT,
    query_type VARCHAR(15),
    queue_start_time TIMESTAMP WITHOUT TIME ZONE,
    class INTEGER,
    slots INTEGER,
    queue_seconds BIGINT,
    exec_seconds BIGINT,
    total_seconds BIGINT,
    gating_efficiency DOUBLE PRECISION,
    gating_bin INTEGER,
    aborted INTEGER,
    pid INTEGER,
    xid BIGINT,
    query_start_time TIMESTAMP WITHOUT TIME ZONE,
    query_start_min DOUBLE PRECISION,
    query_start_hour DOUBLE PRECISION,
    disk_based VARCHAR(1),
    rr_scan VARCHAR(1),
    delayed_scan VARCHAR(1),
    steps_count BIGINT,
    total_bytes_churn_gb BIGINT,
    max_mem_held_gb BIGINT,
    event VARCHAR(1024),
    slices_used BIGINT,
    query_cpu_time BIGINT,
    query_blocks_read BIGINT,
    query_execution_time BIGINT,
    burn_rate DOUBLE PRECISION,
    burn_rate_bin INTEGER,
    query_temp_blocks_to_disk BIGINT,
    segment_execution_time BIGINT,
    cpu_skew NUMERIC(38,2),
    parallel_efficiency NUMERIC(38,33),
    parallel_efficiency_disk NUMERIC(38,33),
    effective_cpu NUMERIC(38,2),
    skew_overhead NUMERIC(38,2),
    scan_row_count BIGINT,
    join_row_count BIGINT,
    nested_loop_join_row_count BIGINT,
    total_rows_returned BIGINT,
    total_row_churn BIGINT,
    pe_bin INTEGER,
    log_date DATE,
    PRIMARY KEY (query_id, query_start_time)
);

-- Table 2: Table Size History Tracking
-- Purpose: Track table size and distribution, mimicking Redshift's STM tables
CREATE TABLE IF NOT EXISTS admin.redshift_tablesize_history
(
    log_date DATE,
    table_owner VARCHAR(50),
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_name VARCHAR(128),
    node_number SMALLINT,
    slice_number SMALLINT,
    mb_count INTEGER,
    row_count BIGINT,
    value_count BIGINT,
    block_min_val BIGINT,
    block_max_val BIGINT,
    PRIMARY KEY (log_date, database_name, schema_name, table_name)
);

-- Table 3: Table Usage Tracking
-- Purpose: Track which tables are accessed by queries
CREATE TABLE IF NOT EXISTS admin.redshift_tableusage
(
    query_id BIGINT,
    query_start_date DATE,
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    table_id INTEGER,
    table_name VARCHAR(128),
    log_date DATE,
    PRIMARY KEY (query_id, query_start_date, table_id)
);

-- Query 1: Populate Query Performance Metrics from pg_stat_statements
-- Purpose: Log query performance details into redshift_qrylog_metrics_smry
INSERT INTO admin.redshift_qrylog_metrics_smry
(
    query_id,
    query_start_date,
    user_name,
    user_id,
    db_name,
    query_text,
    query_start_time,
    query_execution_time,
    query_cpu_time,
    query_blocks_read,
    total_rows_returned,
    log_date
)
SELECT 
    pss.queryid AS query_id,
    CURRENT_DATE AS query_start_date,
    r.rolname AS user_name,
    pss.userid AS user_id,
    d.datname AS db_name,
    pss.query AS query_text,
    CURRENT_TIMESTAMP AS query_start_time,
    pss.total_exec_time AS query_execution_time,
    pss.total_exec_time * 1000 AS query_cpu_time, -- Convert ms to approximate CPU time
    pss.shared_blks_read AS query_blocks_read,
    pss.rows AS total_rows_returned,
    CURRENT_DATE AS log_date
FROM pg_stat_statements pss
JOIN pg_roles r ON pss.userid = r.oid
JOIN pg_database d ON pss.dbid = d.oid
WHERE pss.query NOT LIKE '%pg_stat_statements%'
  AND pss.query NOT LIKE '%redshift_qrylog_metrics_smry%'
ON CONFLICT (query_id, query_start_time) DO NOTHING;

-- Query 2: Populate Table Size History
-- Purpose: Log table size and row counts, mimicking Redshift's STM table behavior
INSERT INTO admin.redshift_tablesize_history
(
    log_date,
    table_owner,
    database_name,
    schema_name,
    table_name,
    mb_count,
    row_count
)
SELECT 
    CURRENT_DATE AS log_date,
    r.rolname AS table_owner,
    d.datname AS database_name,
    n.nspname AS schema_name,
    c.relname AS table_name,
    (pg_total_relation_size(c.oid) / 1024 / 1024)::INTEGER AS mb_count, -- Size in MB
    c.reltuples::BIGINT AS row_count
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_roles r ON c.relowner = r.oid
JOIN pg_database d ON d.oid = CURRENT_DATABASE()
WHERE c.relkind = 'r' -- Regular tables only
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ON CONFLICT (log_date, database_name, schema_name, table_name) DO NOTHING;

-- Query 3: Populate Table Usage
-- Purpose: Log which tables are accessed by queries, using query text parsing
INSERT INTO admin.redshift_tableusage
(
    query_id,
    query_start_date,
    database_name,
    schema_name,
    table_id,
    table_name,
    log_date
)
SELECT DISTINCT
    pss.queryid AS query_id,
    CURRENT_DATE AS query_start_date,
    d.datname AS database_name,
    n.nspname AS schema_name,
    c.oid::INTEGER AS table_id,
    c.relname AS table_name,
    CURRENT_DATE AS log_date
FROM pg_stat_statements pss
JOIN pg_database d ON pss.dbid = d.oid
CROSS JOIN pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND pss.query NOT LIKE '%pg_stat_statements%'
  AND pss.query NOT LIKE '%redshift_tableusage%'
  AND pss.query ILIKE '%' || c.relname || '%' -- Approximate table usage by matching table name in query text
ON CONFLICT (query_id, query_start_date, table_id) DO NOTHING;

-- Query 4: Analyze Peak Query Execution Times
-- Purpose: Identify the time of day with the most concurrent queries
SELECT 
    DATE_TRUNC('hour', query_start_time) AS query_hour,
    COUNT(*) AS query_count,
    STRING_AGG(query_text, '; ') AS sample_queries
FROM admin.redshift_qrylog_metrics_smry
WHERE query_start_date = CURRENT_DATE
GROUP BY DATE_TRUNC('hour', query_start_time)
ORDER BY query_count DESC
LIMIT 5;

-- Query 5: Log All Executed Queries
-- Purpose: Retrieve and log all queries that have run on the server
SELECT 
    query_id,
    query_start_time,
    user_name,
    db_name,
    query_text,
    query_execution_time,
    total_rows_returned
FROM admin.redshift_qrylog_metrics_smry
WHERE query_start_date = CURRENT_DATE
ORDER BY query_start_time DESC;

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_qrylog_query_start_time ON admin.redshift_qrylog_metrics_smry (query_start_time);
CREATE INDEX IF NOT EXISTS idx_tablesize_log_date ON admin.redshift_tablesize_history (log_date);
CREATE INDEX IF NOT EXISTS idx_tableusage_query_id ON admin.redshift_tableusage (query_id);

-- Comments for Documentation
COMMENT ON TABLE admin.redshift_qrylog_metrics_smry IS 'Stores query performance metrics, mimicking Redshift SVM tables';
COMMENT ON TABLE admin.redshift_tablesize_history IS 'Tracks table size and row counts, mimicking Redshift STM tables';
COMMENT ON TABLE admin.redshift_tableusage IS 'Logs table usage by queries, mimicking Redshift table access tracking';
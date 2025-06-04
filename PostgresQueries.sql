-- =====================================================================
-- PostgreSQL Compute Usage Metrics - Complete Monitoring Suite
-- =====================================================================
-- 
-- This file contains a comprehensive set of SQL queries for monitoring
-- PostgreSQL compute usage, performance, and resource utilization.
-- All queries use built-in PostgreSQL system views and catalogs.
--
-- Author: PostgreSQL Monitoring Suite
-- Compatible with: PostgreSQL 9.4+
-- Dependencies: None (uses only built-in system views)
--
-- Usage Instructions:
-- 1. Run individual sections as needed for specific monitoring
-- 2. Create views from these queries for dashboard integration
-- 3. Schedule regular execution for trend analysis
-- 4. Adjust LIMIT clauses based on your system size
--
-- Performance Impact: These queries are read-only and generally lightweight,
-- but some may take longer on systems with many tables/databases.
-- =====================================================================

-- =====================================================================
-- SECTION 1: CONNECTION AND SESSION MONITORING
-- =====================================================================

-- 1.1 Current Database Connections by State
-- Purpose: Monitor connection pool usage and identify connection leaks
-- Frequency: Real-time monitoring recommended
SELECT 
    datname AS database_name,
    state AS connection_state,
    COUNT(*) AS connection_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM pg_stat_activity 
WHERE state IS NOT NULL
GROUP BY datname, state
ORDER BY datname, connection_count DESC;

-- 1.2 Active Queries with Runtime
-- Purpose: Identify long-running queries that may be consuming resources
-- Frequency: Monitor every 1-5 minutes
SELECT 
    pid AS process_id,
    usename AS username,
    datname AS database_name,
    state AS query_state,
    query_start,
    now() - query_start AS runtime,
    CASE 
        WHEN now() - query_start > interval '5 minutes' THEN 'LONG_RUNNING'
        WHEN now() - query_start > interval '1 minute' THEN 'MODERATE'
        ELSE 'NORMAL'
    END AS runtime_category,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity 
WHERE state = 'active' 
    AND query NOT LIKE '%pg_stat_activity%'
    AND pid != pg_backend_pid()
ORDER BY runtime DESC;

-- 1.3 Connection Summary by User and Database
-- Purpose: Analyze connection patterns and user activity
SELECT 
    usename AS username,
    datname AS database_name,
    COUNT(*) AS total_connections,
    COUNT(CASE WHEN state = 'active' THEN 1 END) AS active_connections,
    COUNT(CASE WHEN state = 'idle' THEN 1 END) AS idle_connections,
    COUNT(CASE WHEN state = 'idle in transaction' THEN 1 END) AS idle_in_transaction
FROM pg_stat_activity
WHERE usename IS NOT NULL
GROUP BY usename, datname
ORDER BY total_connections DESC;

-- =====================================================================
-- SECTION 2: DATABASE SIZE AND STORAGE METRICS
-- =====================================================================

-- 2.1 Database Sizes with Growth Indicators
-- Purpose: Monitor database growth and storage consumption
-- Frequency: Daily monitoring recommended
SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS formatted_size,
    pg_database_size(datname) AS size_bytes,
    ROUND(
        100.0 * pg_database_size(datname) / 
        SUM(pg_database_size(datname)) OVER (), 2
    ) AS size_percentage
FROM pg_database 
WHERE datistemplate = false
    AND datname IS NOT NULL
ORDER BY pg_database_size(datname) DESC;

-- 2.2 Top Tables by Size (with Index Information)
-- Purpose: Identify largest tables and their index overhead
-- Frequency: Weekly monitoring recommended
SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS index_size,
    pg_total_relation_size(schemaname||'.'||tablename) AS total_bytes,
    ROUND(
        100.0 * pg_indexes_size(schemaname||'.'||tablename) / 
        NULLIF(pg_total_relation_size(schemaname||'.'||tablename), 0), 2
    ) AS index_ratio_percentage
FROM pg_tables 
WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 25;

-- 2.3 Schema-Level Storage Summary
-- Purpose: Storage usage breakdown by schema
SELECT 
    schemaname AS schema_name,
    COUNT(*) AS table_count,
    pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))) AS total_size,
    pg_size_pretty(SUM(pg_relation_size(schemaname||'.'||tablename))) AS table_size,
    pg_size_pretty(SUM(pg_indexes_size(schemaname||'.'||tablename))) AS index_size,
    SUM(pg_total_relation_size(schemaname||'.'||tablename)) AS total_bytes
FROM pg_tables 
WHERE schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
GROUP BY schemaname
ORDER BY total_bytes DESC;

-- =====================================================================
-- SECTION 3: CACHE PERFORMANCE AND HIT RATIOS
-- =====================================================================

-- 3.1 Buffer Cache Hit Ratios (Overall)
-- Purpose: Monitor memory efficiency and cache performance
-- Frequency: Continuous monitoring recommended
-- Target: >95% for both table and index cache hit ratios
SELECT 
    'table_cache_hit_ratio' AS metric,
    ROUND(
        100.0 * SUM(heap_blks_hit) / 
        NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2
    ) AS hit_ratio_percentage,
    SUM(heap_blks_hit) AS cache_hits,
    SUM(heap_blks_read) AS disk_reads
FROM pg_statio_user_tables

UNION ALL

SELECT 
    'index_cache_hit_ratio' AS metric,
    ROUND(
        100.0 * SUM(idx_blks_hit) / 
        NULLIF(SUM(idx_blks_hit) + SUM(idx_blks_read), 0), 2
    ) AS hit_ratio_percentage,
    SUM(idx_blks_hit) AS cache_hits,
    SUM(idx_blks_read) AS disk_reads
FROM pg_statio_user_indexes;

-- 3.2 Per-Table Cache Performance
-- Purpose: Identify tables with poor cache performance
-- Frequency: Weekly analysis recommended
SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    heap_blks_read AS table_disk_reads,
    heap_blks_hit AS table_cache_hits,
    idx_blks_read AS index_disk_reads,
    idx_blks_hit AS index_cache_hits,
    ROUND(
        100.0 * heap_blks_hit / 
        NULLIF(heap_blks_hit + heap_blks_read, 0), 2
    ) AS table_hit_ratio,
    ROUND(
        100.0 * idx_blks_hit / 
        NULLIF(idx_blks_hit + idx_blks_read, 0), 2
    ) AS index_hit_ratio,
    ROUND(
        100.0 * (heap_blks_hit + idx_blks_hit) / 
        NULLIF(heap_blks_hit + idx_blks_hit + heap_blks_read + idx_blks_read, 0), 2
    ) AS total_hit_ratio
FROM pg_statio_user_tables
WHERE heap_blks_read + idx_blks_read > 100  -- Filter out low-activity tables
ORDER BY (heap_blks_read + idx_blks_read) DESC
LIMIT 20;

-- =====================================================================
-- SECTION 4: DATABASE ACTIVITY AND TRANSACTION STATISTICS
-- =====================================================================

-- 4.1 Database-Level Activity Statistics
-- Purpose: Monitor transaction rates and database activity patterns
-- Frequency: Regular monitoring (every 5-15 minutes)
SELECT 
    datname AS database_name,
    numbackends AS active_connections,
    xact_commit AS transactions_committed,
    xact_rollback AS transactions_rolled_back,
    ROUND(
        100.0 * xact_rollback / 
        NULLIF(xact_commit + xact_rollback, 0), 2
    ) AS rollback_ratio_percentage,
    blks_read AS disk_blocks_read,
    blks_hit AS buffer_blocks_hit,
    ROUND(
        100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2
    ) AS cache_hit_ratio,
    tup_returned AS tuples_returned,
    tup_fetched AS tuples_fetched,
    tup_inserted AS tuples_inserted,
    tup_updated AS tuples_updated,
    tup_deleted AS tuples_deleted,
    ROUND((tup_inserted + tup_updated + tup_deleted)::numeric / 
          NULLIF(xact_commit, 0), 2) AS avg_dml_per_transaction
FROM pg_stat_database 
WHERE datname IS NOT NULL
    AND datname NOT IN ('template0', 'template1')
ORDER BY numbackends DESC;

-- 4.2 Most Active Tables (DML Operations)
-- Purpose: Identify tables with highest write activity
-- Frequency: Daily monitoring recommended
SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    seq_scan AS sequential_scans,
    seq_tup_read AS seq_tuples_read,
    idx_scan AS index_scans,
    idx_tup_fetch AS index_tuples_fetched,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    n_tup_ins + n_tup_upd + n_tup_del AS total_dml_operations,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(
        100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2
    ) AS dead_tuple_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC
LIMIT 20;

-- 4.3 Index Usage Statistics
-- Purpose: Identify unused or underutilized indexes
-- Frequency: Weekly analysis recommended
SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    indexname AS index_name,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) AS index_size,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 10 THEN 'LOW_USAGE'
        WHEN idx_scan < 100 THEN 'MODERATE_USAGE'
        ELSE 'HIGH_USAGE'
    END AS usage_category
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(schemaname||'.'||indexname) DESC;

-- =====================================================================
-- SECTION 5: LOCK MONITORING AND CONTENTION ANALYSIS
-- =====================================================================

-- 5.1 Current Lock Status
-- Purpose: Monitor lock contention and blocking sessions
-- Frequency: Real-time monitoring for production systems
SELECT 
    pl.pid AS process_id,
    pa.usename AS username,
    pa.datname AS database_name,
    pl.mode AS lock_mode,
    pl.locktype AS lock_type,
    COALESCE(pl.relation::regclass::text, pl.locktype) AS locked_object,
    pa.query_start,
    now() - pa.query_start AS lock_duration,
    pa.state AS session_state,
    CASE 
        WHEN pl.granted THEN 'GRANTED'
        ELSE 'WAITING'
    END AS lock_status,
    LEFT(pa.query, 100) AS current_query
FROM pg_locks pl
LEFT JOIN pg_stat_activity pa ON pl.pid = pa.pid
WHERE pa.state IS NOT NULL
    AND pa.pid != pg_backend_pid()
ORDER BY 
    CASE WHEN pl.granted THEN 1 ELSE 0 END,  -- Show waiting locks first
    now() - pa.query_start DESC NULLS LAST;

-- 5.2 Lock Conflicts and Blocking Relationships
-- Purpose: Identify blocking sessions and lock chains
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocked_activity.query AS blocked_statement,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocking_activity.query AS blocking_statement,
    blocked_activity.application_name AS blocked_application
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity 
    ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity 
    ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- =====================================================================
-- SECTION 6: LONG-RUNNING OPERATIONS MONITORING
-- =====================================================================

-- 6.1 Long-Running Transactions and Queries
-- Purpose: Identify potentially problematic long-running operations
-- Frequency: Continuous monitoring recommended
-- Thresholds: Adjust intervals based on your application requirements
SELECT 
    pid AS process_id,
    usename AS username,
    datname AS database_name,
    application_name,
    client_addr AS client_address,
    state AS session_state,
    xact_start AS transaction_start,
    query_start,
    state_change,
    CASE 
        WHEN xact_start IS NOT NULL THEN now() - xact_start 
        ELSE NULL 
    END AS transaction_duration,
    now() - query_start AS query_duration,
    CASE 
        WHEN state = 'idle in transaction' AND now() - state_change > interval '10 minutes' 
            THEN 'CRITICAL_IDLE_IN_TRANSACTION'
        WHEN xact_start IS NOT NULL AND now() - xact_start > interval '30 minutes' 
            THEN 'CRITICAL_LONG_TRANSACTION'
        WHEN now() - query_start > interval '10 minutes' 
            THEN 'LONG_RUNNING_QUERY'
        WHEN state = 'idle in transaction' AND now() - state_change > interval '5 minutes' 
            THEN 'WARNING_IDLE_IN_TRANSACTION'
        ELSE 'NORMAL'
    END AS severity_level,
    LEFT(query, 200) AS current_query
FROM pg_stat_activity 
WHERE state != 'idle'
    AND pid != pg_backend_pid()
    AND (
        (xact_start IS NOT NULL AND now() - xact_start > interval '1 minute') OR
        (query_start IS NOT NULL AND now() - query_start > interval '30 seconds') OR
        (state = 'idle in transaction' AND now() - state_change > interval '5 minutes')
    )
ORDER BY 
    CASE 
        WHEN state = 'idle in transaction' THEN 1
        ELSE 2
    END,
    COALESCE(now() - xact_start, interval '0') DESC,
    now() - query_start DESC;

-- =====================================================================
-- SECTION 7: SYSTEM RESOURCE UTILIZATION SUMMARY
-- =====================================================================

-- 7.1 Overall System Resource Summary
-- Purpose: High-level system health overview
-- Frequency: Dashboard display, updated every 1-5 minutes
SELECT 
    'total_connections' AS metric,
    COUNT(*)::text AS value,
    'connections' AS unit
FROM pg_stat_activity
WHERE pid != pg_backend_pid()

UNION ALL

SELECT 
    'active_connections' AS metric,
    COUNT(*)::text AS value,
    'connections' AS unit
FROM pg_stat_activity 
WHERE state = 'active'
    AND pid != pg_backend_pid()

UNION ALL

SELECT 
    'idle_in_transaction' AS metric,
    COUNT(*)::text AS value,
    'connections' AS unit
FROM pg_stat_activity 
WHERE state = 'idle in transaction'

UNION ALL

SELECT 
    'long_running_queries' AS metric,
    COUNT(*)::text AS value,
    'queries' AS unit
FROM pg_stat_activity 
WHERE state = 'active'
    AND now() - query_start > interval '5 minutes'
    AND pid != pg_backend_pid()

UNION ALL

SELECT 
    'total_databases' AS metric,
    COUNT(*)::text AS value,
    'databases' AS unit
FROM pg_database 
WHERE datistemplate = false

UNION ALL

SELECT 
    'total_size_gb' AS metric,
    ROUND(SUM(pg_database_size(datname))::numeric / 1024 / 1024 / 1024, 2)::text AS value,
    'GB' AS unit
FROM pg_database 
WHERE datistemplate = false

ORDER BY 
    CASE metric
        WHEN 'total_connections' THEN 1
        WHEN 'active_connections' THEN 2
        WHEN 'idle_in_transaction' THEN 3
        WHEN 'long_running_queries' THEN 4
        WHEN 'total_databases' THEN 5
        WHEN 'total_size_gb' THEN 6
    END;

-- 7.2 Background Writer and Checkpoint Statistics
-- Purpose: Monitor background process efficiency and I/O patterns
-- Frequency: Every 15-30 minutes
SELECT 
    'checkpoints_timed' AS metric,
    checkpoints_timed AS value,
    'Scheduled checkpoints' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'checkpoints_requested' AS metric,
    checkpoints_req AS value,
    'Requested checkpoints (may indicate heavy write load)' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'checkpoint_write_time_ms' AS metric,
    checkpoint_write_time AS value,
    'Time spent writing checkpoint files' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'checkpoint_sync_time_ms' AS metric,
    checkpoint_sync_time AS value,
    'Time spent syncing checkpoint files' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'buffers_checkpoint' AS metric,
    buffers_checkpoint AS value,
    'Buffers written during checkpoints' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'buffers_clean' AS metric,
    buffers_clean AS value,
    'Buffers written by background writer' AS description
FROM pg_stat_bgwriter

UNION ALL

SELECT 
    'buffers_backend' AS metric,
    buffers_backend AS value,
    'Buffers written directly by backends' AS description
FROM pg_stat_bgwriter

ORDER BY metric;

-- =====================================================================
-- SECTION 8: MAINTENANCE AND VACUUM STATISTICS
-- =====================================================================

-- 8.1 Table Maintenance Status
-- Purpose: Monitor vacuum and analyze operations
-- Frequency: Daily monitoring recommended
SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percentage,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    vacuum_count,
    autovacuum_count,
    analyze_count,
    autoanalyze_count,
    CASE 
        WHEN last_autovacuum IS NULL AND last_vacuum IS NULL THEN 'NEVER_VACUUMED'
        WHEN COALESCE(last_autovacuum, last_vacuum) < now() - interval '7 days' THEN 'OVERDUE_VACUUM'
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'HIGH_DEAD_TUPLES'
        ELSE 'NORMAL'
    END AS maintenance_status
FROM pg_stat_user_tables
WHERE n_live_tup + n_dead_tup > 1000  -- Filter out very small tables
ORDER BY 
    CASE 
        WHEN last_autovacuum IS NULL AND last_vacuum IS NULL THEN 1
        ELSE 2
    END,
    dead_tuple_percentage DESC NULLS LAST;

-- =====================================================================
-- PERFORMANCE TUNING RECOMMENDATIONS QUERY
-- =====================================================================

-- 8.2 Performance Insights and Recommendations
-- Purpose: Automated performance analysis and recommendations
-- Note: This is a diagnostic query that provides actionable insights
WITH connection_analysis AS (
    SELECT 
        COUNT(*) as total_connections,
        COUNT(CASE WHEN state = 'idle in transaction' THEN 1 END) as idle_in_tx,
        COUNT(CASE WHEN now() - query_start > interval '5 minutes' THEN 1 END) as long_queries
    FROM pg_stat_activity
    WHERE pid != pg_backend_pid()
),
cache_analysis AS (
    SELECT 
        ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0), 2) as table_hit_ratio,
        ROUND(100.0 * SUM(idx_blks_hit) / NULLIF(SUM(idx_blks_hit + idx_blks_read), 0), 2) as index_hit_ratio
    FROM pg_statio_user_tables t
    JOIN pg_statio_user_indexes i ON t.schemaname = i.schemaname AND t.tablename = i.tablename
),
size_analysis AS (
    SELECT 
        COUNT(*) as large_tables,
        SUM(pg_total_relation_size(schemaname||'.'||tablename)) as total_size
    FROM pg_tables 
    WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
        AND pg_total_relation_size(schemaname||'.'||tablename) > 1024*1024*100  -- >100MB
)
SELECT 
    'PERFORMANCE_ANALYSIS' as analysis_type,
    CASE 
        WHEN ca.table_hit_ratio < 90 THEN 'CRITICAL: Table cache hit ratio is ' || ca.table_hit_ratio || '%. Consider increasing shared_buffers.'
        WHEN ca.table_hit_ratio < 95 THEN 'WARNING: Table cache hit ratio is ' || ca.table_hit_ratio || '%. Monitor memory usage.'
        ELSE 'OK: Table cache hit ratio is ' || ca.table_hit_ratio || '%.'
    END as cache_recommendation,
    CASE 
        WHEN conn.idle_in_tx > 5 THEN 'CRITICAL: ' || conn.idle_in_tx || ' idle-in-transaction connections detected. Check application connection handling.'
        WHEN conn.idle_in_tx > 0 THEN 'WARNING: ' || conn.idle_in_tx || ' idle-in-transaction connections.'
        ELSE 'OK: No problematic idle-in-transaction connections.'
    END as connection_recommendation,
    CASE 
        WHEN conn.long_queries > 3 THEN 'WARNING: ' || conn.long_queries || ' long-running queries detected. Review query performance.'
        WHEN conn.long_queries > 0 THEN 'INFO: ' || conn.long_queries || ' long-running queries detected.'
        ELSE 'OK: No long-running queries detected.'
    END as query_recommendation,
    CASE 
        WHEN sa.large_tables > 50 THEN 'INFO: ' || sa.large_tables || ' large tables (>100MB) detected. Consider partitioning strategies.'
        ELSE 'OK: Table sizes are manageable.'
    END as storage_recommendation
FROM connection_analysis conn, cache_analysis ca, size_analysis sa;

-- =====================================================================
-- END OF MONITORING SUITE
-- =====================================================================
--
-- USAGE NOTES:
-- 1. These queries are designed to be non-intrusive and safe for production
-- 2. Some queries may take longer on very large databases - test first
-- 3. Consider creating views for frequently-used queries
-- 4. Set up alerting based on thresholds that make sense for your environment
-- 5. Regular execution of Section 8.2 provides automated performance insights
--
-- RECOMMENDED MONITORING FREQUENCIES:
-- - Real-time: Sections 1.1, 1.2, 5.1, 7.1
-- - Every 5 minutes: Sections 4.1, 6.1
-- - Every 15 minutes: Section 7.2
-- - Daily: Sections 2.1, 4.2, 8.1, 8.2
-- - Weekly: Sections 2.2, 3.2, 4.3
--
-- For automated monitoring, consider tools like pg_stat_monitor, 
-- pgBadger, or custom scripts that execute these queries regularly.
-- =====================================================================
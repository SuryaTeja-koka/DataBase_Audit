# Redshift Performance Monitoring Tables

This repository contains SQL schema definitions for creating essential monitoring tables in Amazon Redshift. These tables are designed to track query performance metrics, table sizes, and table usage patterns.

## Tables Overview

### 1. admin.redshift_qrylog_metrics_smry
A comprehensive table that stores detailed query performance metrics including:
- Query execution details (ID, start time, duration)
- Resource utilization (CPU, memory, disk)
- Performance metrics (parallel efficiency, skew, burn rate)
- Query characteristics (type, text, user information)

Key features:
- DISTSTYLE KEY with query as DISTKEY
- SORTKEY on query_start_date for efficient date-based queries
- Optimized column encodings for performance

### 2. admin.redshift_tablesize_history
Tracks historical table size information across the cluster:
- Table dimensions (size in MB, row count)
- Distribution across nodes and slices
- Value ranges and block statistics

Key features:
- DISTSTYLE EVEN for balanced distribution
- SORTKEY on log_date for temporal analysis
- Tracks table ownership and location

### 3. admin.redshift_tableusage
Records which tables are accessed by which queries:
- Links queries to their accessed tables
- Maintains database and schema context
- Tracks usage patterns over time

Key features:
- DISTSTYLE KEY with query as DISTKEY
- SORTKEY on query_start_date
- Optimized for query-table relationship analysis

## Usage

These tables are typically used for:
1. Query performance analysis and optimization
2. Resource utilization monitoring
3. Table growth tracking
4. Usage pattern analysis
5. Performance bottleneck identification

## Column Naming Convention

All columns follow these standards:
- Lowercase naming
- Words separated by underscores
- No spaces in names
- Clear and descriptive names (e.g., `user_name` instead of `usename`)

## Dependencies

- Amazon Redshift cluster
- Admin schema access
- Appropriate permissions to create tables

## Maintenance

Regular maintenance tasks:
1. Monitor table growth
2. Implement data retention policies
3. Review and update column encodings as needed
4. Analyze and optimize sort keys based on query patterns 
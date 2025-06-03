# Database Performance Monitoring Schemas

This repository contains SQL schema definitions for creating essential monitoring tables across different database systems. These schemas are designed to track query performance metrics, table sizes, and table usage patterns.

## Supported Database Systems

1. MySQL
2. PostgreSQL
3. Microsoft SQL Server
4. MariaDB
5. Oracle Database
6. SQLite
7. Amazon Redshift
8. SAP HANA
9. IBM Db2
10. CockroachDB

## Schema Structure

Each database system has three main monitoring tables:

### 1. Query Performance Metrics Summary Table
- Tracks detailed query execution metrics
- Captures resource utilization
- Records performance indicators
- Stores query characteristics

### 2. Table Size History Tracking Table
- Monitors table growth over time
- Tracks distribution across nodes/partitions
- Records size metrics (MB, rows, blocks)
- Maintains historical data

### 3. Table Usage Tracking Table
- Links queries to accessed tables
- Maintains database context
- Tracks usage patterns
- Records temporal information

## Common Features

All schemas include:
- Appropriate data types for each database system
- Optimized indexes for common query patterns
- Partitioning strategies for historical data
- Primary keys and constraints
- Consistent naming conventions

## Database-Specific Optimizations

Each schema is optimized for its respective database system:

### MySQL/MariaDB
- Uses InnoDB engine
- Implements partitioning by date
- Optimized for UTF-8 character sets

### PostgreSQL
- Uses native partitioning
- Implements appropriate indexes
- Optimized for JSON/JSONB if needed

### SQL Server
- Uses appropriate data types (NVARCHAR, DATETIME2)
- Implements clustered indexes
- Optimized for Windows environments

### Oracle
- Uses NUMBER type for numeric values
- Implements range partitioning
- Optimized for enterprise workloads

### SQLite
- Uses TEXT for dates (no native DATE type)
- Implements appropriate indexes
- Optimized for embedded use

### SAP HANA
- Uses NVARCHAR for Unicode support
- Implements column store optimizations
- Optimized for in-memory operations

### IBM Db2
- Uses appropriate data types
- Implements range partitioning
- Optimized for enterprise workloads

### CockroachDB
- Uses STRING type for text
- Implements range partitioning
- Optimized for distributed operations

## Usage

1. Choose the appropriate schema for your database system
2. Create the admin schema if it doesn't exist
3. Execute the schema creation script
4. Set up appropriate permissions
5. Configure data retention policies

## Maintenance

Regular maintenance tasks:
1. Monitor table growth
2. Implement data retention policies
3. Review and update indexes
4. Analyze and optimize partitions
5. Clean up old data

## Best Practices

1. Regularly review and update the schemas
2. Monitor performance impact
3. Implement appropriate backup strategies
4. Set up automated maintenance jobs
5. Document any custom modifications 
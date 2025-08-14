# MySQL to PostgreSQL Migration Process

## Quick Start

1. **Prepare your environment:**
   ```bash
   # Install required tools
   pip3 install psycopg2-binary
   
   # Set environment variables
   export MYSQL_HOST=localhost
   export MYSQL_USER=root
   export MYSQL_PASSWORD=your_password
   export MYSQL_DB=your_database
   
   export POSTGRES_HOST=localhost
   export POSTGRES_USER=postgres
   export POSTGRES_PASSWORD=your_password
   export POSTGRES_DB=your_database
   ```

2. **Run the migration:**
   ```bash
   cd db/migration_scripts
   ./migrate.sh
   ```

## Detailed Steps

### Phase 1: Pre-Migration (1-2 weeks)

1. **Assessment and Planning**
   - Review existing MySQL schema using provided documentation
   - Identify MySQL-specific features that need conversion
   - Plan testing strategy
   - Set up PostgreSQL development environment

2. **Schema Conversion**
   - Use the provided PostgreSQL schema as a reference
   - Convert MySQL data types to PostgreSQL equivalents
   - Update auto-increment columns to use SERIAL or IDENTITY
   - Convert CHECK constraints and triggers

3. **Application Code Review**
   - Identify SQL queries that need modification
   - Update database drivers and connection strings
   - Test with PostgreSQL-specific features (JSONB, arrays, etc.)

### Phase 2: Data Migration (1 week)

1. **Export MySQL Data**
   ```bash
   mysqldump --single-transaction --routines --triggers --databases your_db > mysql_dump.sql
   ```

2. **Convert Data Format**
   ```bash
   python3 mysql_to_postgresql.py mysql_dump.sql postgres_dump.sql
   ```

3. **Import to PostgreSQL**
   ```bash
   psql -h localhost -U postgres -d your_db -f postgres_dump.sql
   ```

4. **Verify Data Integrity**
   - Compare row counts between MySQL and PostgreSQL
   - Validate data types and constraints
   - Test application functionality

### Phase 3: Application Updates (2-3 weeks)

1. **Update Database Configuration**
   - Choose appropriate config file for your framework:
     - `config/database.yml` for Ruby on Rails
     - `config/database.js` for Node.js
     - `config/database.py` for Python/Django

2. **Test Application**
   - Run full test suite
   - Perform load testing
   - Validate all features work correctly

3. **Performance Optimization**
   - Create appropriate indexes
   - Tune PostgreSQL configuration
   - Monitor query performance

### Phase 4: Production Migration (Planned downtime)

1. **Final Data Sync**
   - Stop application traffic
   - Export final MySQL data
   - Import to PostgreSQL
   - Update sequences

2. **Switch Application**
   - Update database configuration
   - Start application with PostgreSQL
   - Monitor for issues

3. **Post-Migration**
   - Verify all systems working
   - Monitor performance
   - Keep MySQL backup for rollback if needed

## Key Benefits Achieved

### Better JSON Support
PostgreSQL's JSONB provides:
- Native JSON operations and indexing
- Better performance than MySQL's JSON type
- Rich query capabilities with operators like `->`, `->>`, `?`, `@>`

Example usage:
```sql
-- Query users with specific profile attributes
SELECT * FROM users WHERE profile->>'role' = 'admin';

-- Index JSON data for better performance
CREATE INDEX idx_users_profile_role ON users USING GIN((profile->>'role'));
```

### Performance Improvements
- Advanced query optimizer
- Parallel query execution
- Better memory management
- More efficient indexing strategies

### Licensing Benefits
- PostgreSQL uses a permissive BSD-style license
- No licensing fees or restrictions
- Strong open-source community support

## Troubleshooting

### Common Issues

1. **Character encoding problems**
   - Ensure UTF-8 encoding in both databases
   - Use `--default-character-set=utf8` with mysqldump

2. **Date/time format differences**
   - PostgreSQL is stricter with date formats
   - Update application code to use ISO format

3. **Auto-increment sequence issues**
   - Use the sequence update script in migrate.sh
   - Manually set sequence values if needed

4. **Case sensitivity**
   - PostgreSQL is case-sensitive for identifiers
   - Use quotes around mixed-case names

### Performance Tuning

1. **PostgreSQL Configuration**
   ```bash
   # postgresql.conf suggestions
   shared_buffers = 256MB
   effective_cache_size = 1GB
   work_mem = 4MB
   maintenance_work_mem = 64MB
   ```

2. **Index Optimization**
   - Create GIN indexes for JSONB columns
   - Use partial indexes for filtered queries
   - Monitor slow queries with pg_stat_statements

## Rollback Plan

If issues arise during migration:

1. **Immediate Rollback**
   - Switch application back to MySQL
   - Verify MySQL data integrity
   - Investigate PostgreSQL issues

2. **Data Recovery**
   - MySQL backup is maintained during migration
   - All original data is preserved
   - No data loss during rollback

## Support and Maintenance

- Monitor PostgreSQL logs for performance issues
- Regular VACUUM and ANALYZE operations
- Keep PostgreSQL updated with security patches
- Use pg_stat_statements for query analysis

For questions or issues, refer to:
- PostgreSQL documentation: https://www.postgresql.org/docs/
- Migration troubleshooting guide above
- Database team or DBA for production issues
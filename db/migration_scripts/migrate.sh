#!/bin/bash

# MySQL to PostgreSQL Migration Script
# This script orchestrates the complete migration process

set -e  # Exit on any error

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DB="${MYSQL_DB:-myapp}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-myapp}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
MYSQL_DUMP_FILE="$BACKUP_DIR/mysql_dump.sql"
POSTGRES_DUMP_FILE="$BACKUP_DIR/postgres_dump.sql"

echo "Starting MySQL to PostgreSQL migration..."
echo "Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Step 1: Export MySQL data
echo "Step 1: Exporting MySQL data..."
mysqldump \
    --host="$MYSQL_HOST" \
    --port="$MYSQL_PORT" \
    --user="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --databases "$MYSQL_DB" > "$MYSQL_DUMP_FILE"

echo "MySQL dump completed: $MYSQL_DUMP_FILE"

# Step 2: Convert MySQL dump to PostgreSQL format
echo "Step 2: Converting MySQL dump to PostgreSQL format..."
python3 mysql_to_postgresql.py "$MYSQL_DUMP_FILE" "$POSTGRES_DUMP_FILE"

echo "Conversion completed: $POSTGRES_DUMP_FILE"

# Step 3: Create PostgreSQL database
echo "Step 3: Creating PostgreSQL database..."
PGPASSWORD="$POSTGRES_PASSWORD" createdb \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --username="$POSTGRES_USER" \
    "$POSTGRES_DB" || echo "Database already exists or creation failed"

# Step 4: Import converted data to PostgreSQL
echo "Step 4: Importing data to PostgreSQL..."
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --file="$POSTGRES_DUMP_FILE"

echo "PostgreSQL import completed"

# Step 5: Update sequences (for SERIAL columns)
echo "Step 5: Updating PostgreSQL sequences..."
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --command="
    DO \$\$
    DECLARE
        seq_record RECORD;
        max_id INTEGER;
    BEGIN
        FOR seq_record IN
            SELECT schemaname, sequencename, tablename, columnname
            FROM pg_sequences
            JOIN information_schema.columns ON 
                column_default LIKE 'nextval(%' || sequencename || '%'
        LOOP
            EXECUTE format('SELECT COALESCE(MAX(%I), 0) + 1 FROM %I.%I', 
                          seq_record.columnname, 
                          seq_record.schemaname, 
                          seq_record.tablename) INTO max_id;
            EXECUTE format('ALTER SEQUENCE %I.%I RESTART WITH %s', 
                          seq_record.schemaname, 
                          seq_record.sequencename, 
                          max_id);
        END LOOP;
    END
    \$\$;"

echo "Sequences updated"

# Step 6: Verify migration
echo "Step 6: Verifying migration..."
echo "Checking table counts..."

# Get MySQL table counts
mysql \
    --host="$MYSQL_HOST" \
    --port="$MYSQL_PORT" \
    --user="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --database="$MYSQL_DB" \
    --execute="
    SELECT 
        table_name,
        table_rows as row_count
    FROM information_schema.tables 
    WHERE table_schema = '$MYSQL_DB' 
    AND table_type = 'BASE TABLE';" > "$BACKUP_DIR/mysql_counts.txt"

# Get PostgreSQL table counts
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --command="
    SELECT 
        schemaname,
        tablename,
        n_tup_ins - n_tup_del as row_count
    FROM pg_stat_user_tables;" > "$BACKUP_DIR/postgres_counts.txt"

echo "Migration verification files created:"
echo "  MySQL counts: $BACKUP_DIR/mysql_counts.txt"
echo "  PostgreSQL counts: $BACKUP_DIR/postgres_counts.txt"

echo ""
echo "Migration completed successfully!"
echo "Please review the verification files and test your application."
echo "Backup files are stored in: $BACKUP_DIR"
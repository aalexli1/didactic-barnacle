#!/usr/bin/env python3
"""
MySQL to PostgreSQL Migration Script

This script handles the conversion of MySQL data to PostgreSQL format,
including data type conversions and schema transformations.
"""

import json
import re
import sys
from typing import Dict, List, Any
import argparse
from datetime import datetime


class MySQLToPostgreSQLConverter:
    """Converts MySQL schema and data to PostgreSQL format"""
    
    def __init__(self):
        self.type_mapping = {
            'INT': 'INTEGER',
            'BIGINT': 'BIGINT',
            'SMALLINT': 'SMALLINT',
            'TINYINT': 'SMALLINT',
            'MEDIUMINT': 'INTEGER',
            'FLOAT': 'REAL',
            'DOUBLE': 'DOUBLE PRECISION',
            'DECIMAL': 'DECIMAL',
            'NUMERIC': 'NUMERIC',
            'CHAR': 'CHAR',
            'VARCHAR': 'VARCHAR',
            'TEXT': 'TEXT',
            'MEDIUMTEXT': 'TEXT',
            'LONGTEXT': 'TEXT',
            'TINYTEXT': 'TEXT',
            'BLOB': 'BYTEA',
            'MEDIUMBLOB': 'BYTEA',
            'LONGBLOB': 'BYTEA',
            'TINYBLOB': 'BYTEA',
            'DATE': 'DATE',
            'TIME': 'TIME',
            'DATETIME': 'TIMESTAMP',
            'TIMESTAMP': 'TIMESTAMP WITH TIME ZONE',
            'YEAR': 'INTEGER',
            'JSON': 'JSONB',
            'BOOLEAN': 'BOOLEAN',
            'BOOL': 'BOOLEAN'
        }
    
    def convert_data_type(self, mysql_type: str) -> str:
        """Convert MySQL data type to PostgreSQL equivalent"""
        # Handle AUTO_INCREMENT
        if 'AUTO_INCREMENT' in mysql_type.upper():
            if 'BIGINT' in mysql_type.upper():
                return 'BIGSERIAL'
            else:
                return 'SERIAL'
        
        # Extract base type
        base_type = re.match(r'(\w+)', mysql_type.upper()).group(1)
        
        # Get PostgreSQL equivalent
        pg_type = self.type_mapping.get(base_type, mysql_type)
        
        # Preserve size specifications for VARCHAR, CHAR, etc.
        size_match = re.search(r'\((\d+)\)', mysql_type)
        if size_match and pg_type in ['VARCHAR', 'CHAR']:
            pg_type += f'({size_match.group(1)})'
        
        return pg_type
    
    def convert_create_table(self, mysql_ddl: str) -> str:
        """Convert MySQL CREATE TABLE statement to PostgreSQL"""
        lines = mysql_ddl.split('\n')
        pg_lines = []
        
        for line in lines:
            line = line.strip()
            
            # Skip MySQL-specific options
            if any(keyword in line.upper() for keyword in [
                'ENGINE=', 'CHARSET=', 'COLLATE=', 'AUTO_INCREMENT='
            ]):
                continue
            
            # Convert data types
            if re.match(r'^\w+\s+', line):  # Column definition
                parts = line.split()
                if len(parts) >= 2:
                    column_name = parts[0]
                    mysql_type = parts[1]
                    pg_type = self.convert_data_type(mysql_type)
                    
                    # Rebuild line with PostgreSQL type
                    new_line = f"{column_name} {pg_type}"
                    
                    # Add constraints
                    if 'NOT NULL' in line.upper():
                        new_line += ' NOT NULL'
                    if 'DEFAULT' in line.upper():
                        default_match = re.search(r'DEFAULT\s+([^,\s]+)', line, re.IGNORECASE)
                        if default_match:
                            default_val = default_match.group(1)
                            # Convert MySQL-specific defaults
                            if default_val.upper() == 'CURRENT_TIMESTAMP':
                                default_val = 'CURRENT_TIMESTAMP'
                            new_line += f' DEFAULT {default_val}'
                    
                    line = new_line
            
            # Convert PRIMARY KEY with AUTO_INCREMENT
            if 'PRIMARY KEY' in line.upper() and 'AUTO_INCREMENT' in mysql_ddl.upper():
                line = line.replace('AUTO_INCREMENT', '')
            
            pg_lines.append(line)
        
        return '\n'.join(pg_lines)
    
    def convert_insert_data(self, mysql_insert: str) -> str:
        """Convert MySQL INSERT statement to PostgreSQL format"""
        # Handle MySQL-specific syntax
        pg_insert = mysql_insert
        
        # Replace MySQL quotes with PostgreSQL standard
        pg_insert = re.sub(r'`([^`]+)`', r'"\1"', pg_insert)
        
        # Handle boolean values
        pg_insert = re.sub(r'\b1\b', 'TRUE', pg_insert)
        pg_insert = re.sub(r'\b0\b', 'FALSE', pg_insert)
        
        return pg_insert
    
    def generate_migration_sql(self, mysql_dump_file: str, output_file: str):
        """Generate PostgreSQL-compatible SQL from MySQL dump"""
        with open(mysql_dump_file, 'r') as f:
            mysql_content = f.read()
        
        pg_content = []
        pg_content.append("-- Converted from MySQL to PostgreSQL")
        pg_content.append("-- Generated at: " + datetime.now().isoformat())
        pg_content.append("")
        
        # Process each statement
        statements = mysql_content.split(';')
        
        for statement in statements:
            statement = statement.strip()
            if not statement:
                continue
            
            if statement.upper().startswith('CREATE TABLE'):
                pg_statement = self.convert_create_table(statement)
                pg_content.append(pg_statement + ';')
                pg_content.append("")
            
            elif statement.upper().startswith('INSERT INTO'):
                pg_statement = self.convert_insert_data(statement)
                pg_content.append(pg_statement + ';')
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(pg_content))
        
        print(f"Migration SQL generated: {output_file}")


def main():
    parser = argparse.ArgumentParser(description='Convert MySQL dump to PostgreSQL')
    parser.add_argument('input_file', help='MySQL dump file')
    parser.add_argument('output_file', help='PostgreSQL output file')
    
    args = parser.parse_args()
    
    converter = MySQLToPostgreSQLConverter()
    converter.generate_migration_sql(args.input_file, args.output_file)


if __name__ == '__main__':
    main()
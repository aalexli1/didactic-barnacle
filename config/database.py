# Python Database Configuration Examples

import os
from urllib.parse import quote_plus

# Django Settings
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME', 'myapp'),
        'USER': os.environ.get('DATABASE_USER', 'postgres'),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD', ''),
        'HOST': os.environ.get('DATABASE_HOST', 'localhost'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
        'OPTIONS': {
            'connect_timeout': 10,
        },
        'CONN_MAX_AGE': 600,  # Connection pooling
    }
}

# SQLAlchemy Configuration
class DatabaseConfig:
    # Basic configuration
    SQLALCHEMY_DATABASE_URI = (
        f"postgresql://{os.environ.get('DATABASE_USER', 'postgres')}:"
        f"{quote_plus(os.environ.get('DATABASE_PASSWORD', ''))}@"
        f"{os.environ.get('DATABASE_HOST', 'localhost')}:"
        f"{os.environ.get('DATABASE_PORT', '5432')}/"
        f"{os.environ.get('DATABASE_NAME', 'myapp')}"
    )
    
    # Connection pool settings
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True,
        'max_overflow': 20,
        'connect_args': {
            'connect_timeout': 10,
            'application_name': 'myapp'
        }
    }
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False

# psycopg2 Direct Connection
import psycopg2
from psycopg2 import pool

class PostgreSQLConnection:
    def __init__(self):
        self.connection_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=1,
            maxconn=20,
            host=os.environ.get('DATABASE_HOST', 'localhost'),
            port=int(os.environ.get('DATABASE_PORT', 5432)),
            database=os.environ.get('DATABASE_NAME', 'myapp'),
            user=os.environ.get('DATABASE_USER', 'postgres'),
            password=os.environ.get('DATABASE_PASSWORD', ''),
            application_name='myapp'
        )
    
    def get_connection(self):
        return self.connection_pool.getconn()
    
    def return_connection(self, connection):
        self.connection_pool.putconn(connection)
    
    def close_all_connections(self):
        self.connection_pool.closeall()

# Asyncpg Configuration (for async applications)
ASYNCPG_CONFIG = {
    'host': os.environ.get('DATABASE_HOST', 'localhost'),
    'port': int(os.environ.get('DATABASE_PORT', 5432)),
    'database': os.environ.get('DATABASE_NAME', 'myapp'),
    'user': os.environ.get('DATABASE_USER', 'postgres'),
    'password': os.environ.get('DATABASE_PASSWORD', ''),
    'min_size': 5,
    'max_size': 20,
    'command_timeout': 30
}

# Environment-specific configurations
CONFIG_BY_ENV = {
    'development': {
        'host': 'localhost',
        'port': 5432,
        'database': 'myapp_development',
        'user': 'postgres',
        'password': os.environ.get('DATABASE_PASSWORD', ''),
        'debug': True
    },
    'test': {
        'host': 'localhost',
        'port': 5432,
        'database': 'myapp_test',
        'user': 'postgres',
        'password': os.environ.get('DATABASE_PASSWORD', ''),
        'debug': False
    },
    'production': {
        'host': os.environ.get('DATABASE_HOST'),
        'port': int(os.environ.get('DATABASE_PORT', 5432)),
        'database': os.environ.get('DATABASE_NAME'),
        'user': os.environ.get('DATABASE_USER'),
        'password': os.environ.get('DATABASE_PASSWORD'),
        'debug': False,
        'ssl_require': True
    }
}
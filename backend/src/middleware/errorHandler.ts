import { Request, Response, NextFunction } from 'express';

export interface ApiError extends Error {
  statusCode?: number;
}

export const errorHandler = (
  error: ApiError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error('Error:', error);

  // Default to 500 server error
  let statusCode = error.statusCode || 500;
  let message = error.message || 'Internal Server Error';
  let errorName = error.name || 'Error';

  // Handle specific error types
  if (error.message === 'Email already exists') {
    statusCode = 409;
    errorName = 'Conflict';
  }

  // Handle database connection errors
  if (error.message && error.message.includes('database')) {
    statusCode = 503;
    errorName = 'Service Unavailable';
    message = 'Database service is temporarily unavailable';
  }

  // Handle PostgreSQL specific errors
  const pgError = error as any;
  if (pgError.code) {
    switch (pgError.code) {
      case '23505': // Unique constraint violation
        statusCode = 409;
        errorName = 'Conflict';
        message = 'Resource already exists';
        break;
      case '23503': // Foreign key constraint violation
        statusCode = 400;
        errorName = 'Bad Request';
        message = 'Invalid reference to related resource';
        break;
      case '23502': // Not null constraint violation
        statusCode = 400;
        errorName = 'Bad Request';
        message = 'Required field is missing';
        break;
      case '22P02': // Invalid text representation
        statusCode = 400;
        errorName = 'Bad Request';
        message = 'Invalid data format';
        break;
      case '08003': // Connection does not exist
      case '08006': // Connection failure
        statusCode = 503;
        errorName = 'Service Unavailable';
        message = 'Database connection failed';
        break;
    }
  }

  // Handle JSON parsing errors
  if (error instanceof SyntaxError && 'body' in error) {
    statusCode = 400;
    errorName = 'Bad Request';
    message = 'Invalid JSON format';
  }

  // Prevent sensitive information leakage in production
  if (process.env.NODE_ENV === 'production') {
    if (statusCode === 500) {
      message = 'Internal Server Error';
    }
  }

  res.status(statusCode).json({
    error: errorName,
    message,
    ...(process.env.NODE_ENV === 'development' && { 
      stack: error.stack,
      originalError: error.message 
    })
  });
};

export const notFoundHandler = (req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`
  });
};
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

import userRoutes from './routes/users';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { sanitizeInput, rateLimiter, validateContentLength, validateContentType } from './middleware/security';
import { connectDB } from './config/database';

dotenv.config();

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());
app.use(rateLimiter(15 * 60 * 1000, 100)); // 100 requests per 15 minutes
app.use(validateContentLength(10 * 1024 * 1024)); // 10MB limit
app.use(validateContentType);

// Logging middleware
app.use(morgan('combined'));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Input sanitization
app.use(sanitizeInput);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/v1/users', userRoutes);
// Backward compatibility for load tests
app.use('/api/users', userRoutes);

// Error handling middleware
app.use(notFoundHandler);
app.use(errorHandler);

// Initialize database connection
const initializeApp = async () => {
  try {
    await connectDB();
    console.log('Database connection initialized');
  } catch (error) {
    console.error('Failed to initialize database:', error);
    process.exit(1);
  }
};

export { app, initializeApp };
import { Request, Response, NextFunction } from 'express';

/**
 * Middleware to sanitize user input
 */
export const sanitizeInput = (req: Request, res: Response, next: NextFunction) => {
  // Helper function to recursively sanitize strings
  const sanitizeString = (str: string): string => {
    if (typeof str !== 'string') return str;
    
    // Remove potential XSS patterns
    return str
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '')
      .trim();
  };

  // Helper function to sanitize object properties
  const sanitizeObject = (obj: any): any => {
    if (!obj || typeof obj !== 'object') return obj;
    
    if (Array.isArray(obj)) {
      return obj.map(sanitizeObject);
    }
    
    const sanitized: any = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        sanitized[key] = sanitizeString(value);
      } else if (typeof value === 'object') {
        sanitized[key] = sanitizeObject(value);
      } else {
        sanitized[key] = value;
      }
    }
    return sanitized;
  };

  // Sanitize request body
  if (req.body) {
    req.body = sanitizeObject(req.body);
  }

  // Sanitize query parameters
  if (req.query) {
    req.query = sanitizeObject(req.query);
  }

  next();
};

/**
 * Simple in-memory rate limiter
 */
const requestCounts = new Map<string, { count: number; resetTime: number }>();

export const rateLimiter = (
  windowMs: number = 15 * 60 * 1000, // 15 minutes
  maxRequests: number = 100 // Max requests per window
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const clientIP = req.ip || req.connection.remoteAddress || 'unknown';
    const now = Date.now();
    
    // Clean up expired entries
    for (const [ip, data] of requestCounts.entries()) {
      if (now > data.resetTime) {
        requestCounts.delete(ip);
      }
    }
    
    // Get or create entry for this IP
    let clientData = requestCounts.get(clientIP);
    if (!clientData || now > clientData.resetTime) {
      clientData = {
        count: 0,
        resetTime: now + windowMs
      };
      requestCounts.set(clientIP, clientData);
    }
    
    // Increment request count
    clientData.count++;
    
    // Check if limit exceeded
    if (clientData.count > maxRequests) {
      const resetTimeSeconds = Math.ceil((clientData.resetTime - now) / 1000);
      
      res.status(429).json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Try again in ${resetTimeSeconds} seconds.`,
        retryAfter: resetTimeSeconds
      });
      return;
    }
    
    // Add rate limit headers
    res.set({
      'X-RateLimit-Limit': maxRequests.toString(),
      'X-RateLimit-Remaining': (maxRequests - clientData.count).toString(),
      'X-RateLimit-Reset': Math.ceil(clientData.resetTime / 1000).toString()
    });
    
    next();
  };
};

/**
 * Middleware to validate content length
 */
export const validateContentLength = (maxSize: number = 10 * 1024 * 1024) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const contentLength = parseInt(req.get('content-length') || '0');
    
    if (contentLength > maxSize) {
      res.status(413).json({
        error: 'Payload Too Large',
        message: `Request body exceeds maximum size of ${maxSize} bytes`
      });
      return;
    }
    
    next();
  };
};

/**
 * Middleware to validate request content type for API endpoints
 */
export const validateContentType = (req: Request, res: Response, next: NextFunction) => {
  // Skip validation for GET, DELETE requests
  if (['GET', 'DELETE'].includes(req.method)) {
    return next();
  }
  
  const contentType = req.get('content-type');
  
  // Allow application/json and application/x-www-form-urlencoded
  if (!contentType || (!contentType.includes('application/json') && 
                       !contentType.includes('application/x-www-form-urlencoded'))) {
    res.status(415).json({
      error: 'Unsupported Media Type',
      message: 'Content-Type must be application/json or application/x-www-form-urlencoded'
    });
    return;
  }
  
  next();
};
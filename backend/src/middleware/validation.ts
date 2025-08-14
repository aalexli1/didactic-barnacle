import Joi from 'joi';
import { Request, Response, NextFunction } from 'express';

export const validateCreateUser = (req: Request, res: Response, next: NextFunction) => {
  const schema = Joi.object({
    username: Joi.string().trim().min(1).max(50).required(),
    email: Joi.string().email().required(),
    firstName: Joi.string().trim().min(1).max(100).required(),
    lastName: Joi.string().trim().min(1).max(100).required(),
    role: Joi.string().valid('admin', 'user', 'moderator').required(),
    password: Joi.string().min(8).required()
  });

  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({
      error: 'Validation Error',
      message: error.details[0].message,
      details: error.details
    });
  }

  next();
};

export const validateUpdateUser = (req: Request, res: Response, next: NextFunction) => {
  const schema = Joi.object({
    username: Joi.string().trim().min(1).max(50).optional(),
    email: Joi.string().email().optional(),
    firstName: Joi.string().trim().min(1).max(100).optional(),
    lastName: Joi.string().trim().min(1).max(100).optional(),
    role: Joi.string().valid('admin', 'user', 'moderator').optional(),
    status: Joi.string().valid('active', 'inactive', 'suspended').optional()
  }).min(1); // At least one field must be provided

  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({
      error: 'Validation Error',
      message: error.details[0].message,
      details: error.details
    });
  }

  next();
};

export const validateUserFilters = (req: Request, res: Response, next: NextFunction) => {
  const schema = Joi.object({
    search: Joi.string().trim().optional(),
    role: Joi.string().valid('admin', 'user', 'moderator').optional(),
    status: Joi.string().valid('active', 'inactive', 'suspended').optional(),
    page: Joi.number().integer().min(1).optional(),
    limit: Joi.number().integer().min(1).max(100).optional()
  });

  const { error } = schema.validate(req.query);
  if (error) {
    return res.status(400).json({
      error: 'Validation Error',
      message: error.details[0].message,
      details: error.details
    });
  }

  next();
};
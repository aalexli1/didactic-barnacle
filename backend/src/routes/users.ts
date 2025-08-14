import { Router, Request, Response, NextFunction } from 'express';
import { UserModel } from '../models/user';
import { CreateUserRequest, UpdateUserRequest, UserFilters } from '../types/user';
import { validateCreateUser, validateUpdateUser, validateUserFilters } from '../middleware/validation';

const router = Router();

// GET /api/v1/users - Get all users with optional filtering
router.get('/', validateUserFilters, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const filters: UserFilters = {
      search: req.query.search as string,
      role: req.query.role as string,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    };

    const { users, total } = await UserModel.findAll(filters);
    const page = filters.page || 1;
    const limit = filters.limit || 10;

    res.json({
      users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/users/:id - Get user by ID
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const user = await UserModel.findById(id);

    if (!user) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    res.json(user);
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/users - Create new user
router.post('/', validateCreateUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userData: CreateUserRequest = req.body;
    const user = await UserModel.create(userData);

    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});

// PUT /api/v1/users/:id - Update user
router.put('/:id', validateUpdateUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userData: UpdateUserRequest = req.body;

    const user = await UserModel.update(id, userData);

    if (!user) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    res.json(user);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/v1/users/:id - Delete user
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const deleted = await UserModel.delete(id);

    if (!deleted) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;
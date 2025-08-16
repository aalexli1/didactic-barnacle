const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { User } = require('../models');

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET || 'secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 */
router.post('/register',
  [
    body('username').isLength({ min: 3, max: 30 }).trim(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 })
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { username, email, password } = req.body;

      const existingUser = await User.findOne({
        where: {
          [require('sequelize').Op.or]: [{ email }, { username }]
        }
      });

      if (existingUser) {
        return res.status(400).json({
          error: existingUser.email === email 
            ? 'Email already registered' 
            : 'Username already taken'
        });
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      const user = await User.create({
        username,
        email,
        password: hashedPassword,
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${username}`
      });

      const token = generateToken(user);

      res.status(201).json({
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          avatar: user.avatar
        }
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({ error: 'Failed to register user' });
    }
  }
);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Auth]
 */
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty()
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { email, password } = req.body;

      const user = await User.findOne({ where: { email } });

      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const isPasswordValid = await bcrypt.compare(password, user.password);

      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      if (!user.is_active) {
        return res.status(403).json({ error: 'Account is deactivated' });
      }

      const token = generateToken(user);

      res.json({
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          avatar: user.avatar,
          treasures_created: user.treasures_created,
          treasures_found: user.treasures_found,
          points: user.points
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ error: 'Failed to login' });
    }
  }
);

module.exports = router;
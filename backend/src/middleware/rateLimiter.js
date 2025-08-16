const rateLimit = require('express-rate-limit');
const { redisClient } = require('../config/redis');

const RedisStore = require('rate-limit-redis').default;

const createRateLimiter = (windowMs = 15 * 60 * 1000, max = 100) => {
  const options = {
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message: 'Too many requests from this IP, please try again later.'
  };

  if (redisClient && redisClient.isOpen) {
    options.store = new RedisStore({
      client: redisClient,
      prefix: 'rate_limit:'
    });
  }

  return rateLimit(options);
};

const generalLimiter = createRateLimiter(15 * 60 * 1000, 100);

const authLimiter = createRateLimiter(15 * 60 * 1000, 5);

const treasureLimiter = createRateLimiter(60 * 60 * 1000, 50);

module.exports = generalLimiter;
module.exports.authLimiter = authLimiter;
module.exports.treasureLimiter = treasureLimiter;
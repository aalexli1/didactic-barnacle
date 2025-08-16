const { User, Achievement, UserAchievement, Leaderboard } = require('../models');
const { Op } = require('sequelize');

class GamificationService {
  static XP_LEVELS = [
    0, 100, 250, 500, 1000, 1750, 2750, 4000, 5500, 7500,
    10000, 13000, 16500, 20500, 25000, 30000, 36000, 43000, 51000, 60000
  ];

  static POINTS_CONFIG = {
    TREASURE_CREATED: 20,
    TREASURE_FOUND: 30,
    FIRST_TO_FIND: 50,
    RARE_TREASURE_FOUND: 100,
    DAILY_STREAK: 10,
    FRIEND_ADDED: 5,
    CHALLENGE_COMPLETED: 100,
    ACHIEVEMENT_UNLOCKED: 25,
    COMMENT_POSTED: 2,
    LIKE_RECEIVED: 1
  };

  static async addExperience(userId, points, reason) {
    try {
      const user = await User.findByPk(userId);
      if (!user) throw new Error('User not found');

      const newExperience = user.experience + points;
      const newLevel = this.calculateLevel(newExperience);
      const leveledUp = newLevel > user.level;

      await user.update({
        experience: newExperience,
        level: newLevel,
        points: user.points + points
      });

      if (leveledUp) {
        await this.checkLevelAchievements(userId, newLevel);
      }

      await this.updateLeaderboards(userId, points);

      return {
        newExperience,
        newLevel,
        leveledUp,
        pointsEarned: points
      };
    } catch (error) {
      console.error('Error adding experience:', error);
      throw error;
    }
  }

  static calculateLevel(experience) {
    for (let i = this.XP_LEVELS.length - 1; i >= 0; i--) {
      if (experience >= this.XP_LEVELS[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  static getExperienceForNextLevel(currentLevel) {
    if (currentLevel >= this.XP_LEVELS.length) {
      return null;
    }
    return this.XP_LEVELS[currentLevel];
  }

  static async checkAchievements(userId, type, value) {
    try {
      const achievements = await Achievement.findAll({
        where: {
          requirement_type: type,
          is_active: true
        }
      });

      for (const achievement of achievements) {
        const userAchievement = await UserAchievement.findOne({
          where: {
            user_id: userId,
            achievement_id: achievement.id
          }
        });

        if (userAchievement && userAchievement.completed) {
          continue;
        }

        let progress = value;
        let completed = false;

        if (userAchievement) {
          progress = userAchievement.progress + value;
        }

        if (progress >= achievement.requirement_value) {
          completed = true;
          progress = achievement.requirement_value;
        }

        if (userAchievement) {
          await userAchievement.update({
            progress,
            completed,
            completed_at: completed ? new Date() : null
          });
        } else {
          await UserAchievement.create({
            user_id: userId,
            achievement_id: achievement.id,
            progress,
            completed,
            completed_at: completed ? new Date() : null
          });
        }

        if (completed) {
          await this.addExperience(userId, achievement.points, 'achievement_unlocked');
        }
      }
    } catch (error) {
      console.error('Error checking achievements:', error);
    }
  }

  static async checkLevelAchievements(userId, level) {
    const levelMilestones = [5, 10, 20, 30, 50, 75, 100];
    if (levelMilestones.includes(level)) {
      await this.checkAchievements(userId, 'special', level);
    }
  }

  static async updateLeaderboards(userId, points) {
    try {
      const now = new Date();
      const startOfDay = new Date(now.setHours(0, 0, 0, 0));
      const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      const periods = [
        { type: 'daily', start: startOfDay },
        { type: 'weekly', start: startOfWeek },
        { type: 'monthly', start: startOfMonth },
        { type: 'all_time', start: new Date(0) }
      ];

      for (const period of periods) {
        let leaderboard = await Leaderboard.findOne({
          where: {
            user_id: userId,
            period_type: period.type,
            period_start: period.start
          }
        });

        if (leaderboard) {
          await leaderboard.update({
            points: leaderboard.points + points
          });
        } else {
          await Leaderboard.create({
            user_id: userId,
            period_type: period.type,
            period_start: period.start,
            points: points
          });
        }
      }

      await this.updateLeaderboardRanks();
    } catch (error) {
      console.error('Error updating leaderboards:', error);
    }
  }

  static async updateLeaderboardRanks() {
    try {
      const periods = ['daily', 'weekly', 'monthly', 'all_time'];
      
      for (const period of periods) {
        const leaderboards = await Leaderboard.findAll({
          where: { period_type: period },
          order: [['points', 'DESC']]
        });

        for (let i = 0; i < leaderboards.length; i++) {
          await leaderboards[i].update({ rank: i + 1 });
        }
      }
    } catch (error) {
      console.error('Error updating leaderboard ranks:', error);
    }
  }

  static async getLeaderboard(periodType, limit = 100) {
    try {
      const leaderboards = await Leaderboard.findAll({
        where: { period_type: periodType },
        order: [['points', 'DESC']],
        limit,
        include: [{
          model: User,
          attributes: ['id', 'username', 'avatar', 'level']
        }]
      });

      return leaderboards;
    } catch (error) {
      console.error('Error getting leaderboard:', error);
      throw error;
    }
  }

  static async getUserRank(userId, periodType) {
    try {
      const leaderboard = await Leaderboard.findOne({
        where: {
          user_id: userId,
          period_type: periodType
        }
      });

      return leaderboard ? leaderboard.rank : null;
    } catch (error) {
      console.error('Error getting user rank:', error);
      return null;
    }
  }

  static async calculateStreak(userId) {
    try {
      const user = await User.findByPk(userId, {
        include: [{
          model: Discovery,
          order: [['created_at', 'DESC']],
          limit: 30
        }]
      });

      if (!user || !user.Discoveries || user.Discoveries.length === 0) {
        return 0;
      }

      let streak = 1;
      let lastDate = new Date(user.Discoveries[0].created_at);
      lastDate.setHours(0, 0, 0, 0);

      for (let i = 1; i < user.Discoveries.length; i++) {
        const currentDate = new Date(user.Discoveries[i].created_at);
        currentDate.setHours(0, 0, 0, 0);
        
        const dayDiff = Math.floor((lastDate - currentDate) / (1000 * 60 * 60 * 24));
        
        if (dayDiff === 1) {
          streak++;
          lastDate = currentDate;
        } else if (dayDiff > 1) {
          break;
        }
      }

      return streak;
    } catch (error) {
      console.error('Error calculating streak:', error);
      return 0;
    }
  }
}

module.exports = GamificationService;
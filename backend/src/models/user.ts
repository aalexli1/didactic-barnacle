import { pool } from '../config/database';
import { DatabaseUser, User, CreateUserRequest, UpdateUserRequest, UserFilters } from '../types/user';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12');

export class UserModel {
  static async create(userData: CreateUserRequest): Promise<User> {
    const id = uuidv4();
    const passwordHash = await bcrypt.hash(userData.password, SALT_ROUNDS);
    
    const query = `
      INSERT INTO users (id, username, email, first_name, last_name, password_hash, role, status, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
      RETURNING id, username, email, first_name, last_name, role, status, created_at, updated_at
    `;
    
    const values = [id, userData.username, userData.email, userData.firstName, userData.lastName, passwordHash, userData.role, 'active'];
    
    try {
      const result = await pool.query(query, values);
      return this.mapDatabaseUserToUser(result.rows[0]);
    } catch (error: any) {
      if (error.code === '23505') { // Unique constraint violation
        throw new Error('Email already exists');
      }
      throw error;
    }
  }

  static async findAll(filters: UserFilters = {}): Promise<{ users: User[]; total: number }> {
    const { search, role, status, page = 1, limit = 10 } = filters;
    const offset = (page - 1) * limit;
    
    let whereClause = 'WHERE 1=1';
    const values: any[] = [];
    let paramCount = 0;

    if (search) {
      paramCount++;
      whereClause += ` AND (username ILIKE $${paramCount} OR email ILIKE $${paramCount} OR first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount})`;
      values.push(`%${search}%`);
    }

    if (role) {
      paramCount++;
      whereClause += ` AND role = $${paramCount}`;
      values.push(role);
    }

    if (status) {
      paramCount++;
      whereClause += ` AND status = $${paramCount}`;
      values.push(status);
    }

    // Get total count
    const countQuery = `SELECT COUNT(*) FROM users ${whereClause}`;
    const countResult = await pool.query(countQuery, values);
    const total = parseInt(countResult.rows[0].count);

    // Get paginated users
    const query = `
      SELECT id, username, email, first_name, last_name, role, status, created_at, updated_at
      FROM users ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;
    
    const result = await pool.query(query, [...values, limit, offset]);
    const users = result.rows.map(this.mapDatabaseUserToUser);

    return { users, total };
  }

  static async findById(id: string): Promise<User | null> {
    const query = `
      SELECT id, username, email, first_name, last_name, role, status, created_at, updated_at
      FROM users WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapDatabaseUserToUser(result.rows[0]);
  }

  static async update(id: string, userData: UpdateUserRequest): Promise<User | null> {
    const existingUser = await this.findById(id);
    if (!existingUser) {
      return null;
    }

    const updates: string[] = [];
    const values: any[] = [];
    let paramCount = 0;

    if (userData.username !== undefined) {
      paramCount++;
      updates.push(`username = $${paramCount}`);
      values.push(userData.username);
    }

    if (userData.email !== undefined) {
      paramCount++;
      updates.push(`email = $${paramCount}`);
      values.push(userData.email);
    }

    if (userData.firstName !== undefined) {
      paramCount++;
      updates.push(`first_name = $${paramCount}`);
      values.push(userData.firstName);
    }

    if (userData.lastName !== undefined) {
      paramCount++;
      updates.push(`last_name = $${paramCount}`);
      values.push(userData.lastName);
    }

    if (userData.role !== undefined) {
      paramCount++;
      updates.push(`role = $${paramCount}`);
      values.push(userData.role);
    }

    if (userData.status !== undefined) {
      paramCount++;
      updates.push(`status = $${paramCount}`);
      values.push(userData.status);
    }

    if (updates.length === 0) {
      return existingUser;
    }

    paramCount++;
    updates.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE users 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, username, email, first_name, last_name, role, status, created_at, updated_at
    `;

    try {
      const result = await pool.query(query, values);
      return this.mapDatabaseUserToUser(result.rows[0]);
    } catch (error: any) {
      if (error.code === '23505') { // Unique constraint violation
        throw new Error('Email already exists');
      }
      throw error;
    }
  }

  static async delete(id: string): Promise<boolean> {
    const query = 'DELETE FROM users WHERE id = $1';
    const result = await pool.query(query, [id]);
    return (result.rowCount ?? 0) > 0;
  }

  private static mapDatabaseUserToUser(dbUser: any): User {
    return {
      id: dbUser.id,
      username: dbUser.username,
      email: dbUser.email,
      firstName: dbUser.first_name,
      lastName: dbUser.last_name,
      role: dbUser.role,
      status: dbUser.status,
      createdAt: dbUser.created_at.toISOString(),
      updatedAt: dbUser.updated_at.toISOString(),
    };
  }
}
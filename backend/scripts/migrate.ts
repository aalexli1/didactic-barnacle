import dotenv from 'dotenv';
import { runMigrations } from '../src/utils/migrate';
import { closeDB } from '../src/config/database';

dotenv.config();

const main = async () => {
  try {
    console.log('Starting database migrations...');
    await runMigrations();
    console.log('Database migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await closeDB();
  }
};

main();
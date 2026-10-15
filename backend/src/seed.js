/**
 * Seed script — run once with: npm run seed
 * Creates default admin + sample employees in MongoDB.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('./models/User');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/melbet_manager';

const seeds = [
  {
    name: 'Kidu Admin',
    username: 'kidu',
    passwordHash: 'zemakidoo',
    role: 'admin',
    email: 'kidu@melbet.com',
    isApproved: true,
    isActive: true,
  },
  {
    name: 'Dawit Manager',
    username: 'dawit',
    passwordHash: 'mgr123',
    role: 'manager',
    email: 'dawit@melbet.com',
    isApproved: true,
    isActive: true,
  },
  {
    name: 'Alem Tadesse',
    username: 'alem',
    passwordHash: 'emp123',
    role: 'employee',
    email: 'alem@melbet.com',
    isApproved: true,
    isActive: true,
  },
  {
    name: 'Biruk Haile',
    username: 'biruk',
    passwordHash: 'emp123',
    role: 'employee',
    email: 'biruk@melbet.com',
    isApproved: true,
    isActive: true,
  },
  {
    name: 'Chaltu Bekele',
    username: 'chaltu',
    passwordHash: 'emp123',
    role: 'employee',
    email: 'chaltu@melbet.com',
    isApproved: true,
    isActive: true,
  },
];

async function seed() {
  await mongoose.connect(MONGO_URI);
  console.log('✅ Connected to MongoDB');

  for (const data of seeds) {
    const exists = await User.findOne({ username: data.username });
    if (exists) {
      console.log(`⏭  Skipping existing user: ${data.username}`);
      continue;
    }
    const user = new User(data);
    await user.save();
    console.log(`✅ Created user: ${data.username} (${data.role})`);
  }

  console.log('🎉 Seeding complete!');
  await mongoose.disconnect();
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});

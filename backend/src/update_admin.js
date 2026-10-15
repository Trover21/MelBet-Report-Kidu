/**
 * Admin update script — run with: node src/update_admin.js
 * Creates or updates the admin account with:
 *   username: kidu
 *   password: zemakidoo
 *
 * The pre-save hook on User hashes any modified passwordHash field,
 * so we simply set passwordHash = plain text and let the hook hash it.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('./models/User');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/melbet_manager';

async function updateAdmin() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect(MONGO_URI);
  console.log('✅ Connected to MongoDB');

  // Remove ALL existing admin accounts (old 'admin', any duplicate)
  const deleted = await User.deleteMany({ role: 'admin' });
  console.log(`🗑  Removed ${deleted.deletedCount} old admin account(s)`);

  // Create fresh admin — pre-save hook will hash 'zemakidoo' automatically
  const admin = new User({
    name: 'Kidu Admin',
    username: 'kidu',
    passwordHash: 'zemakidoo', // hook will bcrypt this
    role: 'admin',
    email: 'kidu@melbet.com',
    isApproved: true,
    isActive: true,
  });
  await admin.save();

  console.log('✅ Admin account created successfully:');
  console.log('   username : kidu');
  console.log('   password : zemakidoo');
  console.log('   role     : admin');

  await mongoose.disconnect();
  console.log('🎉 Done! You can now log in with the above credentials.');
  process.exit(0);
}

updateAdmin().catch((err) => {
  console.error('❌ Failed:', err.message);
  process.exit(1);
});

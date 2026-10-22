const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// ── Roles: admin | manager | employee ────────────────────────────
// manager = same UI access as admin, but must be approved by admin
const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
    },
    passwordHash: { type: String, required: true },
    role: {
      type: String,
      enum: ['admin', 'manager', 'employee'],
      default: 'employee',
    },
    email: { type: String, trim: true, lowercase: true },
    teamNumber: { type: Number, default: 1, min: 1 }, // which team this user belongs to
    teamName: { type: String, default: 'Team 1', trim: true },
    teams: [{ type: String, trim: true }],
    isApproved: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.passwordHash);
};

userSchema.methods.toSafeObject = function () {
  const primaryTeam =
    this.teamName ||
    (this.teams && this.teams[0]) ||
    (this.teamNumber ? `Team ${this.teamNumber}` : 'Team 1');
  const userTeams =
    this.teams && this.teams.length > 0 ? this.teams : [primaryTeam];

  return {
    id: this._id.toString(),
    name: this.name,
    username: this.username,
    role: this.role,
    email: this.email,
    teamNumber: this.teamNumber ?? 1,
    teamName: primaryTeam,
    teams: userTeams,
    isApproved: this.isApproved,
    isActive: this.isActive,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('User', userSchema);

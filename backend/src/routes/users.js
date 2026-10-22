const router = require('express').Router();
const User = require('../models/User');
const { authenticate, requirePrivileged, requireAdmin } = require('../middleware/authMiddleware');

// All user-management routes require a valid JWT
router.use(authenticate);

// ── GET /api/users (Admin: all users. Manager: self + assigned team employees)
router.get('/', requirePrivileged, async (req, res) => {
  try {
    let filter = {};
    if (req.user.role === 'manager') {
      const managerTeams = (req.user.teams && req.user.teams.length > 0)
        ? req.user.teams
        : (req.user.teamName ? [req.user.teamName] : []);
      filter = {
        $or: [
          { _id: req.user._id },
          { role: 'employee', teamName: { $in: managerTeams } },
        ],
      };
    }
    const users = await User.find(filter).sort({ createdAt: -1 });
    res.json(users.map((u) => u.toSafeObject()));
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// ── GET /api/users/pending ────────────────────────────────────────
router.get('/pending', requirePrivileged, async (req, res) => {
  try {
    let filter = { isApproved: false };
    if (req.user.role === 'manager') {
      const managerTeams = (req.user.teams && req.user.teams.length > 0)
        ? req.user.teams
        : (req.user.teamName ? [req.user.teamName] : []);
      filter = {
        isApproved: false,
        role: 'employee',
        teamName: { $in: managerTeams },
      };
    }
    const users = await User.find(filter).sort({ createdAt: -1 });
    res.json(users.map((u) => u.toSafeObject()));
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch pending users' });
  }
});

// ── PATCH /api/users/:id/approve (Admin Only) ────────────────────
router.patch('/:id/approve', requireAdmin, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isApproved: true, isActive: true },
      { new: true }
    );
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.toSafeObject());
  } catch (err) {
    res.status(500).json({ error: 'Failed to approve user' });
  }
});

// ── PATCH /api/users/:id/reject (Admin Only) ─────────────────────
router.patch('/:id/reject', requireAdmin, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'User rejected and removed' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to reject user' });
  }
});

// ── DELETE /api/users/:id (Admin removes employee or manager) ─────
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    if (req.params.id === req.user._id.toString()) {
      return res.status(400).json({ error: 'Cannot delete your own admin account' });
    }
    const targetUser = await User.findById(req.params.id);
    if (!targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }
    if (targetUser.role === 'admin') {
      return res.status(400).json({ error: 'Cannot delete an administrator account' });
    }
    await User.findByIdAndDelete(req.params.id);
    try {
      const TeamRequest = require('../models/TeamRequest');
      await TeamRequest.deleteMany({ userId: req.params.id });
    } catch (_) {}
    res.json({ message: `${targetUser.name} (${targetUser.role}) removed successfully` });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// ── PATCH /api/users/:id/active (Admin Only) ─────────────────────
router.patch('/:id/active', requireAdmin, async (req, res) => {
  try {
    const { isActive } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: Boolean(isActive) },
      { new: true }
    );
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.toSafeObject());
  } catch (err) {
    res.status(500).json({ error: 'Failed to update user status' });
  }
});

module.exports = router;

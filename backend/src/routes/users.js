const router = require('express').Router();
const User = require('../models/User');
const { authenticate, requirePrivileged, requireAdmin } = require('../middleware/authMiddleware');

// All user-management routes require a valid JWT
router.use(authenticate);

// ── GET /api/users (Admin + Manager can view team members) ────────
router.get('/', requirePrivileged, async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json(users.map((u) => u.toSafeObject()));
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// ── GET /api/users/pending ────────────────────────────────────────
router.get('/pending', requirePrivileged, async (req, res) => {
  try {
    const users = await User.find({ isApproved: false }).sort({ createdAt: -1 });
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

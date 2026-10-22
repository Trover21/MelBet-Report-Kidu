const express = require('express');
const router = express.Router();
const Team = require('../models/Team');
const TeamRequest = require('../models/TeamRequest');
const User = require('../models/User');
const { authenticate, requireAdmin } = require('../middleware/authMiddleware');

const DEFAULT_TEAMS = ['Team 1', 'Team 2', 'Team 3'];

// ── GET /api/teams ────────────────────────────────────────────────
// Public / accessible for register screen & dashboard dropdowns
router.get('/', async (req, res) => {
  try {
    let teams = await Team.find({ isActive: true }).sort({ name: 1 });
    if (teams.length === 0) {
      // Seed default teams if none exist
      for (const name of DEFAULT_TEAMS) {
        await Team.updateOne({ name }, { $setOnInsert: { name, isActive: true } }, { upsert: true });
      }
      teams = await Team.find({ isActive: true }).sort({ name: 1 });
    }
    res.json({ teams: teams.map((t) => t.name) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teams' });
  }
});

// ── POST /api/teams (Admin pushes new team dynamically) ───────────
router.post('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Team name is required' });
    }
    const cleanName = name.trim();
    const existing = await Team.findOne({ name: cleanName });
    if (existing) {
      if (!existing.isActive) {
        existing.isActive = true;
        await existing.save();
        return res.json({ message: 'Team re-activated', team: existing.name });
      }
      return res.status(409).json({ error: 'A team with this name already exists' });
    }
    const team = await Team.create({ name: cleanName, description: description?.trim() || '' });
    res.status(201).json({ message: 'Team created successfully', team: team.name });
  } catch (err) {
    res.status(500).json({ error: err.message || 'Failed to create team' });
  }
});

// ── DELETE /api/teams/:name (Admin deactivate team) ───────────────
router.delete('/:name', authenticate, requireAdmin, async (req, res) => {
  try {
    const { name } = req.params;
    await Team.findOneAndUpdate({ name }, { isActive: false });
    res.json({ message: 'Team removed successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to remove team' });
  }
});

// ── POST /api/teams/request (Manager requests additional teams) ────
router.post('/request', authenticate, async (req, res) => {
  try {
    const { requestedTeams, reason } = req.body;
    if (!requestedTeams || !Array.isArray(requestedTeams) || requestedTeams.length === 0) {
      return res.status(400).json({ error: 'At least one requested team is required' });
    }
    const request = await TeamRequest.create({
      userId: req.user._id,
      userName: req.user.name,
      requestedTeams: requestedTeams.map((t) => String(t).trim()).filter(Boolean),
      reason: reason?.trim() || '',
    });
    res.status(201).json({ message: 'Team request submitted to admin', request });
  } catch (err) {
    res.status(500).json({ error: 'Failed to submit team request' });
  }
});

// ── GET /api/teams/requests ───────────────────────────────────────
router.get('/requests', authenticate, async (req, res) => {
  try {
    let filter = {};
    if (req.user.role !== 'admin') {
      filter.userId = req.user._id;
    }
    const requests = await TeamRequest.find(filter).sort({ createdAt: -1 });
    res.json({
      requests: requests.map((r) => ({
        id: r._id.toString(),
        userId: r.userId.toString(),
        userName: r.userName,
        requestedTeams: r.requestedTeams,
        reason: r.reason,
        status: r.status,
        reviewedBy: r.reviewedBy,
        reviewedAt: r.reviewedAt?.toISOString(),
        createdAt: r.createdAt.toISOString(),
      })),
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch team requests' });
  }
});

// ── POST /api/teams/requests/:id/approve (Admin approves request) ─
router.post('/requests/:id/approve', authenticate, requireAdmin, async (req, res) => {
  try {
    const request = await TeamRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.status !== 'pending') {
      return res.status(400).json({ error: `Request already ${request.status}` });
    }

    request.status = 'approved';
    request.reviewedBy = req.user.username;
    request.reviewedAt = new Date();
    await request.save();

    // Add teams to manager's user account
    const manager = await User.findById(request.userId);
    if (manager) {
      const existingTeams = new Set(manager.teams || []);
      if (manager.teamName) existingTeams.add(manager.teamName);
      request.requestedTeams.forEach((t) => existingTeams.add(t));
      manager.teams = Array.from(existingTeams);
      await manager.save();
    }

    res.json({ message: 'Team request approved and teams assigned', request });
  } catch (err) {
    res.status(500).json({ error: 'Failed to approve request' });
  }
});

// ── POST /api/teams/requests/:id/reject (Admin rejects request) ───
router.post('/requests/:id/reject', authenticate, requireAdmin, async (req, res) => {
  try {
    const request = await TeamRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    request.status = 'rejected';
    request.reviewedBy = req.user.username;
    request.reviewedAt = new Date();
    await request.save();
    res.json({ message: 'Team request rejected', request });
  } catch (err) {
    res.status(500).json({ error: 'Failed to reject request' });
  }
});

// ── DELETE /api/teams/my-team/:name (Manager removes team from own list) ──
router.delete('/my-team/:name', authenticate, async (req, res) => {
  try {
    const { name } = req.params;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    let teams = (user.teams || []).filter((t) => t !== name);
    if (teams.length === 0) {
      return res.status(400).json({ error: 'You must manage at least one team.' });
    }
    user.teams = teams;
    if (user.teamName === name) {
      user.teamName = teams[0];
    }
    await user.save();

    res.json({
      message: `Team "${name}" removed from your managed teams`,
      teams: user.teams,
      teamName: user.teamName,
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to remove team from your managed list' });
  }
});

// ── DELETE /api/teams/requests/:id (Cancel/delete team request) ────
router.delete('/requests/:id', authenticate, async (req, res) => {
  try {
    const request = await TeamRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (req.user.role !== 'admin' && request.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Not authorized to cancel this request' });
    }
    await TeamRequest.findByIdAndDelete(req.params.id);
    res.json({ message: 'Request cancelled successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to cancel request' });
  }
});

module.exports = router;


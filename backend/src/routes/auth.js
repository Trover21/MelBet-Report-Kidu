const router = require('express').Router();
const User = require('../models/User');
const { authenticate, signToken } = require('../middleware/authMiddleware');

// ── POST /api/auth/login ──────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const user = await User.findOne({ username: username.toLowerCase().trim() });
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const match = await user.comparePassword(password);
    if (!match) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    if (!user.isApproved) {
      return res.status(403).json({
        error:
          'Your account is pending administrator approval. Please contact an admin or wait for approval before signing in.',
        isPending: true,
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        error: 'Your account has been disabled by an administrator. Please contact your manager.',
      });
    }

    const token = signToken(user._id);
    return res.json({ token, user: user.toSafeObject() });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// ── POST /api/auth/register ───────────────────────────────────────
// role must be 'employee' or 'manager' (admin cannot self-register)
router.post('/register', async (req, res) => {
  try {
    const { name, username, email, password, role, teamNumber, teamName, teams } = req.body;

    if (!name || !username || !password) {
      return res.status(400).json({ error: 'Name, username, and password are required' });
    }

    const allowedRoles = ['employee', 'manager'];
    const assignedRole = allowedRoles.includes(role) ? role : 'employee';

    // Parse team(s)
    let assignedTeamName = 'Team 1';
    let assignedTeams = [];

    if (assignedRole === 'manager') {
      if (Array.isArray(teams) && teams.length > 0) {
        assignedTeams = teams.map((t) => String(t).trim()).filter(Boolean);
        assignedTeamName = assignedTeams[0] || 'Team 1';
      } else if (teamName && String(teamName).trim()) {
        assignedTeamName = String(teamName).trim();
        assignedTeams = [assignedTeamName];
      } else {
        assignedTeams = ['Team 1'];
      }
    } else {
      // employee: selects one team
      if (teamName && String(teamName).trim()) {
        assignedTeamName = String(teamName).trim();
      } else if (Array.isArray(teams) && teams.length > 0) {
        assignedTeamName = String(teams[0]).trim();
      } else if (teamNumber) {
        assignedTeamName = `Team ${teamNumber}`;
      }
      assignedTeams = [assignedTeamName];
    }

    // Optional legacy teamNumber fallback
    const matchedNumber = parseInt(assignedTeamName.replace(/\D/g, ''), 10);
    const assignedTeamNumber = !isNaN(matchedNumber) && matchedNumber >= 1
      ? matchedNumber
      : (Number.isInteger(Number(teamNumber)) && Number(teamNumber) >= 1 ? Number(teamNumber) : 1);

    const existingByUsername = await User.findOne({ username: username.toLowerCase().trim() });
    if (existingByUsername) {
      return res.status(409).json({ error: 'Username is already taken' });
    }

    if (email) {
      const existingByEmail = await User.findOne({ email: email.toLowerCase().trim() });
      if (existingByEmail) {
        return res.status(409).json({ error: 'Email is already registered' });
      }
    }

    const user = new User({
      name: name.trim(),
      username: username.toLowerCase().trim(),
      passwordHash: password, // pre-save hook will hash it
      role: assignedRole,
      email: email?.toLowerCase().trim(),
      teamNumber: assignedTeamNumber,
      teamName: assignedTeamName,
      teams: assignedTeams,
      isApproved: false,
      isActive: true,
    });

    await user.save();
    return res.status(201).json({ message: 'Registration successful. Await admin approval.' });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// ── POST /api/auth/change-password ───────────────────────────────
router.post('/change-password', authenticate, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters' });
    }

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ error: 'Current password is incorrect' });
    }

    user.passwordHash = newPassword;
    await user.save();
    return res.json({ message: 'Password changed successfully' });
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ error: 'Failed to change password. Please try again.' });
  }
});

// ── POST /api/auth/forgot-password ───────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      return res.status(404).json({ error: 'No account found with that email address' });
    }
    // In production: send email. Here we just confirm it exists.
    return res.json({ message: 'If an account exists, credentials have been sent.' });
  } catch (err) {
    res.status(500).json({ error: 'Something went wrong. Please try again.' });
  }
});

// ── GET /api/auth/me ─────────────────────────────────────────────
router.get('/me', authenticate, (req, res) => {
  res.json({ user: req.user.toSafeObject() });
});

module.exports = router;

const router = require('express').Router();
const ShiftReport = require('../models/ShiftReport');
const User = require('../models/User');
const { authenticate, requirePrivileged } = require('../middleware/authMiddleware');

router.use(authenticate);

const isPrivileged = (user) => user.role === 'admin' || user.role === 'manager';

// ── GET /api/reports/employees ────────────────────────────────────
// Admin/manager: list approved employees for filters
router.get('/employees', requirePrivileged, async (req, res) => {
  try {
    const employees = await User.find({ role: 'employee', isApproved: true, isActive: true });
    res.json(employees.map((u) => u.toSafeObject()));
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch employees' });
  }
});

// ── GET /api/reports ──────────────────────────────────────────────
// Admin/manager: all reports. Employee: own reports only.
router.get('/', async (req, res) => {
  try {
    let query = {};
    if (!isPrivileged(req.user)) {
      query.employeeId = req.user._id;
    }

    const { startDate, endDate, employeeId, shiftNumber } = req.query;
    if (startDate) query.operatingDate = { $gte: new Date(startDate) };
    if (endDate) query.operatingDate = { ...query.operatingDate, $lte: new Date(endDate) };
    if (employeeId && isPrivileged(req.user)) query.employeeId = employeeId;
    if (shiftNumber) query.shiftNumber = parseInt(shiftNumber, 10);

    const reports = await ShiftReport.find(query).sort({ operatingDate: -1, shiftNumber: 1 });
    res.json(reports.map((r) => r.toClientObject()));
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch reports' });
  }
});

// ── POST /api/reports ─────────────────────────────────────────────
// Employee submits a new shift report
router.post('/', async (req, res) => {
  try {
    const body = req.body;

    // Duplicate check
    const existing = await ShiftReport.findOne({
      employeeId: req.user._id,
      operatingDate: new Date(body.operatingDate),
      shiftNumber: body.shiftNumber,
    });
    if (existing) {
      return res.status(409).json({ error: 'A report for this shift and date already exists.' });
    }

    const report = new ShiftReport({
      ...body,
      employeeId: req.user._id,
      employeeName: req.user.name,
      submittedAt: new Date(),
      status: 'submitted',
    });

    await report.save();
    res.status(201).json(report.toClientObject());
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'A report for this shift and date already exists.' });
    }
    console.error('Submit report error:', err);
    res.status(500).json({ error: 'Failed to submit report' });
  }
});

// ── PATCH /api/reports/:id ────────────────────────────────────────
// Employee updates their own report (resubmit after correction)
router.patch('/:id', async (req, res) => {
  try {
    const report = await ShiftReport.findById(req.params.id);
    if (!report) return res.status(404).json({ error: 'Report not found' });

    // Employees can only edit their own reports
    if (!isPrivileged(req.user) && report.employeeId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const updatedFields = { ...req.body, lastModifiedAt: new Date() };
    if (!isPrivileged(req.user)) {
      updatedFields.status = 'submitted'; // resubmit for review
    }

    const updated = await ShiftReport.findByIdAndUpdate(req.params.id, updatedFields, {
      new: true,
    });
    res.json(updated.toClientObject());
  } catch (err) {
    res.status(500).json({ error: 'Failed to update report' });
  }
});

// ── PATCH /api/reports/:id/status ─────────────────────────────────
// Admin/manager changes report status with optional note
router.patch('/:id/status', requirePrivileged, async (req, res) => {
  try {
    const { status, notes } = req.body;
    const report = await ShiftReport.findById(req.params.id);
    if (!report) return res.status(404).json({ error: 'Report not found' });

    report.status = status;
    if (notes) report.notes = notes;
    if (notes && notes.trim()) {
      report.correctionHistory.push({
        correctedBy: req.user.name,
        correctedAt: new Date(),
        reason: notes.trim(),
      });
    }
    report.lastModifiedAt = new Date();
    await report.save();
    res.json(report.toClientObject());
  } catch (err) {
    res.status(500).json({ error: 'Failed to update report status' });
  }
});

// ── DELETE /api/reports/:id ───────────────────────────────────────
// Admin/manager deletes a report
router.delete('/:id', requirePrivileged, async (req, res) => {
  try {
    await ShiftReport.findByIdAndDelete(req.params.id);
    res.json({ message: 'Report deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete report' });
  }
});

module.exports = router;

const mongoose = require('mongoose');

const correctionRecordSchema = new mongoose.Schema(
  {
    correctedBy: { type: String, required: true },
    correctedAt: { type: Date, default: Date.now },
    reason: { type: String, required: true },
  },
  { _id: false }
);

const shiftReportSchema = new mongoose.Schema(
  {
    employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    employeeName: { type: String, required: true },
    operatingDate: { type: Date, required: true },
    shiftNumber: { type: Number, enum: [1, 2, 3], required: true },

    // Input fields
    initialReddy: { type: Number, default: 0 },
    initialAccount: { type: Number, default: 0 },
    totalDeposit: { type: Number, default: 0 },
    totalWithdrawal: { type: Number, default: 0 },
    endReddy: { type: Number, default: 0 },
    transferToNext: { type: Number, default: 0 },
    depositComplaintAccepted: { type: Number, default: 0 },
    withdrawalComplaintAccepted: { type: Number, default: 0 },
    prevDayPendingDepositApproved: { type: Number, default: 0 },
    depositOkAfterShift: { type: Number, default: 0 },
    withdrawalOkAfterShift: { type: Number, default: 0 },
    depositOkBeforeShift: { type: Number, default: 0 },
    withdrawalApprovedBeforeShift: { type: Number, default: 0 },
    totalUnprocessed: { type: Number, default: 0 },
    added: { type: Number, default: 0 },
    taken: { type: Number, default: 0 },

    // Calculated fields
    endBalance: { type: Number, default: 0 },
    depositCommission: { type: Number, default: 0 },
    withdrawalCommission: { type: Number, default: 0 },
    totalCommission: { type: Number, default: 0 },
    expectedAmount: { type: Number, default: 0 },
    actualAmount: { type: Number, default: 0 },
    deviation: { type: Number, default: 0 },

    // Meta
    status: {
      type: String,
      enum: ['submitted', 'reviewed', 'correction_requested', 'approved'],
      default: 'submitted',
    },
    notes: { type: String },
    correctionHistory: { type: [correctionRecordSchema], default: [] },
    submittedAt: { type: Date, default: Date.now },
    lastModifiedAt: { type: Date },
  },
  { timestamps: true }
);

// Compound unique index: one report per employee per date per shift
shiftReportSchema.index(
  { employeeId: 1, operatingDate: 1, shiftNumber: 1 },
  { unique: true }
);

shiftReportSchema.methods.toClientObject = function () {
  const obj = this.toObject();
  return {
    ...obj,
    id: obj._id.toString(),
    employeeId: obj.employeeId.toString(),
    operatingDate: obj.operatingDate.toISOString(),
    submittedAt: obj.submittedAt.toISOString(),
    lastModifiedAt: obj.lastModifiedAt?.toISOString() ?? null,
    correctionHistory: obj.correctionHistory.map((c) => ({
      ...c,
      correctedAt: c.correctedAt.toISOString(),
    })),
  };
};

module.exports = mongoose.model('ShiftReport', shiftReportSchema);

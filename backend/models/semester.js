const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Batch = require('./batch');

const Semester = sequelize.define('Semester', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    batchId: { type: DataTypes.INTEGER, allowNull: false, references: { model: Batch, key: 'id' } },
    semesterNumber: { type: DataTypes.TINYINT, allowNull: false, validate: { min: 1, max: 8 } },
    startDate: { type: DataTypes.DATEONLY, allowNull: false },
    endDate: { type: DataTypes.DATEONLY, allowNull: false }
}, { timestamps: false });

module.exports = Semester;

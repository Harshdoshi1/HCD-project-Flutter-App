const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Batch = require('./batch');

const Student = sequelize.define('Student', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    email: {
        type: DataTypes.STRING,
        allowNull: false
    },
    batchId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: { model: 'Batches', key: 'id' }
    },
    enrollmentNumber: {
        type: DataTypes.STRING,
        allowNull: false
    },
    currnetsemester: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    currentClassName: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'Current class name (e.g., Computer Science A, Computer Science B)'
    }
}, {
    tableName: 'Students',
    timestamps: true
});

Student.belongsTo(Batch, { foreignKey: 'batchId' });

module.exports = Student;
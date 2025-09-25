const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Semester = require('./semester'); // Import Semester model
const Batch = require('./batch'); // Import Batch model

const Subject = sequelize.define('Subject', {
    id: { 
        type: DataTypes.INTEGER, 
        autoIncrement: true, 
        primaryKey: true 
    },
    subjectName: { 
        type: DataTypes.STRING, 
        allowNull: false 
    },
    semesterId: { 
        type: DataTypes.INTEGER, 
        allowNull: false,
        references: { model: Semester, key: 'id' } // ✅ Foreign Key
    },
    batchId: { 
        type: DataTypes.INTEGER, 
        allowNull: false,
        references: { model: Batch, key: 'id' } // ✅ Foreign Key
    }
}, { timestamps: false });

// Establish relationships
Subject.belongsTo(Semester, { foreignKey: 'semesterId' });
Subject.belongsTo(Batch, { foreignKey: 'batchId' });

module.exports = Subject;

const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const User = sequelize.define('User', {
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
        allowNull: false,
        unique: 'email_unique'  // Using a unique constraint instead of index
    },
    password: { 
        type: DataTypes.STRING, 
        allowNull: false 
    },
    role: { 
        type: DataTypes.ENUM('student', 'Faculty', 'HOD'), 
        allowNull: false 
    }
}, { 
    timestamps: false,
    indexes: []  // Explicitly define indexes if needed
});

module.exports = User;

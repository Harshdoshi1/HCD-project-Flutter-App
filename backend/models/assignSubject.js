const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const Batch = require("./batch");
const Semester = require("./semester");
const UniqueSubDegree = require("./uniqueSubDegree");
const UniqueSubDiploma = require("./uniqueSubDiploma");

const AssignSubject = sequelize.define(
    "AssignSubject",
    {
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        batchId: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Batch,
                key: "id",
            },
        },
        semesterId: {
            type: DataTypes.INTEGER,
            allowNull: false,
        },
        facultyName: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        subjectCode: {
            type: DataTypes.STRING,
            allowNull: false,
        },
    },
    { timestamps: false }
);

// Relationships
AssignSubject.belongsTo(Batch, { foreignKey: "batchId" });
// AssignSubject.belongsTo(Semester, { foreignKey: "semesterId" });

// subjectCode can belong to either UniqueSubDegree or UniqueSubDiploma
AssignSubject.belongsTo(UniqueSubDegree, { foreignKey: "subjectCode", targetKey: "sub_code", constraints: false });
AssignSubject.belongsTo(UniqueSubDiploma, { foreignKey: "subjectCode", targetKey: "sub_code", constraints: false });

module.exports = AssignSubject;

const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const UniqueSubDegree = require("./uniqueSubDegree"); 
const Batch = require("./batch");
const Semester = require("./semester");

const ComponentWeightage = sequelize.define(
  "ComponentWeightage",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    subjectId: {
      type: DataTypes.STRING, // Change to match UniqueSubDegree.sub_code
      allowNull: false,
      references: {
        model: UniqueSubDegree, 
        key: "sub_code",
      },
    },
    batchId: {
      type: DataTypes.INTEGER,
      allowNull: true, // Temporarily allow nulls
      references: {
        model: Batch,
        key: "id",
      },
    },
    semesterId: {
      type: DataTypes.INTEGER,
      allowNull: true, // Temporarily allow nulls
      references: {
        model: Semester,
        key: "id",
      },
    },
    ese: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    cse: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    ia: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    tw: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    viva: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
  },
  { timestamps: false }
);

// Associations

ComponentWeightage.belongsTo(UniqueSubDegree, { foreignKey: "subjectId", targetKey: "sub_code" });
ComponentWeightage.belongsTo(Batch, { foreignKey: "batchId" });
ComponentWeightage.belongsTo(Semester, { foreignKey: "semesterId" });

module.exports = ComponentWeightage;

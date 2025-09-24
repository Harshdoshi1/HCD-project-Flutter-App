const ComponentWeightage = require("../models/componentWeightage");
const Batch = require("../models/batch");
const Semester = require("../models/semester");
const UniqueSubDegree = require("../models/uniqueSubDegree");

// ✅ Create Component Weightage
const createComponentWeightage = async (req, res) => {
  try {
    console.log("Received request body:", req.body);
    const { batch, semester, subject, ese, cse, ia, tw, viva } = req.body;

    // Fetch Batch ID
    const batchRecord = await Batch.findOne({ where: { batchName: batch } });
    if (!batchRecord) return res.status(400).json({ error: "Batch not found" });

    // Fetch Semester ID
    const semesterRecord = await Semester.findOne({ where: { semesterNumber: semester, batchId: batchRecord.id } });
    if (!semesterRecord) return res.status(400).json({ error: "Semester not found" });

    // Fetch Subject ID
    const subjectRecord = await UniqueSubDegree.findOne({ where: { sub_name: subject } });
    if (!subjectRecord) return res.status(400).json({ error: "Subject not found" });

    // Create Component Weightage
    const newWeightage = await ComponentWeightage.create({
      batchId: batchRecord.id,
      semesterId: semesterRecord.id,
      subjectId: subjectRecord.sub_code,
      ese,
      cse,
      ia,
      tw,
      viva,
    });

    console.log("Created Component Weightage:", newWeightage);
    res.status(201).json(newWeightage);
  } catch (error) {
    console.error("Error in createComponentWeightage:", error);
    res.status(500).json({ error: error.message });
  }
};

// ✅ Get All Component Weightages
const getAllComponentWeightages = async (req, res) => {
  try {
    const weightages = await ComponentWeightage.findAll({
      include: [
        { model: Batch, attributes: ["batchName"] },
        { model: Semester, attributes: ["semesterNumber"] },
        { model: UniqueSubDegree, attributes: ["sub_name"] },
      ],
    });

    res.status(200).json(weightages);
  } catch (error) {
    console.error("Error in getAllComponentWeightages:", error);
    res.status(500).json({ error: error.message });
  }
};

// ✅ Get Component Weightage by ID
const getComponentWeightageById = async (req, res) => {
  try {
    const { id } = req.params;
    const weightage = await ComponentWeightage.findByPk(id, {
      include: [
        { model: Batch, attributes: ["batchName"] },
        { model: Semester, attributes: ["semesterNumber"] },
        { model: UniqueSubDegree, attributes: ["sub_name"] },
      ],
    });

    if (!weightage) return res.status(404).json({ error: "Component Weightage not found" });

    res.status(200).json(weightage);
  } catch (error) {
    console.error("Error in getComponentWeightageById:", error);
    res.status(500).json({ error: error.message });
  }
};

// ✅ Update Component Weightage
const updateComponentWeightage = async (req, res) => {
  try {
    const { id } = req.params;
    const { ese, cse, ia, tw, viva } = req.body;

    const weightage = await ComponentWeightage.findByPk(id);
    if (!weightage) return res.status(404).json({ error: "Component Weightage not found" });

    // Update values
    await weightage.update({ ese, cse, ia, tw, viva });

    console.log("Updated Component Weightage:", weightage);
    res.status(200).json(weightage);
  } catch (error) {
    console.error("Error in updateComponentWeightage:", error);
    res.status(500).json({ error: error.message });
  }
};

// ✅ Delete Component Weightage
const deleteComponentWeightage = async (req, res) => {
  try {
    const { id } = req.params;

    const weightage = await ComponentWeightage.findByPk(id);
    if (!weightage) return res.status(404).json({ error: "Component Weightage not found" });

    await weightage.destroy();

    console.log("Deleted Component Weightage:", weightage);
    res.status(200).json({ message: "Component Weightage deleted successfully" });
  } catch (error) {
    console.error("Error in deleteComponentWeightage:", error);
    res.status(500).json({ error: error.message });
  }
};


// Get Component Weightages by Subject Code
const getComponentWeightagesBySubjectCode = async (req, res) => {
  try {
    const { subjectCode } = req.params;
    
    const weightages = await ComponentWeightage.findAll({
      where: { subjectId: subjectCode }, // Query by subjectId which stores the subject code
      include: [
        { model: Batch, attributes: ["batchName"] },
        { model: Semester, attributes: ["semesterNumber"] },
        { model: UniqueSubDegree, attributes: ["sub_name"] }, // subject_name is included
      ],
    });

    if (!weightages || weightages.length === 0) {
      return res.status(404).json({ error: "Component Weightages not found for this subject code" });
    }

    res.status(200).json(weightages);
  } catch (error) {
    console.error("Error in getComponentWeightagesBySubjectCode:", error);
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  updateComponentWeightage,
  deleteComponentWeightage,
  getComponentWeightageById,
  getAllComponentWeightages,
  createComponentWeightage,
  getComponentWeightagesBySubjectCode // Export the new function
};


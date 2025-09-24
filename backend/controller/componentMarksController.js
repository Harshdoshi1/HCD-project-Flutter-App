const ComponentMarks = require("../models/componentMarks");
const ComponentWeightage = require("../models/componentWeightage");
const UniqueSubDegree = require("../models/uniqueSubDegree");

// Create Component Marks
const createComponentMarks = async (req, res) => {
  try {
    console.log("Received request body:", req.body);
    const { subject, ese, cse, ia, tw, viva } = req.body;

    // Fetch Subject ID
    const subjectRecord = await UniqueSubDegree.findOne({ where: { sub_code: subject } });
    if (!subjectRecord) return res.status(400).json({ error: "Subject not found" });

    // Create Component Marks
    const newMarks = await ComponentMarks.create({

      subjectId: subjectRecord.sub_code,
      ese,
      cse,
      ia,
      tw,
      viva,
    });

    console.log("Created Component Marks:", newMarks);
    res.status(201).json(newMarks);
  } catch (error) {
    console.error("Error in createComponentMarks:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get All Component Marks
const getAllComponentMarks = async (req, res) => {
  try {
    const marks = await ComponentMarks.findAll({
      include: [
        { model: UniqueSubDegree, attributes: ["sub_name"] },
      ],
    });

    res.status(200).json(marks);
  } catch (error) {
    console.error("Error in getAllComponentMarks:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get Component Marks by ID
const getComponentMarksById = async (req, res) => {
  try {
    const { id } = req.params;
    const marks = await ComponentMarks.findByPk(id, {
      include: [
        { model: UniqueSubDegree, attributes: ["sub_name"] },
      ],
    });

    if (!marks) return res.status(404).json({ error: "Component Marks not found" });

    res.status(200).json(marks);
  } catch (error) {
    console.error("Error in getComponentMarksById:", error);
    res.status(500).json({ error: error.message });
  }
};

// Update Component Marks
const updateComponentMarks = async (req, res) => {
  try {
    const { id } = req.params;
    const { ese, cse, ia, tw, viva } = req.body;

    const marks = await ComponentMarks.findByPk(id);
    if (!marks) return res.status(404).json({ error: "Component Marks not found" });

    // Update values
    await marks.update({ ese, cse, ia, tw, viva });

    console.log("Updated Component Marks:", marks);
    res.status(200).json(marks);
  } catch (error) {
    console.error("Error in updateComponentMarks:", error);
    res.status(500).json({ error: error.message });
  }
};

// Delete Component Marks
const deleteComponentMarks = async (req, res) => {
  try {
    const { id } = req.params;

    const marks = await ComponentMarks.findByPk(id);
    if (!marks) return res.status(404).json({ error: "Component Marks not found" });

    await marks.destroy();

    console.log("Deleted Component Marks:", marks);
    res.status(200).json({ message: "Component Marks deleted successfully" });
  } catch (error) {
    console.error("Error in deleteComponentMarks:", error);
    res.status(500).json({ error: error.message });
  }
};

const addSubjectWithComponents = async (req, res) => {
  try {
    const { subject, name, credits, componentsWeightage, componentsMarks } = req.body;

    // Fetch Subject ID
    const subjectRecord = await UniqueSubDegree.findOne({ where: { sub_code: subject } });
    if (!subjectRecord) return res.status(400).json({ error: "Subject not found" });

    // Update credits and name in UniqueSubDegree
    const updateData = {};
    if (typeof credits === 'number') {
      updateData.credits = credits;
    }
    if (name) {
      updateData.sub_name = name;
    }
    
    await subjectRecord.update(updateData);

    // Prepare mapping helper
    function mapComponents(components) {
      const map = { ESE: 0, CSE: 0, IA: 0, TW: 0, VIVA: 0 };
      if (Array.isArray(components)) {
        components.forEach(comp => {
          if (comp.name && typeof comp.value === 'number') {
            let key = comp.name.toUpperCase();
            // Normalize 'CA' to 'CSE' to match database column
            if (key === 'CA') key = 'CSE';
            if (map.hasOwnProperty(key)) {
              map[key] = comp.value;
            }
          } else if (comp.name && typeof comp.weightage === 'number') {
            // fallback for weightage
            let key = comp.name.toUpperCase();
            // Normalize 'CA' to 'CSE' to match database column
            if (key === 'CA') key = 'CSE';
            if (map.hasOwnProperty(key)) {
              map[key] = comp.weightage;
            }
          }
        });
      }
      return map;
    }

    // Map weightages
    const weightageMap = mapComponents(componentsWeightage);
    // Map marks
    const marksMap = mapComponents(componentsMarks);

    // Insert into ComponentWeightage (now uses 'cse' field like ComponentMarks)
    const newWeightage = await ComponentWeightage.create({
      subjectId: subjectRecord.sub_code,
      ese: weightageMap.ESE,
      cse: weightageMap.CSE,  // Both tables now use 'cse' field
      ia: weightageMap.IA,
      tw: weightageMap.TW,
      viva: weightageMap.VIVA
    });

    // Insert into ComponentMarks
    const newMarks = await ComponentMarks.create({
      subjectId: subjectRecord.sub_code,
      ese: marksMap.ESE,
      cse: marksMap.CSE,
      ia: marksMap.IA,
      tw: marksMap.TW,
      viva: marksMap.VIVA
    });

    res.status(201).json({
      weightage: newWeightage,
      marks: newMarks
    });
  } catch (error) {
    console.error("Error in addSubjectWithComponents:", error);
    res.status(500).json({ error: error.message });
  }
};

// Get Component Marks by Subject Code
const getComponentMarksBySubject = async (req, res) => {
  try {
    const { subjectCode } = req.params;
    
    const marks = await ComponentMarks.findOne({
      where: { subjectId: subjectCode },
      include: [
        { model: UniqueSubDegree, attributes: ["sub_name"] },
      ],
    });

    if (!marks) return res.status(404).json({ error: "Component Marks not found for this subject" });

    res.status(200).json(marks);
  } catch (error) {
    console.error("Error in getComponentMarksBySubject:", error);
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  deleteComponentMarks, 
  addSubjectWithComponents, 
  updateComponentMarks, 
  getComponentMarksById, 
  getAllComponentMarks, 
  createComponentMarks,
  getComponentMarksBySubject
}

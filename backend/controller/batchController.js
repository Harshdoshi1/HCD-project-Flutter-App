const Batch = require("../models/batch");


const getBatchIdByName = async (req, res) => {
    try {
        const batchName = req.params.batchName;
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }
        res.json({ batchId: batch.id });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

const getCurrentSemester = async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    if (isNaN(batchId)) {
      return res.status(400).json({ message: "Invalid batch id" });
    }

    // Fetch the row from Semester table where batchId matches
    const semester = await Semester.findOne({ where: { batchId } });

    if (!semester) {
      return res.status(404).json({ message: "Semester not found" });
    }

    // Return the current semester number
    res.json({ currentSemester: semester.semesterNumber }); // or semester.currentSemester
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

const addBatch = async (req, res) => {
    try {
        const { batchName, batchStart, batchEnd, courseType } = req.body;

        // Check for existing batch with same name
        const existingBatch = await Batch.findOne({ where: { batchName } });
        if (existingBatch) {
            return res.status(400).json({ message: 'A batch with this name already exists' });
        }

        // Validate that batchStart and batchEnd are dates
        if (isNaN(new Date(batchStart).getTime()) || isNaN(new Date(batchEnd).getTime())) {
            return res.status(400).json({ message: "Invalid date format for batchStart or batchEnd" });
        }

        // Validate that courseType is either "Degree" or "Diploma"
        if (!['Degree', 'Diploma'].includes(courseType)) {
            return res.status(400).json({ message: "Invalid courseType. It must be 'Degree' or 'Diploma'" });
        }

        // Create the new batch
        const batch = await Batch.create({
            batchName,
            batchStart: new Date(batchStart),  // Convert to Date object
            batchEnd: new Date(batchEnd),      // Convert to Date object
            courseType,
        });

        res.status(201).json({ message: "Batch created successfully", batch });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

const getAllBatches = async (req, res) => {
    try {
        const batches = await Batch.findAll(); // Sequelize equivalent of find()
        res.status(200).json(batches);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};




module.exports = {
    getAllBatches, addBatch,getBatchIdByName,getCurrentSemester
}

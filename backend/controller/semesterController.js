const express = require('express');
const router = express.Router();
const Semester = require("../models/semester.js");
const Batch = require('../models/batch.js');
const ClassSection = require('../models/classSection.js');
// Import associations to ensure they are loaded
require("../models/associations");

// const { Semester } = require('../models');
const getSemesterIdByNumber = async (req, res) => {
    try {
        const semesterNumber = parseInt(req.params.semesterNumber);
        if (isNaN(semesterNumber)) {
            return res.status(400).json({ message: "Invalid semester number" });
        }
        const semester = await Semester.findOne({ where: { semesterNumber } });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found" });
        }
        res.json({ semesterId: semester.id });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};


const getSemesterNumberById = async (req, res) => {
  try {
    const semesterId = parseInt(req.params.semesterId);
    if (isNaN(semesterId)) {
      return res.status(400).json({ message: "Invalid semester id" });
    }

    // Fetch the row from Semester table where id matches
    const semester = await Semester.findOne({ where: { id: semesterId } });

    if (!semester) {
      return res.status(404).json({ message: "Semester not found" });
    }

    // Return the semesterNumber field
    res.json({ semesterNumber: semester.semesterNumber });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};



const addSemester = async (req, res) => {
    try {
        const { batchName, semesterNumber, startDate, endDate, numberOfClasses, classes } = req.body;

        if (!batchName || !semesterNumber || !startDate || !endDate) {
            return res.status(400).json({ message: "All fields are required." });
        }

        // Find batch
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found." });
        }

        // Create semester
        const newSemester = await Semester.create({
            batchId: batch.id,
            semesterNumber,
            startDate,
            endDate
        });

        // Update currentSemester in batch table
        await batch.update({ currentSemester: semesterNumber });

        let classSections = [];

        // Handle class sections if provided
        if (numberOfClasses && numberOfClasses > 0 && classes && Array.isArray(classes)) {
            // Validate classes array
            if (classes.length !== parseInt(numberOfClasses)) {
                return res.status(400).json({ message: "Number of classes doesn't match the classes array." });
            }

            // Create class sections
            for (let i = 0; i < classes.length; i++) {
                const classData = classes[i];
                const classLetter = String.fromCharCode(65 + i); // A, B, C, etc.

                if (!classData.name || !classData.name.trim()) {
                    return res.status(400).json({ message: `Class name is required for class ${classLetter}.` });
                }

                const classSection = await ClassSection.create({
                    semesterId: newSemester.id,
                    batchId: batch.id,
                    className: classData.name.trim(),
                    classLetter: classLetter,
                    studentCount: 0, // Will be updated when students are added
                    excelFileName: classData.excelFile ? classData.excelFile.name : null,
                    isActive: true
                });

                classSections.push(classSection);
            }
        }

        res.status(201).json({
            message: "Semester added successfully",
            semester: newSemester,
            classSections: classSections
        });

    } catch (error) {
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};


const getSemestersByBatch = async (req, res) => {
    try {
        console.log("Received request with params:", req.params); // Debugging log

        const { batchName } = req.params; // Use params instead of query
        if (!batchName) {
            console.log("❌ Missing batchName in request.");
            return res.status(400).json({ message: "Batch name is required." });
        }

        console.log(`🔍 Searching for batch: ${batchName}`);
        const batch = await Batch.findOne({ where: { batchName } });

        if (!batch) {
            console.log(`❌ Batch '${batchName}' not found in DB.`);
            return res.status(404).json({ message: "Batch not found." });
        }

        console.log(`✅ Found batch with ID: ${batch.id}, fetching semesters...`);
        const semesters = await Semester.findAll({
            where: { batchId: batch.id },
            include: [{
                model: ClassSection,
                as: 'classSections',
                where: { isActive: true },
                required: false
            }],
            order: [['semesterNumber', 'ASC']]
        });

        if (!semesters.length) {
            console.log(`⚠️ No semesters found for batch ID: ${batch.id}`);
            return res.status(404).json({ message: "No semesters found for this batch." });
        }

        console.log(`✅ Found ${semesters.length} semesters. Sending response.`);
        res.status(200).json(semesters);
    } catch (error) {
        console.error("❌ Server Error:", error.message);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

// New: Get semesters by batch ID (numeric ID)
const getSemestersByBatchId = async (req, res) => {
    try {
        const { batchId } = req.params;

        if (!batchId) {
            return res.status(400).json({ message: "Batch ID is required." });
        }

        // Optional: verify batch exists
        const batch = await Batch.findByPk(batchId);
        if (!batch) {
            return res.status(404).json({ message: "Batch not found." });
        }

        const semesters = await Semester.findAll({
            where: { batchId: batch.id },
            include: [{
                model: ClassSection,
                as: 'classSections',
                where: { isActive: true },
                required: false
            }],
            order: [['semesterNumber', 'ASC']]
        });

        if (!semesters || semesters.length === 0) {
            return res.status(404).json({ message: "No semesters found for this batch." });
        }

        return res.status(200).json(semesters);
    } catch (error) {
        console.error("❌ Server Error:", error.message);
        return res.status(500).json({ message: "Server Error", error: error.message });
    }
};



module.exports = {
    getSemestersByBatch,
    getSemestersByBatchId,
    addSemester,
    getSemesterIdByNumber,
    getSemesterNumberById
};


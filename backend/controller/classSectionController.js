const ClassSection = require("../models/classSection");
const Semester = require("../models/semester");
const Batch = require("../models/batch");
// Import associations to ensure they are loaded
require("../models/associations");

const addClassSections = async (req, res) => {
    try {
        const { batchName, semesterNumber, numberOfClasses, classes } = req.body;

        if (!batchName || !semesterNumber || !numberOfClasses || !classes) {
            return res.status(400).json({ message: "All fields are required." });
        }

        // Find batch
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found." });
        }

        // Find semester
        const semester = await Semester.findOne({
            where: {
                batchId: batch.id,
                semesterNumber: semesterNumber
            }
        });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found." });
        }

        // Validate classes array
        if (!Array.isArray(classes) || classes.length !== parseInt(numberOfClasses)) {
            return res.status(400).json({ message: "Invalid classes data." });
        }

        // Create class sections
        const classSections = [];
        for (let i = 0; i < classes.length; i++) {
            const classData = classes[i];
            const classLetter = String.fromCharCode(65 + i); // A, B, C, etc.

            if (!classData.name || !classData.name.trim()) {
                return res.status(400).json({ message: `Class name is required for class ${classLetter}.` });
            }

            const classSection = await ClassSection.create({
                semesterId: semester.id,
                batchId: batch.id,
                className: classData.name.trim(),
                classLetter: classLetter,
                studentCount: 0, // Will be updated when students are added
                excelFileName: classData.excelFile ? classData.excelFile.name : null,
                isActive: true
            });

            classSections.push(classSection);
        }

        res.status(201).json({
            message: "Class sections added successfully",
            classSections: classSections
        });

    } catch (error) {
        console.error("Error adding class sections:", error);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

const getClassSectionsBySemester = async (req, res) => {
    try {
        const { batchName, semesterNumber } = req.params;

        if (!batchName || !semesterNumber) {
            return res.status(400).json({ message: "Batch name and semester number are required." });
        }

        // Find batch
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found." });
        }

        // Find semester
        const semester = await Semester.findOne({
            where: {
                batchId: batch.id,
                semesterNumber: semesterNumber
            }
        });
        if (!semester) {
            return res.status(404).json({ message: "Semester not found." });
        }

        // Get class sections
        const classSections = await ClassSection.findAll({
            where: {
                semesterId: semester.id,
                isActive: true
            },
            order: [['classLetter', 'ASC']]
        });

        res.status(200).json(classSections);

    } catch (error) {
        console.error("Error fetching class sections:", error);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

const getSemesterWiseBatchInfo = async (req, res) => {
    try {
        const { batchName } = req.params;

        if (!batchName) {
            return res.status(400).json({ message: "Batch name is required." });
        }

        // Find batch
        const batch = await Batch.findOne({ where: { batchName } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found." });
        }

        // Get all semesters for the batch with their class sections
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

        // Process real data from ClassSections table
        const semesterInfo = semesters.map(semester => {
            const classSections = semester.classSections || [];
            const totalClasses = classSections.length;

            // Calculate real totals from ClassSections data
            let totalStudents = 0;
            let studentsPerClass = 0;

            if (totalClasses > 0) {
                totalStudents = classSections.reduce((sum, cls) => sum + (cls.studentCount || 0), 0);
                studentsPerClass = Math.round(totalStudents / totalClasses);
            }

            return {
                semesterNumber: semester.semesterNumber,
                startDate: semester.startDate,
                endDate: semester.endDate,
                totalStudents: totalStudents,
                totalClasses: totalClasses,
                studentsPerClass: studentsPerClass,
                classes: classSections.map(cls => ({
                    id: cls.id,
                    name: cls.className,
                    letter: cls.classLetter,
                    students: cls.studentCount || 0
                }))
            };
        });

        res.status(200).json({
            batchName: batch.batchName,
            courseType: batch.courseType,
            batchStart: batch.batchStart,
            batchEnd: batch.batchEnd,
            totalSemesters: semesters.length,
            semesters: semesterInfo
        });

    } catch (error) {
        console.error("Error fetching semester-wise batch info:", error);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

const updateClassSection = async (req, res) => {
    try {
        const { classSectionId } = req.params;
        const { className, studentCount, excelFileName } = req.body;

        const classSection = await ClassSection.findByPk(classSectionId);
        if (!classSection) {
            return res.status(404).json({ message: "Class section not found." });
        }

        // Update fields
        if (className) classSection.className = className;
        if (studentCount !== undefined) classSection.studentCount = studentCount;
        if (excelFileName !== undefined) classSection.excelFileName = excelFileName;

        await classSection.save();

        res.status(200).json({
            message: "Class section updated successfully",
            classSection: classSection
        });

    } catch (error) {
        console.error("Error updating class section:", error);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

const deleteClassSection = async (req, res) => {
    try {
        const { classSectionId } = req.params;

        const classSection = await ClassSection.findByPk(classSectionId);
        if (!classSection) {
            return res.status(404).json({ message: "Class section not found." });
        }

        // Soft delete by setting isActive to false
        classSection.isActive = false;
        await classSection.save();

        res.status(200).json({ message: "Class section deleted successfully" });

    } catch (error) {
        console.error("Error deleting class section:", error);
        res.status(500).json({ message: "Server Error", error: error.message });
    }
};

module.exports = {
    addClassSections,
    getClassSectionsBySemester,
    getSemesterWiseBatchInfo,
    updateClassSection,
    deleteClassSection
}; 
const Gettedmarks = require("../models/gettedmarks");
const Student = require("../models/students");
const UniqueSubDegree = require("../models/uniqueSubDegree");
const Batch = require("../models/batch");
const AssignSubject = require("../models/assignSubject");

exports.getStudentMarksByBatchAndSubject = async (req, res) => {
    try {
        const { batchId } = req.params;
        console.log("Received check:", batchId);

        const students = await Student.findAll({ where: { batchId: batchId } });

        if (!students || students.length === 0) {
            return res.status(404).json({ message: "No students found for this batch" });
        }

        console.log('Students:', students);

        res.status(200).json(students.map(student => student.toJSON()));
    } catch (error) {
        console.error("Error fetching student marks:", error);
        res.status(500).json({ message: "Error fetching student marks", error: error.stack });
    }
};
exports.getStudentsByBatchAndSemester = async (req, res) => {
    try {
        const { batchId, semesterId } = req.params;
        console.log("Received check:", batchId, semesterId);

        const students = await Student.findAll({ where: { batchId: batchId, currnetsemester: semesterId } });

        if (!students || students.length === 0) {
            return res.status(404).json({ message: "No students found for this batch and semester" });
        }

        console.log('Students:', students);

        res.status(200).json(students.map(student => student.toJSON()));
    } catch (error) {
        console.error("Error fetching students:", error);
        res.status(500).json({ message: "Error fetching students", error: error.stack });
    }
};
exports.getStudentMarksByBatchAndSubject1 = async (req, res) => {
    try {
        const { batchId } = req.params;
        console.log("Received check:", batchId);

        const batch = await Batch.findOne({ where: { batchName: batchId } });
        if (!batch) {
            return res.status(404).json({ message: "Batch not found" });
        }

        // console.log('Batch:', batch);

        const students = await Student.findAll({ where: { batchId: batch.id } });

        if (!students || students.length === 0) {
            return res.status(404).json({ message: "No students found for this batch" });
        }

        console.log('Students:', students);

        res.status(200).json(students.map(student => student.toJSON()));
    } catch (error) {
        console.error("Error fetching student marks:", error);
        res.status(500).json({ message: "Error fetching student marks", error: error.stack });
    }
};

exports.updateStudentMarks = async (req, res) => {
    try {
        const { studentId, subjectId } = req.params;
        const { ese, cse, ia, tw, viva, facultyId, response } = req.body;

        console.log('Updating marks for student:', studentId, 'and subject:', subjectId);

        // Ensure subject exists
        const subjectExists = await UniqueSubDegree.findOne({
            where: { sub_code: subjectId }
        });

        if (!subjectExists) {
            return res.status(400).json({ error: `Subject ID ${subjectId} does not exist.` });
        }

        const [marks, created] = await Gettedmarks.findOrCreate({
            where: { studentId, subjectId },
            defaults: {
                facultyId,
                ese: ese || 0,
                cse: cse || 0,
                ia: ia || 0,
                tw: tw || 0,
                viva: viva || 0,
                facultyResponse: response || ''
            }
        });

        if (!created) {
            await marks.update({
                facultyId,
                ...(ese !== undefined && { ese }),
                ...(cse !== undefined && { cse }),
                ...(ia !== undefined && { ia }),
                ...(tw !== undefined && { tw }),
                ...(viva !== undefined && { viva }),
                ...(response !== undefined && { facultyResponse: response })
            });
        }

        res.status(200).json({ message: 'Marks updated successfully', data: marks });

    } catch (error) {
        console.error("Error updating student marks:", error);
        res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
};

exports.getSubjectNamefromCode = async (req, res) => {
    try {
        const { subjectCode } = req.params;
        const subject = await UniqueSubDegree.findOne({ where: { sub_code: subjectCode } });
        if (!subject) {
            return res.status(404).json({ message: "Subject not found" });
        }
        res.status(200).json({ subjectName: subject.sub_name });
    } catch (error) {
        console.error("Error fetching subject name:", error);
        res.status(500).json({ message: "Error fetching subject name", error: error.stack });
    }
};

exports.getBatchIdfromName = async (req, res) => {
    try {
        const { batchName } = req.params;
        
        if (!batchName) {
            return res.status(400).json({ error: "Batch name is required" });
        }

        const batch = await Batch.findOne({
            where: { batchName }
        });

        if (!batch) {
            return res.status(404).json({ error: `Batch with name ${batchName} not found` });
        }

        res.status(200).json({ batchId: batch.id });
    } catch (error) {
        console.error("Error fetching batch ID:", error);
        res.status(500).json({ message: "Error fetching batch ID", error: error.stack });
    }
};

exports.getSubjectByBatchAndSemester = async (req, res) => {
    try {
        const { batchId, semesterId, facultyName } = req.params;

        if (!facultyName) {
            return res.status(400).json({ error: "Faculty name is required" });
        }

        const assignedSubjects = await AssignSubject.findAll({
            where: {
                batchId,
                semesterId,
                facultyName
            },
            attributes: ['subjectCode'], // fetch only subjectCode
            order: [['facultyName', 'ASC']] // optional if needed
        });

        res.status(200).json(assignedSubjects);
    } catch (error) {
        console.error("Error fetching assigned subjects:", error);
        res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
};

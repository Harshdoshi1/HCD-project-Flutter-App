const { StudentMarks, Student, User, UniqueSubDegree, Semester, Batch, SubComponents, ComponentWeightage, ComponentMarks } = require('../models');
const { calculateAndStoreBloomsDistributionDirect } = require('./bloomsDistributionController');
const { Op } = require('sequelize');

// Get student marks with sub-components for a specific subject
const getStudentMarksWithSubComponents = async (req, res) => {
    try {
        const { batchId, semesterNumber, subjectCode } = req.params;

        // Find semester ID
        const semester = await Semester.findOne({
            where: { 
                semesterNumber: parseInt(semesterNumber),
                batchId: parseInt(batchId)
            }
        });

        if (!semester) {
            return res.status(404).json({ error: 'Semester not found for this batch' });
        }

        // Get students with their marks for this subject
        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) },
            include: [{
                model: StudentMarks,
                as: 'studentMarks',
                where: {
                    subjectId: subjectCode,
                    semesterId: semester.id
                },
                required: false,
                include: [{
                    model: SubComponents,
                    as: 'subComponent',
                    required: false
                }]
            }]
        });

        // Get subject components and sub-components structure
        const componentWeightage = await ComponentWeightage.findOne({
            where: { subjectId: subjectCode }
        });

        let subComponents = [];
        if (componentWeightage) {
            subComponents = await SubComponents.findAll({
                where: { componentWeightageId: componentWeightage.id },
                order: [['componentType', 'ASC'], ['subComponentName', 'ASC']]
            });
        }

        res.status(200).json({
            students,
            subComponents,
            semester: semester
        });
    } catch (error) {
        console.error('Error fetching student marks with sub-components:', error);
        res.status(500).json({ error: error.message });
    }
};

// Update or create student marks for components and sub-components
const updateStudentMarks = async (req, res) => {
    try {
        const { studentId, subjectCode } = req.params;
        const { 
            facultyId, 
            marks, // Object containing component marks and sub-component marks
            facultyResponse, 
            facultyRating,
            semesterId,
            batchId,
            enrollmentSemester
        } = req.body;

        console.log('Updating student marks:', { studentId, subjectCode, marks });

        // Validate required fields
        if (!facultyId || !semesterId || !batchId || !enrollmentSemester) {
            return res.status(400).json({ error: 'Missing required fields: facultyId, semesterId, batchId, enrollmentSemester' });
        }

        const updatedMarks = [];

        // Process each component and its marks
        for (const [componentType, componentData] of Object.entries(marks)) {
            if (componentData.subComponents && Array.isArray(componentData.subComponents)) {
                // Handle sub-components
                for (const subComponentData of componentData.subComponents) {
                    const existingMark = await StudentMarks.findOne({
                        where: {
                            studentId: parseInt(studentId),
                            subjectId: subjectCode,
                            semesterId: parseInt(semesterId),
                            subComponentId: subComponentData.subComponentId,
                            componentType: componentType.toUpperCase()
                        }
                    });

                    const markData = {
                        studentId: parseInt(studentId),
                        facultyId: parseInt(facultyId),
                        subjectId: subjectCode,
                        semesterId: parseInt(semesterId),
                        batchId: parseInt(batchId),
                        subComponentId: subComponentData.subComponentId,
                        componentType: componentType.toUpperCase(),
                        componentName: subComponentData.name,
                        marksObtained: parseFloat(subComponentData.marksObtained) || 0,
                        totalMarks: parseInt(subComponentData.totalMarks) || 0,
                        facultyResponse: facultyResponse || '',
                        facultyRating: parseInt(facultyRating) || 0,
                        isSubComponent: true,
                        enrollmentSemester: parseInt(enrollmentSemester)
                    };

                    let updatedMark;
                    if (existingMark) {
                        await existingMark.update(markData);
                        updatedMark = existingMark;
                    } else {
                        updatedMark = await StudentMarks.create(markData);
                    }
                    updatedMarks.push(updatedMark);
                }
            } else {
                // Handle main component (no sub-components)
                const existingMark = await StudentMarks.findOne({
                    where: {
                        studentId: parseInt(studentId),
                        subjectId: subjectCode,
                        semesterId: parseInt(semesterId),
                        componentType: componentType.toUpperCase(),
                        isSubComponent: false
                    }
                });

                const markData = {
                    studentId: parseInt(studentId),
                    facultyId: parseInt(facultyId),
                    subjectId: subjectCode,
                    semesterId: parseInt(semesterId),
                    batchId: parseInt(batchId),
                    subComponentId: null,
                    componentType: componentType.toUpperCase(),
                    componentName: null,
                    marksObtained: parseFloat(componentData.marksObtained) || 0,
                    totalMarks: parseInt(componentData.totalMarks) || 0,
                    facultyResponse: facultyResponse || '',
                    facultyRating: parseInt(facultyRating) || 0,
                    isSubComponent: false,
                    enrollmentSemester: parseInt(enrollmentSemester)
                };

                let updatedMark;
                if (existingMark) {
                    await existingMark.update(markData);
                    updatedMark = existingMark;
                } else {
                    updatedMark = await StudentMarks.create(markData);
                }
                updatedMarks.push(updatedMark);
            }
        }

        // After successfully updating marks, trigger weighted Bloom's distribution calculation
        try {
            const student = await Student.findByPk(studentId);
            if (student) {
                // Pass subject ID to calculate distribution for the specific subject
                await calculateAndStoreBloomsDistributionDirect(
                    student.enrollmentNumber, 
                    enrollmentSemester,
                    subjectCode
                );
                console.log(`Weighted Bloom's distribution calculated for student ${student.enrollmentNumber}, semester ${enrollmentSemester}, subject ${subjectCode}`);
            }
        } catch (bloomsError) {
            console.error('Error calculating weighted Bloom\'s distribution:', bloomsError);
            // Don't fail the main operation if Bloom's calculation fails
        }

        res.status(200).json({
            message: 'Student marks updated successfully',
            data: updatedMarks
        });
    } catch (error) {
        console.error('Error updating student marks:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get student marks for grading interface
const getStudentMarksForGrading = async (req, res) => {
    try {
        const { batchId, semesterNumber } = req.params;

        // Find semester
        const semester = await Semester.findOne({
            where: { 
                semesterNumber: parseInt(semesterNumber),
                batchId: parseInt(batchId)
            }
        });

        if (!semester) {
            return res.status(404).json({ error: 'Semester not found for this batch' });
        }

        // Get students with their marks
        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) },
            include: [{
                model: StudentMarks,
                as: 'studentMarks',
                where: { semesterId: semester.id },
                required: false,
                include: [{
                    model: SubComponents,
                    as: 'subComponent',
                    required: false
                }, {
                    model: UniqueSubDegree,
                    as: 'subject',
                    required: false
                }]
            }],
            order: [['name', 'ASC']]
        });

        res.status(200).json(students);
    } catch (error) {
        console.error('Error fetching student marks for grading:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get subject components with sub-components for grading
const getSubjectComponentsForGrading = async (req, res) => {
    try {
        const { subjectCode } = req.params;

        // Get component weightage and marks
        const componentWeightage = await ComponentWeightage.findOne({
            where: { subjectId: subjectCode }
        });

        const componentMarks = await ComponentMarks.findOne({
            where: { subjectId: subjectCode }
        });

        if (!componentWeightage || !componentMarks) {
            return res.status(404).json({ error: 'Component configuration not found for this subject' });
        }

        // Get sub-components
        const subComponents = await SubComponents.findAll({
            where: { componentWeightageId: componentWeightage.id },
            order: [['componentType', 'ASC'], ['subComponentName', 'ASC']]
        });

        // Structure the response to match frontend expectations
        const componentStructure = {
            CA: { enabled: componentWeightage.ca > 0, totalMarks: componentMarks.cse, subComponents: [] },
            ESE: { enabled: componentWeightage.ese > 0, totalMarks: componentMarks.ese, subComponents: [] },
            IA: { enabled: componentWeightage.ia > 0, totalMarks: componentMarks.ia, subComponents: [] },
            TW: { enabled: componentWeightage.tw > 0, totalMarks: componentMarks.tw, subComponents: [] },
            VIVA: { enabled: componentWeightage.viva > 0, totalMarks: componentMarks.viva, subComponents: [] }
        };

        // Group sub-components by component type
        subComponents.forEach(subComp => {
            if (componentStructure[subComp.componentType]) {
                componentStructure[subComp.componentType].subComponents.push({
                    id: subComp.id,
                    name: subComp.subComponentName,
                    totalMarks: subComp.totalMarks,
                    weightage: subComp.weightage,
                    selectedCOs: subComp.selectedCOs
                });
            }
        });

        res.status(200).json({
            componentWeightage,
            componentMarks,
            componentStructure,
            subComponents
        });
    } catch (error) {
        console.error('Error fetching subject components for grading:', error);
        res.status(500).json({ error: error.message });
    }
};

// Get existing student marks for a specific subject and semester
const getExistingStudentMarks = async (req, res) => {
    try {
        const { batchId, semesterNumber, subjectCode } = req.params;

        // Find semester ID
        const semester = await Semester.findOne({
            where: { 
                semesterNumber: parseInt(semesterNumber),
                batchId: parseInt(batchId)
            }
        });

        if (!semester) {
            return res.status(404).json({ error: 'Semester not found for this batch' });
        }

        // Get students with their marks for this subject
        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) },
            include: [{
                model: StudentMarks,
                as: 'studentMarks',
                where: {
                    subjectId: subjectCode,
                    semesterId: semester.id
                },
                required: false,
                include: [{
                    model: SubComponents,
                    as: 'subComponent',
                    required: false
                }]
            }],
            order: [['name', 'ASC']]
        });

        res.status(200).json({
            students,
            semester: semester
        });
    } catch (error) {
        console.error('Error fetching existing student marks:', error);
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    getStudentMarksWithSubComponents,
    updateStudentMarks,
    getStudentMarksForGrading,
    getSubjectComponentsForGrading,
    getExistingStudentMarks
};

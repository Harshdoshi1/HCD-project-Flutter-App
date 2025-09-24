const { 
    Student, 
    StudentBloomsDistribution, 
    BloomsTaxonomy, 
    UniqueSubDegree, 
    StudentMarks,
    CourseOutcome,
    SubComponents,
    ComponentWeightage
} = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/db');

/**
 * Get detailed Bloom's taxonomy achievement for a student
 * Shows marks distribution by components, COs, and Bloom's levels
 */
const getDetailedBloomsAchievement = async (req, res) => {
    try {
        const { enrollmentNumber, semesterNumber, subjectId } = req.params;
        
        // Find student
        const student = await Student.findOne({
            where: { enrollmentNumber }
        });
        
        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }
        
        // Build query conditions
        const queryConditions = {
            studentId: student.id,
            semesterNumber: parseInt(semesterNumber)
        };
        
        if (subjectId) {
            queryConditions.subjectId = subjectId;
        }
        
        // Get distribution data with associations
        const distributions = await StudentBloomsDistribution.findAll({
            where: queryConditions,
            include: [
                {
                    model: BloomsTaxonomy,
                    as: 'bloomsTaxonomy',
                    attributes: ['id', 'name', 'description']
                },
                {
                    model: UniqueSubDegree,
                    as: 'subject',
                    attributes: ['sub_code', 'sub_name']
                }
            ],
            order: [
                ['subjectId', 'ASC'],
                ['courseOutcomeId', 'ASC'],
                ['bloomsTaxonomyId', 'ASC']
            ]
        });
        
        // Process data for different views
        const analysis = {
            student: {
                enrollmentNumber: student.enrollmentNumber,
                name: student.name,
                id: student.id
            },
            semester: parseInt(semesterNumber),
            bySubject: {},
            byCourseOutcome: {},
            byBloomsLevel: {},
            byComponent: {},
            summary: {
                totalWeightedMarks: 0,
                totalPossibleMarks: 150, // Fixed at 150 per subject
                overallPercentage: 0
            }
        };
        
        // Get course outcomes for mapping
        const courseOutcomeIds = [...new Set(distributions.map(d => d.courseOutcomeId))];
        const courseOutcomes = await CourseOutcome.findAll({
            where: { id: courseOutcomeIds }
        });
        const coMap = {};
        courseOutcomes.forEach(co => {
            coMap[co.id] = { code: co.co_code, description: co.description };
        });
        
        // Process distributions
        const processedComponents = new Set(); // Track processed components to avoid duplication
        
        distributions.forEach(dist => {
            const subjectCode = dist.subjectId;
            const subjectName = dist.subject?.sub_name || subjectCode;
            const bloomsName = dist.bloomsTaxonomy?.name || `Bloom ID ${dist.bloomsTaxonomyId}`;
            const coInfo = coMap[dist.courseOutcomeId] || { code: `CO${dist.courseOutcomeId}`, description: '' };
            const componentKey = `${dist.studentMarksSubjectComponentId}`;
            
            // Initialize structures if needed
            if (!analysis.bySubject[subjectCode]) {
                analysis.bySubject[subjectCode] = {
                    name: subjectName,
                    totalWeightedMarks: 0,
                    totalPossibleMarks: 150,
                    components: {},
                    courseOutcomes: {},
                    bloomsLevels: {}
                };
            }
            
            if (!analysis.byCourseOutcome[coInfo.code]) {
                analysis.byCourseOutcome[coInfo.code] = {
                    description: coInfo.description,
                    totalMarks: 0,
                    subjects: {}
                };
            }
            
            if (!analysis.byBloomsLevel[bloomsName]) {
                analysis.byBloomsLevel[bloomsName] = {
                    totalMarks: 0,
                    subjects: {}
                };
            }
            
            if (!analysis.byComponent[componentKey]) {
                analysis.byComponent[componentKey] = {
                    componentId: dist.studentMarksSubjectComponentId,
                    weightage: dist.subComponentWeightage,
                    totalMarks: dist.totalMarksOfComponent,
                    assignedMarks: dist.assignedMarks,
                    courseOutcomes: []
                };
            }
            
            // Add component-level marks (only once per component)
            if (!processedComponents.has(componentKey)) {
                analysis.bySubject[subjectCode].totalWeightedMarks += dist.assignedMarks;
                analysis.summary.totalWeightedMarks += dist.assignedMarks;
                processedComponents.add(componentKey);
            }
            
            // Track component in subject
            if (!analysis.bySubject[subjectCode].components[componentKey]) {
                analysis.bySubject[subjectCode].components[componentKey] = {
                    weightage: dist.subComponentWeightage,
                    assignedMarks: dist.assignedMarks,
                    courseOutcomes: dist.selectedCOs
                };
            }
            
            // Track CO achievement
            if (!analysis.bySubject[subjectCode].courseOutcomes[coInfo.code]) {
                analysis.bySubject[subjectCode].courseOutcomes[coInfo.code] = {
                    description: coInfo.description,
                    marks: 0
                };
            }
            // Note: Each component's marks go to all its COs
            
            // Track Bloom's level achievement
            if (!analysis.bySubject[subjectCode].bloomsLevels[bloomsName]) {
                analysis.bySubject[subjectCode].bloomsLevels[bloomsName] = {
                    marks: 0
                };
            }
            
            // Add CO tracking
            if (!analysis.byComponent[componentKey].courseOutcomes.includes(coInfo.code)) {
                analysis.byComponent[componentKey].courseOutcomes.push(coInfo.code);
            }
        });
        
        // Calculate aggregated marks for COs and Bloom's levels
        for (const [subjectCode, subjectData] of Object.entries(analysis.bySubject)) {
            // Calculate percentage for subject
            subjectData.percentage = subjectData.totalPossibleMarks > 0 
                ? ((subjectData.totalWeightedMarks / subjectData.totalPossibleMarks) * 100).toFixed(2)
                : 0;
                
            // Aggregate marks by CO and Bloom's level
            distributions.forEach(dist => {
                if (dist.subjectId === subjectCode) {
                    const coInfo = coMap[dist.courseOutcomeId] || { code: `CO${dist.courseOutcomeId}` };
                    const bloomsName = dist.bloomsTaxonomy?.name || `Bloom ID ${dist.bloomsTaxonomyId}`;
                    const componentKey = `${dist.studentMarksSubjectComponentId}`;
                    
                    // Each CO gets marks from components mapped to it
                    if (subjectData.courseOutcomes[coInfo.code] && !subjectData.courseOutcomes[coInfo.code].processed) {
                        subjectData.courseOutcomes[coInfo.code].marks = dist.assignedMarks;
                    }
                    
                    // Each Bloom's level gets marks from components mapped to it
                    if (subjectData.bloomsLevels[bloomsName] && !subjectData.bloomsLevels[bloomsName].processed) {
                        subjectData.bloomsLevels[bloomsName].marks = dist.assignedMarks;
                    }
                    
                    // Global CO tracking
                    if (!analysis.byCourseOutcome[coInfo.code].subjects[subjectCode]) {
                        analysis.byCourseOutcome[coInfo.code].subjects[subjectCode] = {
                            name: subjectData.name,
                            marks: dist.assignedMarks
                        };
                        analysis.byCourseOutcome[coInfo.code].totalMarks += dist.assignedMarks;
                    }
                    
                    // Global Bloom's tracking
                    if (!analysis.byBloomsLevel[bloomsName].subjects[subjectCode]) {
                        analysis.byBloomsLevel[bloomsName].subjects[subjectCode] = {
                            name: subjectData.name,
                            marks: dist.assignedMarks
                        };
                        analysis.byBloomsLevel[bloomsName].totalMarks += dist.assignedMarks;
                    }
                }
            });
        }
        
        // Calculate overall percentage
        const totalSubjects = Object.keys(analysis.bySubject).length;
        if (totalSubjects > 0) {
            analysis.summary.totalPossibleMarks = totalSubjects * 150;
            analysis.summary.overallPercentage = analysis.summary.totalPossibleMarks > 0
                ? ((analysis.summary.totalWeightedMarks / analysis.summary.totalPossibleMarks) * 100).toFixed(2)
                : 0;
        }
        
        res.status(200).json(analysis);
        
    } catch (error) {
        console.error('Error fetching detailed Bloom\'s achievement:', error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Get Bloom's achievement comparison for multiple students
 */
const compareBloomsAchievement = async (req, res) => {
    try {
        const { batchId, semesterNumber, subjectId } = req.params;
        
        // Get all students in the batch
        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) }
        });
        
        if (!students.length) {
            return res.status(404).json({ error: 'No students found in this batch' });
        }
        
        const comparison = {
            batch: batchId,
            semester: parseInt(semesterNumber),
            subject: subjectId || 'All Subjects',
            students: [],
            bloomsLevelAverages: {},
            courseOutcomeAverages: {}
        };
        
        // Get all Bloom's levels
        const bloomsLevels = await BloomsTaxonomy.findAll();
        bloomsLevels.forEach(level => {
            comparison.bloomsLevelAverages[level.name] = {
                totalMarks: 0,
                studentCount: 0,
                average: 0
            };
        });
        
        // Process each student
        for (const student of students) {
            const queryConditions = {
                studentId: student.id,
                semesterNumber: parseInt(semesterNumber)
            };
            
            if (subjectId) {
                queryConditions.subjectId = subjectId;
            }
            
            const distributions = await StudentBloomsDistribution.findAll({
                where: queryConditions,
                include: [{
                    model: BloomsTaxonomy,
                    as: 'bloomsTaxonomy'
                }]
            });
            
            const studentData = {
                id: student.id,
                enrollmentNumber: student.enrollmentNumber,
                name: student.name,
                bloomsAchievement: {},
                totalWeightedMarks: 0
            };
            
            const processedComponents = new Set();
            
            distributions.forEach(dist => {
                const bloomsName = dist.bloomsTaxonomy?.name || 'Unknown';
                const componentKey = `${dist.studentMarksSubjectComponentId}`;
                
                if (!studentData.bloomsAchievement[bloomsName]) {
                    studentData.bloomsAchievement[bloomsName] = 0;
                }
                
                // Add component marks only once
                if (!processedComponents.has(componentKey)) {
                    studentData.bloomsAchievement[bloomsName] += dist.assignedMarks;
                    studentData.totalWeightedMarks += dist.assignedMarks;
                    
                    // Add to averages
                    if (comparison.bloomsLevelAverages[bloomsName]) {
                        comparison.bloomsLevelAverages[bloomsName].totalMarks += dist.assignedMarks;
                    }
                    
                    processedComponents.add(componentKey);
                }
            });
            
            comparison.students.push(studentData);
        }
        
        // Calculate averages
        Object.keys(comparison.bloomsLevelAverages).forEach(level => {
            const levelData = comparison.bloomsLevelAverages[level];
            if (students.length > 0) {
                levelData.average = (levelData.totalMarks / students.length).toFixed(2);
                levelData.studentCount = students.length;
            }
        });
        
        res.status(200).json(comparison);
        
    } catch (error) {
        console.error('Error comparing Bloom\'s achievement:', error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Get CO attainment report for a subject
 */
const getCOAttainmentReport = async (req, res) => {
    try {
        const { subjectId, batchId, semesterNumber } = req.params;
        
        // Get all students in the batch
        const students = await Student.findAll({
            where: { batchId: parseInt(batchId) }
        });
        
        // Get all COs for the subject
        const courseOutcomes = await CourseOutcome.findAll({
            where: { subject_id: subjectId }
        });
        
        if (!courseOutcomes.length) {
            return res.status(404).json({ error: 'No course outcomes found for this subject' });
        }
        
        const report = {
            subject: subjectId,
            batch: batchId,
            semester: parseInt(semesterNumber),
            courseOutcomes: {},
            studentCount: students.length,
            attainmentThreshold: 60 // Percentage threshold for CO attainment
        };
        
        // Initialize CO structure
        courseOutcomes.forEach(co => {
            report.courseOutcomes[co.co_code] = {
                id: co.id,
                description: co.description,
                totalStudents: students.length,
                studentsAttained: 0,
                averageMarks: 0,
                attainmentPercentage: 0,
                students: []
            };
        });
        
        // Process each student
        for (const student of students) {
            const distributions = await StudentBloomsDistribution.findAll({
                where: {
                    studentId: student.id,
                    semesterNumber: parseInt(semesterNumber),
                    subjectId: subjectId
                }
            });
            
            // Group by CO
            const coMarks = {};
            const processedComponents = new Set();
            
            distributions.forEach(dist => {
                const componentKey = `${dist.studentMarksSubjectComponentId}`;
                
                // Find CO from the map
                courseOutcomes.forEach(co => {
                    if (co.id === dist.courseOutcomeId) {
                        if (!coMarks[co.co_code]) {
                            coMarks[co.co_code] = 0;
                        }
                        
                        // Add component marks only once per CO
                        if (!processedComponents.has(`${componentKey}-${co.id}`)) {
                            coMarks[co.co_code] += dist.assignedMarks;
                            processedComponents.add(`${componentKey}-${co.id}`);
                        }
                    }
                });
            });
            
            // Update report with student data
            Object.keys(coMarks).forEach(coCode => {
                const marks = coMarks[coCode];
                const percentage = (marks / 150) * 100; // Assuming max 150 marks per subject
                
                report.courseOutcomes[coCode].students.push({
                    enrollmentNumber: student.enrollmentNumber,
                    name: student.name,
                    marks: marks,
                    percentage: percentage.toFixed(2)
                });
                
                report.courseOutcomes[coCode].averageMarks += marks;
                
                if (percentage >= report.attainmentThreshold) {
                    report.courseOutcomes[coCode].studentsAttained++;
                }
            });
        }
        
        // Calculate final statistics
        Object.keys(report.courseOutcomes).forEach(coCode => {
            const coData = report.courseOutcomes[coCode];
            if (coData.totalStudents > 0) {
                coData.averageMarks = (coData.averageMarks / coData.totalStudents).toFixed(2);
                coData.attainmentPercentage = ((coData.studentsAttained / coData.totalStudents) * 100).toFixed(2);
            }
        });
        
        res.status(200).json(report);
        
    } catch (error) {
        console.error('Error generating CO attainment report:', error);
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    getDetailedBloomsAchievement,
    compareBloomsAchievement,
    getCOAttainmentReport
};

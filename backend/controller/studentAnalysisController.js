const { StudentMarks, Student, UniqueSubDegree, Semester, Batch, SubComponents, ComponentWeightage, ComponentMarks } = require('../models');
const CourseOutcome = require('../models/courseOutcome');
const sequelize = require('../config/db');
const { Op } = require('sequelize');

// Get comprehensive student analysis data
const getStudentAnalysisData = async (req, res) => {
    try {
        const { enrollmentNumber } = req.params;


        // Find the student
        const student = await Student.findOne({
            where: { enrollmentNumber: enrollmentNumber }
        });

        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }


        // Get student's batch and current semester
        const batch = await Batch.findByPk(student.batchId);
        if (!batch) {
            return res.status(404).json({ error: 'Student batch not found' });
        }

        const currentSemester = batch.currentSemester || 1;

        // Fetch academic data for all semesters up to current
        const academicData = [];
        
        for (let semesterNum = 1; semesterNum <= currentSemester; semesterNum++) {
            // Find semester record
            const semester = await Semester.findOne({
                where: { 
                    semesterNumber: semesterNum,
                    batchId: student.batchId
                }
            });

            if (!semester) {
                continue;
            }
            
            // Get all marks for this student in this semester using raw query
            const rawMarks = await sequelize.query(`
                SELECT sm.*, sub.sub_name, sub.sub_code 
                FROM StudentMarks sm 
                LEFT JOIN UniqueSubDegrees sub ON sm.subjectId = sub.sub_code 
                WHERE sm.studentId = :studentId 
                ORDER BY sm.subjectId, sm.componentType
            `, {
                replacements: { studentId: student.id },
                type: sequelize.QueryTypes.SELECT
            });


            // Process marks by subject using raw data
            const subjectMarks = {};
            rawMarks.forEach(mark => {
                const subjectCode = mark.subjectId;
                const subjectName = mark.sub_name || subjectCode;

                if (!subjectMarks[subjectCode]) {
                    subjectMarks[subjectCode] = {
                        subjectName,
                        subjectCode,
                        components: {},
                        totalMarks: 0,
                        totalPossible: 0
                    };
                }

                const componentType = mark.componentType;
                if (!subjectMarks[subjectCode].components[componentType]) {
                    subjectMarks[subjectCode].components[componentType] = {
                        marksObtained: 0,
                        totalMarks: 0,
                        subComponents: []
                    };
                }

                if (mark.isSubComponent) {
                    subjectMarks[subjectCode].components[componentType].subComponents.push({
                        name: mark.componentName,
                        marksObtained: parseFloat(mark.marksObtained) || 0,
                        totalMarks: parseInt(mark.totalMarks) || 0
                    });
                } else {
                    subjectMarks[subjectCode].components[componentType].marksObtained += parseFloat(mark.marksObtained) || 0;
                    subjectMarks[subjectCode].components[componentType].totalMarks += parseInt(mark.totalMarks) || 0;
                }

                subjectMarks[subjectCode].totalMarks += parseFloat(mark.marksObtained) || 0;
                subjectMarks[subjectCode].totalPossible += parseInt(mark.totalMarks) || 0;
            });

            // Calculate semester statistics
            let semesterTotalObtained = 0;
            let semesterTotalPossible = 0;
            const subjects = Object.values(subjectMarks);

            subjects.forEach(subject => {
                semesterTotalObtained += subject.totalMarks;
                semesterTotalPossible += subject.totalPossible;
            });

            const semesterPercentage = semesterTotalPossible > 0 
                ? (semesterTotalObtained / semesterTotalPossible) * 100 
                : 0;

            academicData.push({
                semester: semesterNum,
                subjects: subjects,
                totalMarksObtained: semesterTotalObtained,
                totalMarksPossible: semesterTotalPossible,
                percentage: Math.round(semesterPercentage * 100) / 100,
                subjectCount: subjects.length
            });
        }

        // Calculate overall academic performance
        const overallStats = academicData.reduce((acc, semester) => {
            acc.totalObtained += semester.totalMarksObtained;
            acc.totalPossible += semester.totalMarksPossible;
            acc.totalSubjects += semester.subjectCount;
            return acc;
        }, { totalObtained: 0, totalPossible: 0, totalSubjects: 0 });

        const overallPercentage = overallStats.totalPossible > 0 
            ? (overallStats.totalObtained / overallStats.totalPossible) * 100 
            : 0;

        // Generate academic insights
        const insights = generateAcademicInsights(academicData, overallPercentage);

        // Prepare chart data for academic performance
        const chartData = academicData.map(semester => ({
            semester: semester.semester,
            percentage: semester.percentage,
            marksObtained: semester.totalMarksObtained,
            totalMarks: semester.totalMarksPossible
        }));

        res.status(200).json({
            student: {
                id: student.id,
                name: student.name,
                enrollmentNumber: student.enrollmentNumber,
                batchId: student.batchId,
                currentSemester
            },
            academicData,
            overallStats: {
                ...overallStats,
                overallPercentage: Math.round(overallPercentage * 100) / 100
            },
            insights,
            chartData
        });

    } catch (error) {
        console.error('Error fetching student analysis data:', error);
        res.status(500).json({ error: error.message });
    }
};

// Generate academic performance insights
const generateAcademicInsights = (academicData, overallPercentage) => {
    const insights = {
        strengths: [],
        weaknesses: [],
        trends: '',
        recommendations: []
    };

    if (academicData.length === 0) {
        insights.trends = 'No academic data available';
        insights.recommendations.push('Start engaging with academic assessments');
        return insights;
    }

    // Analyze performance trends
    if (academicData.length > 1) {
        const firstSemester = academicData[0];
        const lastSemester = academicData[academicData.length - 1];
        const trend = lastSemester.percentage - firstSemester.percentage;

        if (trend > 5) {
            insights.trends = 'Improving academic performance';
            insights.strengths.push('Consistent academic improvement');
        } else if (trend < -5) {
            insights.trends = 'Declining academic performance';
            insights.weaknesses.push('Academic performance needs attention');
            insights.recommendations.push('Schedule study sessions with faculty');
        } else {
            insights.trends = 'Stable academic performance';
        }
    }

    // Analyze overall performance level
    if (overallPercentage >= 85) {
        insights.strengths.push('Excellent academic performance');
        insights.recommendations.push('Consider mentoring peers');
    } else if (overallPercentage >= 70) {
        insights.strengths.push('Good academic performance');
        insights.recommendations.push('Aim for excellence in challenging subjects');
    } else if (overallPercentage >= 50) {
        insights.weaknesses.push('Average academic performance');
        insights.recommendations.push('Focus on improving study strategies');
    } else {
        insights.weaknesses.push('Below average academic performance');
        insights.recommendations.push('Seek additional academic support immediately');
    }

    // Analyze subject-wise performance
    const latestSemester = academicData[academicData.length - 1];
    if (latestSemester && latestSemester.subjects.length > 0) {
        const subjectPerformances = latestSemester.subjects.map(subject => ({
            name: subject.subjectName,
            percentage: subject.totalPossible > 0 ? (subject.totalMarks / subject.totalPossible) * 100 : 0
        }));

        const bestSubject = subjectPerformances.reduce((max, subject) => 
            subject.percentage > max.percentage ? subject : max
        );

        const worstSubject = subjectPerformances.reduce((min, subject) => 
            subject.percentage < min.percentage ? subject : min
        );

        if (bestSubject.percentage > 80) {
            insights.strengths.push(`Strong performance in ${bestSubject.name}`);
        }

        if (worstSubject.percentage < 60) {
            insights.weaknesses.push(`Needs improvement in ${worstSubject.name}`);
            insights.recommendations.push(`Focus additional study time on ${worstSubject.name}`);
        }
    }

    return insights;
};

// Get Bloom's taxonomy distribution for a student
const getBloomsTaxonomyDistribution = async (req, res) => {
    try {
        const { enrollmentNumber, semesterNumber } = req.params;
        const student = await Student.findOne({ where: { enrollmentNumber } });
        if (!student) return res.status(404).json({ error: 'Student not found' });

        // 1. Single, comprehensive query with the CORRECT join condition
        const results = await sequelize.query(`
            SELECT
                sm.subjectId, sub.sub_name, sm.marksObtained, sm.totalMarks AS subComponentTotalMarks,
                sm.componentType, sc.id AS subComponentId, sc.weightage AS subComponentWeightage,
                cw.id AS componentWeightageId, cw.ese, cw.ia, cw.tw, cw.viva, cw.ca,
                co.id AS coId, bt.name AS bloomsLevel
            FROM StudentMarks sm
            JOIN SubComponents sc ON sm.subComponentId = sc.id
            JOIN ComponentWeightages cw ON sc.componentWeightageId = cw.id
            JOIN UniqueSubDegrees sub ON sm.subjectId = sub.sub_code
            LEFT JOIN subject_component_cos scc ON scc.subject_component_id = sc.id -- Corrected JOIN
            LEFT JOIN course_outcomes co ON scc.course_outcome_id = co.id
            LEFT JOIN co_blooms_taxonomy cbt ON cbt.course_outcome_id = co.id
            LEFT JOIN blooms_taxonomy bt ON cbt.blooms_taxonomy_id = bt.id
            WHERE sm.studentId = :studentId AND sm.enrollmentSemester = :semesterNumber
        `, { replacements: { studentId: student.id, semesterNumber }, type: sequelize.QueryTypes.SELECT });

        const subjectBloomsData = {};

        // 2. Process each unique student mark to avoid double-counting
        const uniqueMarks = results.filter((v, i, a) => a.findIndex(t => (t.subComponentId === v.subComponentId)) === i);

        for (const mark of uniqueMarks) {
            if (!mark.subComponentId) continue;

            // 3. Calculate effective marks for the sub-component
            let componentTotal = 0;
            switch (mark.componentType) {
                case 'ESE': componentTotal = mark.ese; break;
                case 'IA': componentTotal = mark.ia; break;
                case 'TW': componentTotal = mark.tw; break;
                case 'VIVA': componentTotal = mark.viva; break;
                case 'CA': componentTotal = mark.ca; break;
            }
            if (componentTotal === 0) continue;

            const effectiveTotal = (componentTotal * (mark.subComponentWeightage / 100));
            const effectiveObtained = (mark.marksObtained / mark.subComponentTotalMarks) * effectiveTotal;

            // 4. Distribute marks to relevant COs
            const cosForSubComponent = results.filter(r => r.subComponentId === mark.subComponentId && r.coId);
            const uniqueCoIds = [...new Set(cosForSubComponent.map(r => r.coId))];
            if (uniqueCoIds.length === 0) continue;

            const marksPerCo = effectiveObtained / uniqueCoIds.length;
            const totalPerCo = effectiveTotal / uniqueCoIds.length;

            // 5. Distribute marks from COs to Bloom's Levels
            for (const coId of uniqueCoIds) {
                const bloomsForCo = results.filter(r => r.coId === coId && r.bloomsLevel);
                const uniqueBloomLevels = [...new Set(bloomsForCo.map(r => r.bloomsLevel))];
                if (uniqueBloomLevels.length === 0) continue;

                const marksPerBloom = marksPerCo / uniqueBloomLevels.length;
                const totalPerBloom = totalPerCo / uniqueBloomLevels.length;

                for (const bloomLevel of uniqueBloomLevels) {
                    if (!subjectBloomsData[mark.subjectId]) {
                        subjectBloomsData[mark.subjectId] = { subject: mark.sub_name, code: mark.subjectId, bloomsLevels: {} };
                    }
                    if (!subjectBloomsData[mark.subjectId].bloomsLevels[bloomLevel]) {
                        subjectBloomsData[mark.subjectId].bloomsLevels[bloomLevel] = { obtained: 0, possible: 0 };
                    }
                    subjectBloomsData[mark.subjectId].bloomsLevels[bloomLevel].obtained += marksPerBloom;
                    subjectBloomsData[mark.subjectId].bloomsLevels[bloomLevel].possible += totalPerBloom;
                }
            }
        }

        // 6. Format for frontend response
        const bloomsData = Object.values(subjectBloomsData).map(subject => ({
            subject: subject.subject,
            code: subject.code,
            bloomsLevels: Object.entries(subject.bloomsLevels).map(([level, data]) => ({
                level,
                score: data.possible > 0 ? Math.round((data.obtained / data.possible) * 100) : 0
            }))
        }));

        res.status(200).json({ semester: parseInt(semesterNumber), bloomsDistribution: bloomsData });

    } catch (error) {
        console.error('Error fetching Bloom\'s taxonomy distribution:', error);
        res.status(500).json({ error: error.message });
    }
};




// Get subject-wise performance
const getSubjectWisePerformance = async (req, res) => {
    try {
        const { enrollmentNumber, semesterNumber } = req.params;

        console.log(`Fetching academic performance for enrollment: ${enrollmentNumber}, semester: ${semesterNumber}`);

        // Find the student
        const student = await Student.findOne({
            where: { enrollmentNumber: enrollmentNumber }
        });

        if (!student) {
            console.log(`Student not found with enrollment: ${enrollmentNumber}`);
            return res.status(404).json({ 
                error: 'Student not found',
                details: { enrollmentNumber }
            });
        }

        console.log('Student details:', {
            id: student.id,
            enrollmentNumber: student.enrollmentNumber,
            batchId: student.batchId,
            currentSemester: student.currentSemester
        });

        // Find all semesters for the student's batch for debugging
        const allSemesters = await Semester.findAll({
            where: { batchId: student.batchId },
            attributes: ['id', 'semesterNumber', 'batchId']
        });
        console.log(`Found ${allSemesters.length} semesters for batch ${student.batchId}:`, 
            allSemesters.map(s => s.semesterNumber));

        // Find the specific semester
        const semester = await Semester.findOne({
            where: { 
                semesterNumber: parseInt(semesterNumber),
                batchId: student.batchId
            }
        });

        if (!semester) {
            const availableSemesters = allSemesters.map(s => s.semesterNumber);
            const currentSemester = student.currentSemester || 1;
            const suggestedSemester = Math.min(currentSemester, ...availableSemesters);
            
            const errorMessage = availableSemesters.length === 0
                ? 'No semesters found for this batch. Please contact support.'
                : `Semester ${semesterNumber} not available. Available semesters: ${availableSemesters.join(', ')}.`;
        
            console.log('Semester not found. Details:', {
                requestedSemester: parseInt(semesterNumber),
                batchId: student.batchId,
                availableSemesters,
                currentSemester,
                suggestedSemester
            });
        
            return res.status(404).json({ 
                error: errorMessage,
                details: {
                    requestedSemester: parseInt(semesterNumber),
                    availableSemesters,
                    currentSemester,
                    suggestedSemester,
                    recommendation: `Try using semester ${suggestedSemester} instead.`
                }
            });
        }

        console.log(`Found semester:`, {
            semesterId: semester.id,
            semesterNumber: semester.semesterNumber,
            batchId: semester.batchId
        });

        // Rest of your existing code...

        // Get marks with subcomponent weightages for proper calculation
        const rawMarks = await sequelize.query(`
            SELECT 
                sm.subjectId,
                sm.componentType,
                sm.marksObtained,
                sm.totalMarks,
                sm.grades,
                sm.isSubComponent,
                sm.componentName,
                sm.subComponentId,
                sub.sub_name,
                sub.sub_code,
                sub.sub_credit,
                sc.subComponentName as subComponentName,
                sc.weightage as subComponentWeightage,
                sc.totalMarks as subComponentTotalMarks
           FROM StudentMarks sm 
LEFT JOIN UniqueSubDegrees sub ON sm.subjectId = sub.sub_code 
LEFT JOIN SubComponents sc ON sm.subComponentId = sc.id
LEFT JOIN ComponentWeightages cw ON sc.componentWeightageId = cw.id
            WHERE sm.studentId = :studentId 
            AND sm.enrollmentSemester = :semesterNumber
            ORDER BY sm.subjectId, sm.componentType, sm.isSubComponent
        `, {
            replacements: { 
                studentId: student.id,
                semesterNumber: parseInt(semesterNumber)
            },
            type: sequelize.QueryTypes.SELECT
        });

        console.log(`Found ${rawMarks.length} marks records for semester ${semesterNumber}`);

        // Process marks by subject with weighted calculation
        const subjectData = {};
        rawMarks.forEach(mark => {
            const subjectCode = mark.subjectId;
            const subjectName = mark.sub_name || subjectCode;

            if (!subjectData[subjectCode]) {
                subjectData[subjectCode] = {
                    subject: subjectName,
                    shortName: subjectName.length > 15 ? subjectName.substring(0, 15) + '...' : subjectName,
                    code: subjectCode,
                    credits: mark.sub_credit || 3,
                    ese: 0,
                    ia: 0,
                    tw: 0,
                    viva: 0,
                    cse: 0,
                    total: 0,
                    totalPossible: 0, // Add totalPossible for dynamic calculation
                    percentage: 0,
                    grade: 'F'
                };
            }

            const componentType = mark.componentType.toUpperCase();
            let effectiveMarks = parseFloat(mark.marksObtained) || 0;

            
            // Map component types to table columns
            switch(componentType) {
                case 'ESE':
                    subjectData[subjectCode].ese += effectiveMarks;
                    break;
                case 'IA':
                    subjectData[subjectCode].ia += effectiveMarks;
                    break;
                case 'TW':
                    subjectData[subjectCode].tw += effectiveMarks;
                    break;
                case 'VIVA':
                    subjectData[subjectCode].viva += effectiveMarks;
                    break;
                case 'CA':
                case 'CSE':
                    subjectData[subjectCode].cse += effectiveMarks;
                    break;
            }

            subjectData[subjectCode].total += effectiveMarks;
            subjectData[subjectCode].totalPossible += parseFloat(mark.totalMarks) || 0;
            
            // Use grade if available
            if (mark.grades && mark.grades !== 'F') {
                subjectData[subjectCode].grade = mark.grades;
            }
        });

        // Calculate percentages and final grades
        Object.values(subjectData).forEach(subject => {
            subject.percentage = subject.totalPossible > 0 
                ? ((subject.total / subject.totalPossible) * 100).toFixed(1) 
                : 0;
            
            // Calculate grade based on percentage if not already set
            if (subject.grade === 'F') {
                const percentage = parseFloat(subject.percentage);
                if (percentage >= 90) subject.grade = 'A+';
                else if (percentage >= 80) subject.grade = 'A';
                else if (percentage >= 70) subject.grade = 'B+';
                else if (percentage >= 60) subject.grade = 'B';
                else if (percentage >= 50) subject.grade = 'C+';
                else if (percentage >= 40) subject.grade = 'C';
                else if (percentage >= 35) subject.grade = 'D';
                else subject.grade = 'F';
            }
        });

        const subjects = Object.values(subjectData);
        
        // Calculate summary statistics
        const totalCredits = subjects.reduce((sum, subject) => sum + subject.credits, 0);
        const averagePercentage = subjects.length > 0 
            ? (subjects.reduce((sum, subject) => sum + parseFloat(subject.percentage), 0) / subjects.length).toFixed(1)
            : 0;
        const passedSubjects = subjects.filter(s => s.grade !== 'F').length;

        console.log(`Processed ${subjects.length} subjects for academic analysis`);

        res.status(200).json({
            semester: parseInt(semesterNumber),
            subjects: subjects,
            summary: {
                totalCredits,
                averagePercentage,
                passedSubjects,
                totalSubjects: subjects.length
            }
        });

    } catch (error) {
        console.error('Error fetching subject-wise performance:', error);
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    getStudentAnalysisData,
    getSubjectWisePerformance,
    getBloomsTaxonomyDistribution
};
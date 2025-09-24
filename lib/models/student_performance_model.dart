class StudentPerformanceModel {
  final StudentInfo student;
  final List<SubjectPerformance> subjects;
  final PerformanceStats overallStats;
  final List<String> insights;

  StudentPerformanceModel({
    required this.student,
    required this.subjects,
    required this.overallStats,
    required this.insights,
  });

  factory StudentPerformanceModel.fromJson(Map<String, dynamic> json) {
    return StudentPerformanceModel(
      student: StudentInfo.fromJson(json['student'] ?? {}),
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((subject) => SubjectPerformance.fromJson(subject))
          .toList() ?? [],
      overallStats: PerformanceStats.fromJson(json['overallStats'] ?? {}),
      insights: (json['insights'] as List<dynamic>?)
          ?.map((insight) => insight.toString())
          .toList() ?? [],
    );
  }
}

class StudentInfo {
  final int id;
  final String name;
  final String enrollmentNumber;
  final int batchId;
  final int currentSemester;

  StudentInfo({
    required this.id,
    required this.name,
    required this.enrollmentNumber,
    required this.batchId,
    required this.currentSemester,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      enrollmentNumber: json['enrollmentNumber'] ?? '',
      batchId: json['batchId'] ?? 0,
      currentSemester: json['currentSemester'] ?? 1,
    );
  }
}

class SubjectPerformance {
  final String subject;
  final String shortName;
  final String code;
  final double? credits;
  final Map<String, ComponentPerformance> components;
  final double totalMarksObtained;
  final double totalMarksPossible;
  final double percentage;
  final String grade;
  final double? ese;
  final double? ia;
  final double? tw;
  final double? viva;
  final double? cse;

  SubjectPerformance({
    required this.subject,
    required this.shortName,
    required this.code,
    this.credits,
    required this.components,
    required this.totalMarksObtained,
    required this.totalMarksPossible,
    required this.percentage,
    required this.grade,
    this.ese,
    this.ia,
    this.tw,
    this.viva,
    this.cse,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    Map<String, ComponentPerformance> componentMap = {};
    
    // Check if components are provided in nested format
    if (json['components'] != null) {
      (json['components'] as Map<String, dynamic>).forEach((key, value) {
        componentMap[key] = ComponentPerformance.fromJson(value);
      });
    } else {
      // Create components from flat structure (actual API response)
      if (json['ese'] != null) {
        componentMap['ESE'] = ComponentPerformance(
          marksObtained: (json['ese'] ?? 0).toDouble(),
          totalMarks: 100.0, // Default max marks for ESE
          percentage: 0.0,
          subComponents: [],
        );
      }
      if (json['ia'] != null) {
        componentMap['IA'] = ComponentPerformance(
          marksObtained: (json['ia'] ?? 0).toDouble(),
          totalMarks: 25.0, // Default max marks for IA
          percentage: 0.0,
          subComponents: [],
        );
      }
      if (json['tw'] != null) {
        componentMap['TW'] = ComponentPerformance(
          marksObtained: (json['tw'] ?? 0).toDouble(),
          totalMarks: 25.0, // Default max marks for TW
          percentage: 0.0,
          subComponents: [],
        );
      }
      if (json['viva'] != null) {
        componentMap['VIVA'] = ComponentPerformance(
          marksObtained: (json['viva'] ?? 0).toDouble(),
          totalMarks: 15.0, // Default max marks for VIVA
          percentage: 0.0,
          subComponents: [],
        );
      }
      if (json['cse'] != null) {
        componentMap['CSE'] = ComponentPerformance(
          marksObtained: (json['cse'] ?? 0).toDouble(),
          totalMarks: 15.0, // Default max marks for CSE
          percentage: 0.0,
          subComponents: [],
        );
      }
    }

    return SubjectPerformance(
      subject: json['subject'] ?? '',
      shortName: json['shortName'] ?? json['subject'] ?? '',
      code: json['code'] ?? '',
      credits: json['credits']?.toDouble(),
      components: componentMap,
      totalMarksObtained: (json['total'] ?? json['totalMarksObtained'] ?? 0).toDouble(),
      totalMarksPossible: (json['totalPossible'] ?? json['totalMarksPossible'] ?? 180).toDouble(),
      percentage: double.parse((json['percentage'] ?? 0).toString()),
      grade: json['grade'] ?? 'NA',
      ese: json['ese']?.toDouble(),
      ia: json['ia']?.toDouble(),
      tw: json['tw']?.toDouble(),
      viva: json['viva']?.toDouble(),
      cse: json['cse']?.toDouble(),
    );
  }
}

class ComponentPerformance {
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final List<SubComponentPerformance> subComponents;

  ComponentPerformance({
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.subComponents,
  });

  factory ComponentPerformance.fromJson(Map<String, dynamic> json) {
    return ComponentPerformance(
      marksObtained: (json['marksObtained'] ?? 0).toDouble(),
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      subComponents: (json['subComponents'] as List<dynamic>?)
          ?.map((sub) => SubComponentPerformance.fromJson(sub))
          .toList() ?? [],
    );
  }
}

class SubComponentPerformance {
  final String name;
  final double marksObtained;
  final double totalMarks;
  final double percentage;

  SubComponentPerformance({
    required this.name,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
  });

  factory SubComponentPerformance.fromJson(Map<String, dynamic> json) {
    return SubComponentPerformance(
      name: json['name'] ?? '',
      marksObtained: (json['marksObtained'] ?? 0).toDouble(),
      totalMarks: (json['totalMarks'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PerformanceStats {
  final int totalSubjects;
  final double averagePercentage;
  final int excellentCount;
  final int needsAttentionCount;

  PerformanceStats({
    required this.totalSubjects,
    required this.averagePercentage,
    required this.excellentCount,
    required this.needsAttentionCount,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalSubjects: json['totalSubjects'] ?? 0,
      averagePercentage: (json['averagePercentage'] ?? 0).toDouble(),
      excellentCount: json['excellentCount'] ?? 0,
      needsAttentionCount: json['needsAttentionCount'] ?? 0,
    );
  }
}

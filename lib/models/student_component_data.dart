import 'dart:convert';

class StudentComponentData {
  final StudentInfo student;
  final List<SemesterData> semesters;

  StudentComponentData({
    required this.student,
    required this.semesters,
  });

  factory StudentComponentData.fromJson(Map<String, dynamic> json) {
    return StudentComponentData(
      student: StudentInfo.fromJson(json['student']),
      semesters: (json['semesters'] as List)
          .map((semester) => SemesterData.fromJson(semester))
          .toList(),
    );
  }

  static StudentComponentData fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return StudentComponentData.fromJson(json);
  }
}

class StudentInfo {
  final int id;
  final String name;
  final String email;
  final String enrollmentNumber;
  final String batch;
  final int hardwarePoints;
  final int softwarePoints;

  StudentInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.batch,
    required this.hardwarePoints,
    required this.softwarePoints,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      enrollmentNumber: json['enrollmentNumber'],
      batch: json['batch'],
      hardwarePoints: json['hardwarePoints'] ?? 0,
      softwarePoints: json['softwarePoints'] ?? 0,
    );
  }
}

class SemesterData {
  final int semesterId;
  final int semesterNumber;
  final String startDate;
  final String endDate;
  final double? cpi;
  final double? spi;
  final int? rank;
  final List<SubjectData> subjects;

  SemesterData({
    required this.semesterId,
    required this.semesterNumber,
    required this.startDate,
    required this.endDate,
    this.cpi,
    this.spi,
    this.rank,
    required this.subjects,
  });

  factory SemesterData.fromJson(Map<String, dynamic> json) {
    return SemesterData(
      semesterId: json['semesterId'],
      semesterNumber: json['semesterNumber'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      cpi: json['cpi'] != null ? json['cpi'].toDouble() : null,
      spi: json['spi'] != null ? json['spi'].toDouble() : null,
      rank: json['rank'],
      subjects: (json['subjects'] as List)
          .map((subject) => SubjectData.fromJson(subject))
          .toList(),
    );
  }
}

class SubjectData {
  final int subjectId;
  final String subjectName;
  final String? subjectCode;
  final int? credits;
  final ComponentMarks? componentMarks;
  final ComponentWeightage? componentWeightage;

  SubjectData({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    this.credits,
    this.componentMarks,
    this.componentWeightage,
  });

  factory SubjectData.fromJson(Map<String, dynamic> json) {
    return SubjectData(
      subjectId: json['subjectId'],
      subjectName: json['subjectName'],
      subjectCode: json['subjectCode'],
      credits: json['credits'],
      componentMarks: json['componentMarks'] != null
          ? ComponentMarks.fromJson(json['componentMarks'])
          : null,
      componentWeightage: json['componentWeightage'] != null
          ? ComponentWeightage.fromJson(json['componentWeightage'])
          : null,
    );
  }
}

class ComponentMarks {
  final int? ese;
  final int? cse;
  final int? ia;
  final int? tw;
  final int? viva;

  ComponentMarks({
    this.ese,
    this.cse,
    this.ia,
    this.tw,
    this.viva,
  });

  factory ComponentMarks.fromJson(Map<String, dynamic> json) {
    return ComponentMarks(
      ese: json['ese'],
      cse: json['cse'],
      ia: json['ia'],
      tw: json['tw'],
      viva: json['viva'],
    );
  }
}

class ComponentWeightage {
  final int? ese;
  final int? cse;
  final int? ia;
  final int? tw;
  final int? viva;

  ComponentWeightage({
    this.ese,
    this.cse,
    this.ia,
    this.tw,
    this.viva,
  });

  factory ComponentWeightage.fromJson(Map<String, dynamic> json) {
    return ComponentWeightage(
      ese: json['ese'],
      cse: json['cse'],
      ia: json['ia'],
      tw: json['tw'],
      viva: json['viva'],
    );
  }
}

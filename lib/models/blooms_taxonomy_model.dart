class BloomsTaxonomyModel {
  final int semester;
  final List<SubjectBloomsData> bloomsDistribution;
  final String? debug;

  BloomsTaxonomyModel({
    required this.semester,
    required this.bloomsDistribution,
    this.debug,
  });

  factory BloomsTaxonomyModel.fromJson(Map<String, dynamic> json) {
    return BloomsTaxonomyModel(
      semester: json['semester'] ?? 1,
      bloomsDistribution: (json['bloomsDistribution'] as List<dynamic>?)
          ?.map((subject) => SubjectBloomsData.fromJson(subject))
          .toList() ?? [],
      debug: json['debug'],
    );
  }
}

class SubjectBloomsData {
  final String subject;
  final String code;
  final List<BloomsLevel> bloomsLevels;

  SubjectBloomsData({
    required this.subject,
    required this.code,
    required this.bloomsLevels,
  });

  factory SubjectBloomsData.fromJson(Map<String, dynamic> json) {
    return SubjectBloomsData(
      subject: json['subject'] ?? '',
      code: json['code'] ?? '',
      bloomsLevels: (json['bloomsLevels'] as List<dynamic>?)
          ?.map((level) => BloomsLevel.fromJson(level))
          .toList() ?? [],
    );
  }
}

class BloomsLevel {
  final String level;
  final int score;
  final double marks;
  final double obtained;
  final double possible;

  BloomsLevel({
    required this.level,
    required this.score,
    required this.marks,
    required this.obtained,
    required this.possible,
  });

  factory BloomsLevel.fromJson(Map<String, dynamic> json) {
    return BloomsLevel(
      level: json['level'] ?? '',
      score: json['score'] ?? 0,
      marks: (json['marks'] ?? 0.0).toDouble(),
      obtained: (json['obtained'] ?? 0.0).toDouble(),
      possible: (json['possible'] ?? 0.0).toDouble(),
    );
  }
}

// Helper class for chart data
class BloomsChartData {
  final String level;
  final double score;
  final String subject;

  BloomsChartData({
    required this.level,
    required this.score,
    required this.subject,
  });
}

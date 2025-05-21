class StudentRanking {
  final int id;
  final String name;
  final String email;
  final String enrollmentNumber;
  final int hardwarePoints;
  final int softwarePoints;
  final int cocurricularPoints;
  final int extracurricularPoints;
  final double? cpi;
  final double? spi;
  final int? rank;
  final String? batch;
  final int currentSemester;

  StudentRanking({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.hardwarePoints,
    required this.softwarePoints,
    this.cocurricularPoints = 0,
    this.extracurricularPoints = 0,
    this.cpi,
    this.spi,
    this.rank,
    this.batch,
    required this.currentSemester,
  });

  int get totalPoints => hardwarePoints + softwarePoints;
  
  int get totalActivityPoints => cocurricularPoints + extracurricularPoints;

  factory StudentRanking.fromJson(Map<String, dynamic> json) {
    return StudentRanking(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollmentNumber: json['enrollmentNumber'] ?? '',
      hardwarePoints: json['hardwarePoints'] ?? 0,
      softwarePoints: json['softwarePoints'] ?? 0,
      cocurricularPoints: json['totalCocurricular'] ?? 0,
      extracurricularPoints: json['totalExtracurricular'] ?? 0,
      cpi: json['cpi'] != null ? double.tryParse(json['cpi'].toString()) : null,
      spi: json['spi'] != null ? double.tryParse(json['spi'].toString()) : null,
      rank: json['rank'],
      batch: json['batch'],
      currentSemester: json['currnetsemester'] ?? json['currentSemester'] ?? json['semester'] ?? 0,
    );
  }
}

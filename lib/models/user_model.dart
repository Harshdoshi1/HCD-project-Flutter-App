class User {
  final String id;
  final String name;
  final String email;
  final String enrollmentNumber;
  final int currentSemester;
  final String role;
  final int hardwarePoints;
  final int softwarePoints;
  final String? batch;
  final String? studentName; // For parent role - name of the student
  final String? studentEnrollment; // For parent role - enrollment of the student

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.currentSemester,
    required this.role,
    this.hardwarePoints = 0,
    this.softwarePoints = 0,
    this.batch,
    this.studentName,
    this.studentEnrollment,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing user from JSON: $json');
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      enrollmentNumber: json['enrollmentNumber']?.toString() ?? '',
      currentSemester: json['currentSemester'] != null 
          ? int.tryParse(json['currentSemester'].toString()) ?? 0 
          : 0,
      role: json['role']?.toString() ?? 'student',
      hardwarePoints: json['hardwarePoints'] != null
          ? int.tryParse(json['hardwarePoints'].toString()) ?? 0
          : 0,
      softwarePoints: json['softwarePoints'] != null
          ? int.tryParse(json['softwarePoints'].toString()) ?? 0
          : 0,
      batch: json['batch']?.toString(),
      studentName: json['studentName']?.toString(),
      studentEnrollment: json['studentEnrollment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'enrollmentNumber': enrollmentNumber,
    'currentSemester': currentSemester,
    'role': role,
    'hardwarePoints': hardwarePoints,
    'softwarePoints': softwarePoints,
    'batch': batch,
    'studentName': studentName,
    'studentEnrollment': studentEnrollment,
  };

  // Helper methods for role checking
  bool get isParent => role == 'parent';
  bool get isStudent => role == 'student';
  
  // Get display name based on role
  String get displayName {
    if (isParent && studentName != null) {
      return "$studentName's Parent";
    }
    return name;
  }
}

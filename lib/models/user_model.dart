class User {
  final String id;
  final String name;
  final String email;
  final String enrollmentNumber;
  final int currentSemester;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.currentSemester,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      enrollmentNumber: json['enrollmentNumber'] as String,
      currentSemester: int.parse(json['currnetsemester'].toString()),
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'enrollmentNumber': enrollmentNumber,
    'currnetsemester': currentSemester,
    'role': role,
  };
}

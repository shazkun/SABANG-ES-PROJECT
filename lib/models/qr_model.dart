class QRModel {
  final String id;
  final String name;
  final String email;
  final String gradeSection;

  QRModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gradeSection,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gradeSection': gradeSection,
    };
  }

  factory QRModel.fromMap(Map<String, dynamic> map) {
    return QRModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      gradeSection: map['gradeSection'] as String,
    );
  }
}

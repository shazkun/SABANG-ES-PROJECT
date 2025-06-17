class QRModel {
  final String? id;
  final String name;
  final String email;
  final String gradeSection;

  QRModel({
    this.id,
    required this.name,
    required this.email,
    required this.gradeSection,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gradeSection': gradeSection,
    };
  }

  factory QRModel.fromJson(Map<String, dynamic> json) {
    return QRModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gradeSection: json['gradeSection'],
    );
  }
}

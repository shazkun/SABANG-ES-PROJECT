class QRModel {
  final String id;
  final String name;
  final String email;
  final String year;

  QRModel({
    required this.id,
    required this.name,
    required this.email,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'year': year};
  }

  factory QRModel.fromMap(Map<String, dynamic> map) {
    return QRModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      year: map['year'] as String,
    );
  }
}

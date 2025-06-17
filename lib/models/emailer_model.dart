import 'dart:convert';

class EmailerModel {
  String email;
  String code;

  EmailerModel({required this.email, required this.code});

  Map<String, dynamic> toMap() {
    return {'email': email, 'code': code};
  }

  factory EmailerModel.fromMap(Map<String, dynamic> map) {
    return EmailerModel(email: map['email'], code: map['code']);
  }

  String toJson() => json.encode(toMap());

  factory EmailerModel.fromJson(String source) =>
      EmailerModel.fromMap(json.decode(source));
}

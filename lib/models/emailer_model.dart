import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

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

class EncryptionHelper {
  static final _key = encrypt.Key.fromUtf8(
    'my32lengthsupersecretnooneknows1',
  ); // 32 chars
  static final _iv = encrypt.IV.fromLength(16); // 16 bytes IV

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}

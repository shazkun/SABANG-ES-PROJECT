import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static final _key = encrypt.Key.fromUtf8(
    'my32lengthsupersecretnooneknows1', // 32 chars for AES-256
  );

  static final _iv = encrypt.IV.fromLength(16); // 16 bytes IV (AES block size)

  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  // Encrypt text
  static String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // Decrypt text
  static String decryptText(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}

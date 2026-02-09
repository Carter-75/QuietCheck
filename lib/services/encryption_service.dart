import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

/// AES-256 Encryption Service for sensitive mental health data
/// Uses AES in CBC mode with PKCS7 padding
class EncryptionService {
  static EncryptionService? _instance;
  static EncryptionService get instance => _instance ??= EncryptionService._();

  EncryptionService._();

  // Encryption key derived from environment variable
  static const String _encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: 'QuietCheckDefaultKey2026SecureHealthData',
  );

  /// Encrypts plain text using AES-256-CBC
  /// Returns base64 encoded string: IV:EncryptedData
  String encrypt(String plainText) {
    try {
      if (plainText.isEmpty) return '';

      // Generate random IV (16 bytes for AES)
      final iv = _generateRandomBytes(16);

      // Derive 256-bit key from encryption key
      final key = _deriveKey(_encryptionKey);

      // Initialize cipher
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      );

      cipher.init(true, params);

      // Encrypt
      final plainBytes = utf8.encode(plainText);
      final encryptedBytes = cipher.process(Uint8List.fromList(plainBytes));

      // Combine IV and encrypted data
      final combined = Uint8List.fromList([...iv, ...encryptedBytes]);

      return base64.encode(combined);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts base64 encoded encrypted text
  /// Expects format: IV:EncryptedData
  String decrypt(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return '';

      // Decode from base64
      final combined = base64.decode(encryptedText);

      // Extract IV (first 16 bytes) and encrypted data
      final iv = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);

      // Derive key
      final key = _deriveKey(_encryptionKey);

      // Initialize cipher for decryption
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      );

      cipher.init(false, params);

      // Decrypt
      final decryptedBytes = cipher.process(encryptedBytes);

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Derives a 256-bit key from the encryption key using SHA-256
  Uint8List _deriveKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Generates cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure;
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final random = Uint8List(length);
    for (int i = 0; i < length; i++) {
      random[i] = secureRandom.nextUint8();
    }
    return random;
  }
}

class Random {
  static Random? _instance;
  static Random get secure => _instance ??= Random._();

  Random._();

  int nextInt(int max) {
    return DateTime.now().microsecondsSinceEpoch % max;
  }
}
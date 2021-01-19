import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

EncryptionService encryptionService = EncryptionService();

///
class EncryptionService {
  factory EncryptionService() => _service;
  EncryptionService._internal();
  static final EncryptionService _service = EncryptionService._internal();

  String __clientSecretKey1,
      __clientSecretKey2,
      __tokenSecretKey1,
      __tokenSecretKey2,
      __deviceIdSecretKey;

  ///
  void init(
      String clientSecretKey1,
      String clientSecretKey2,
      String tokenSecretKey1,
      String tokenSecretKey2,
      String deviceIdSecretKey) {
    __clientSecretKey1 = clientSecretKey1;
    __clientSecretKey2 = clientSecretKey2;
    __tokenSecretKey1 = tokenSecretKey1;
    __tokenSecretKey2 = tokenSecretKey2;
    __deviceIdSecretKey = deviceIdSecretKey;
  }

  Future<Uint8List> _enc1Stage1(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey1.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: nonce,
      aad: [12, 12, 10],
    );
    return encrypted;
  }

  Future<Uint8List> _enc1Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey2.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: cnonce,
      aad: [12, 12, 10],
    );

    return encrypted;
  }

  ///Encrypt 1
  Future<String> encrypt1(
      {Nonce cnonce, Nonce nonce, Map<String, dynamic> data}) async {
    Uint8List _data = utf8.encode(json.encode(data));
    return base64
        .encode(await _enc1Stage2(cnonce, await _enc1Stage1(nonce, _data)));
  }

  Future<Uint8List> _dec1Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey2.codeUnits);
    final message = encryptedData;
    final encrypted = await cipher.decrypt(message,
        secretKey: secretKey, nonce: cnonce, aad: [12, 12, 10]);
    return encrypted;
  }

  Future<Uint8List> _dec1Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey1.codeUnits);
    final message = data;
    final encrypted = await cipher.decrypt(message,
        secretKey: secretKey, nonce: nonce, aad: [12, 12, 10]);

    return encrypted;
  }

  ///Decrypt 2
  Future<Map<String, dynamic>> decrypt1(
      {Nonce nonce, Nonce cnonce, String data}) async {
    return json.decode(utf8.decode(await _dec1Stage2(
        nonce, await _dec1Stage1(cnonce, base64.decode(data)))));
  }

  Future<Uint8List> _enc2Stage1(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey1.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: nonce,
      aad: [12, 12, 10],
    );
    return encrypted;
  }

  Future<Uint8List> _enc2Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: cnonce,
      aad: [12, 12, 10],
    );

    return encrypted;
  }

  ///Encrypt 2
  Future<String> encrypt2({Map<String, dynamic> data}) async {
    Uint8List _data = utf8.encode(json.encode(data));
    return base64.encode(await _enc2Stage2(
        Nonce(<int>[54, 23, 55, 98, 5, 78, 2, 44, 88, 5, 63, 10]),
        await _enc2Stage1(
            Nonce(<int>[54, 23, 55, 98, 5, 69, 2, 44, 15, 5, 98, 10]), _data)));
  }

  Future<Uint8List> _dec2Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final message = encryptedData;
    final encrypted = await cipher.decrypt(message,
        secretKey: secretKey, nonce: cnonce, aad: [12, 12, 10]);
    return encrypted;
  }

  Future<Uint8List> _dec2Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey1.codeUnits);
    final message = data;
    final encrypted = await cipher.decrypt(message,
        secretKey: secretKey, nonce: nonce, aad: [12, 12, 10]);

    return encrypted;
  }

  ///Decrypt 2
  Future<Map<String, dynamic>> decrypt2({String data}) async {
    return json.decode(utf8.decode(await _dec2Stage2(
        Nonce(<int>[54, 23, 55, 98, 5, 69, 2, 44, 15, 5, 98, 10]),
        await _dec2Stage1(
            Nonce(<int>[54, 23, 55, 98, 5, 78, 2, 44, 88, 5, 63, 10]),
            base64.decode(data)))));
  }

  ///Encrypt 3
  Future<String> encrypt3(Map<String, dynamic> data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final encrypted = await cipher.encrypt(
      utf8.encode(json.encode(data)),
      secretKey: secretKey,
      nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]),
      aad: [12, 12, 10],
    );
    return base64.encode(encrypted);
  }

  ///Decrypt 3
  Future<Map<String, dynamic>> decrypt3(String encryptedText) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final encrypted = await cipher.decrypt(base64.decode(encryptedText),
        secretKey: secretKey,
        nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]),
        aad: [12, 12, 10]);

    return json.decode(utf8.decode(encrypted));
  }

  ///Encrypt 4
  Future<String> decrypt4(String data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__deviceIdSecretKey.codeUnits);
    final encrypted = await cipher.decrypt(base64.decode(data),
        secretKey: secretKey,
        nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]),
        aad: [12, 12, 10]);

    return utf8.decode(encrypted);
  }

  ///Encrypt 4
  Future<String> encrypt4(String data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__deviceIdSecretKey.codeUnits);
    final encrypted = await cipher.encrypt(
      utf8.encode(data),
      secretKey: secretKey,
      nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]),
      aad: [12, 12, 10],
    );
    return base64.encode(encrypted);
  }
}

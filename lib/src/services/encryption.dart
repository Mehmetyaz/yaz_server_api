import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

///
class Nonce {
  ///
  Nonce(List<int> bytes) : _list = bytes;

  ///
  Nonce.random() : _list = _random;

  static List<int> get _random {
    var res = Uint8List(12);
    for (var i = 0; i < res.length; i++) {
      res[i] = Random().nextInt(255);
    }
    return res;
  }

  ///
  final List<int> _list;

  ///
  List<int> get list => _list;
}

///
EncryptionService encryptionService = EncryptionService();

///
class EncryptionService {
  ///
  factory EncryptionService() => _service;

  EncryptionService._internal();

  static final EncryptionService _service = EncryptionService._internal();

  late String __clientSecretKey1,
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

  ///
  Uint8List mergeMac(SecretBox secretBox) {
    return Uint8List.fromList([]
      ..addAll(secretBox.mac.bytes)
      ..addAll(secretBox.cipherText));
  }

  ///
  SecretBox splitMac(List<int> nonce, Uint8List list) {
    return SecretBox(list.sublist(16),
        nonce: nonce, mac: Mac(list.sublist(0, 16)));
  }

  ///1
  Chacha20 get chacha20Poly1305Aead => Chacha20.poly1305Aead();

  Future<Uint8List> _enc1Stage1(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey1.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: nonce.list,
      aad: [12, 12, 10],
    );
    return mergeMac(encrypted);
  }

  Future<Uint8List> _enc1Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey2.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: cnonce.list,
      aad: [12, 12, 10],
    );

    return mergeMac(encrypted);
  }

  ///Encrypt 1
  Future<String> encrypt1(
      {required Nonce cnonce,
      required Nonce nonce,
      Map<String, dynamic>? data}) async {
    var _data = utf8.encode(json.encode(data)) as Uint8List;
    return base64
        .encode(await _enc1Stage2(cnonce, await _enc1Stage1(nonce, _data)));
  }

  Future<Uint8List> _dec1Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey2.codeUnits);

    var message = splitMac(cnonce.list, encryptedData);

    final encrypted =
        await cipher.decrypt(message, secretKey: secretKey, aad: [12, 12, 10]);
    return encrypted as FutureOr<Uint8List>;
  }

  Future<Uint8List> _dec1Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__clientSecretKey1.codeUnits);

    final message = splitMac(nonce.list, data);

    final encrypted = await cipher.decrypt(message,
        secretKey: secretKey /*, nonce: nonce*/, aad: [12, 12, 10]);

    return encrypted as FutureOr<Uint8List>;
  }

  ///Decrypt 2
  Future<Map<String, dynamic>?> decrypt1(
      {required Nonce nonce,
      required Nonce cnonce,
      required String data}) async {
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
      nonce: nonce.list,
      aad: [12, 12, 10],
    );
    return mergeMac(encrypted);
  }

  Future<Uint8List> _enc2Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: cnonce.list,
      aad: [12, 12, 10],
    );

    return mergeMac(encrypted);
  }

  ///Encrypt 2
  Future<String> encrypt2({Map<String, dynamic>? data}) async {
    var _data = utf8.encode(json.encode(data)) as Uint8List;
    return base64.encode(await _enc2Stage2(
        Nonce(<int>[54, 23, 55, 98, 5, 78, 2, 44, 88, 5, 63, 10]),
        await _enc2Stage1(
            Nonce(<int>[54, 23, 55, 98, 5, 69, 2, 44, 15, 5, 98, 10]), _data)));
  }

  Future<Uint8List> _dec2Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);
    final message = splitMac(cnonce.list, encryptedData);
    final encrypted =
        await cipher.decrypt(message, secretKey: secretKey, aad: [12, 12, 10]);
    return encrypted as FutureOr<Uint8List>;
  }

  Future<Uint8List> _dec2Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey1.codeUnits);
    final message = splitMac(nonce.list, data);
    final encrypted =
        await cipher.decrypt(message, secretKey: secretKey, aad: [12, 12, 10]);

    return encrypted as FutureOr<Uint8List>;
  }

  ///Decrypt 2
  Future<Map<String, dynamic>?> decrypt2({required String data}) async {
    return json.decode(utf8.decode(await _dec2Stage2(
        Nonce(<int>[54, 23, 55, 98, 5, 69, 2, 44, 15, 5, 98, 10]),
        await _dec2Stage1(
            Nonce(<int>[54, 23, 55, 98, 5, 78, 2, 44, 88, 5, 63, 10]),
            base64.decode(data)))));
  }

  ///Encrypt 3 For Token
  Future<String> encrypt3(Map<String, dynamic> data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);

    final encrypted = await cipher.encrypt(
      utf8.encode(json.encode(data)),
      secretKey: secretKey,
      nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]).list,
      aad: [12, 12, 10],
    );
    return base64.encode(mergeMac(encrypted));
  }

  ///Decrypt 3
  Future<Map<String, dynamic>?> decrypt3(String encryptedText) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__tokenSecretKey2.codeUnits);

    final message = splitMac(
        Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]).list,
        base64.decode(encryptedText));

    final encrypted =
        await cipher.decrypt(message, secretKey: secretKey, aad: [12, 12, 10]);

    return json.decode(utf8.decode(encrypted));
  }

  ///Encrypt 4
  Future<String> decrypt4(String data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final secretKey = SecretKey(__deviceIdSecretKey.codeUnits);

    var message = splitMac(
        Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]).list,
        base64.decode(data));

    final encrypted =
        await cipher.decrypt(message, secretKey: secretKey, aad: [12, 12, 10]);

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
      nonce: Nonce(<int>[54, 12, 89, 74, 5, 69, 8, 23, 14, 5, 89, 22]).list,
      aad: [12, 12, 10],
    );
    return base64.encode(mergeMac(encrypted));
  }

  ///
  Future<String> encryptToken(Map<String, dynamic> payload) async {
    var h = {"alg": "HS512", "typ": "JWT"};
    var base64H = base64.encode(utf8.encode(json.encode(h)));
    var base64P = base64.encode(utf8.encode(json.encode(payload)));
    var macMessage = base64.encode(utf8.encode("$base64H.$base64P"));
    var alg = AesCtr.with256bits(macAlgorithm: Hmac.sha512());

    var mac = await alg.encrypt(utf8.encode(macMessage),
        secretKey: SecretKey(__tokenSecretKey1.codeUnits));
    return "$base64H.$base64P.${mac.cipherText}";
  }
}

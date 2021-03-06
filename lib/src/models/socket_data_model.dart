import 'dart:convert';

import 'package:meta/meta.dart';

import '../services/encryption.dart';
import 'statics.dart';

///
class SocketData {
  ///
  SocketData.create(
      {required Map<String, dynamic> data,
      this.messageId,
      required this.type}) {
    messageId ??= Statics.getRandomId(30);
    fullData = {"message_id": messageId, "message_type": type, "data": data};
    isDecrypted = true;
    isEncrypted = false;
  }

  ///
  factory SocketData.fromJson(Map<String, dynamic> data) =>
      SocketData.fromFullData(data);




  ///
  SocketData.fromFullData(this.fullData) {
    fullData!["message_id"] ??= Statics.getRandomId(30);

    schemeValid = fullData!.containsKey("data") &&
        fullData!.containsKey("message_id") &&
        fullData!.containsKey("message_type");

    if (!schemeValid) {
      throw Exception("Socket Data Scheme isn't valid \n"
          "\"data\" is ${fullData!.containsKey("data")}\n"
          "\"message_id\" is ${fullData!.containsKey("message_id")}\n"
          "\"message_type\" is ${fullData!.containsKey("message_type")}");
    }

    messageId = fullData!["message_id"];
    type = fullData!["message_type"];

    isEncrypted =
        fullData!["data"] is String && fullData!["data"].startsWith("enc");
    if (isEncrypted) {
      fullData!["data"] = fullData!["data"].replaceFirst("enc", "");
    }
    isDecrypted = !isEncrypted;
  }

  ///
  factory SocketData.fromSocket(
    String rawData,
  ) {
    return SocketData.fromFullData(json.decode(rawData));
  }
  ///
  SocketData response(Map<String, dynamic> data){
    return SocketData.create(data: data, type: type ,messageId: messageId);
  }

  ///
  Map<String, dynamic>? toJson() => fullData;

  ///
  String? messageId;

  ///
  String? type;

  ///
  late bool schemeValid;

  ///
  bool get success => fullData!["success"] ?? true;

  ///
  set success(bool _suc) {
    fullData!["success"] = _suc;
  }

  ///
  Map<String, dynamic>? get data {
    if (isEncrypted || fullData!["data"] is String) {
      return {"success": false, "reason": "Data is encrypted"};
    }
    // ignore: avoid_as

    return fullData!["data"].map<String, dynamic>(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value));
  }

  ///
  Map<String, dynamic>? fullData = {
    "success": false,
    "reason": "data not created or operated"
  };

  ///
  late bool isDecrypted;

  ///
  late bool isEncrypted;

  ///
  Future<SocketData> encrypt(Nonce? nonce, Nonce? cNonce) async {
    if (isDecrypted) {
      schemeValid = fullData!.containsKey("data") &&
          fullData!.containsKey("message_id") &&
          fullData!.containsKey("message_type");

      if (!schemeValid) {
        throw Exception("Socket Data Scheme isn't valid \n"
            "\"data\" is ${fullData!.containsKey("data")}\n"
            "\"message_id\" is ${fullData!.containsKey("message_id")}\n"
            "\"message_type\" is ${fullData!.containsKey("message_type")}");
      }

      messageId = fullData!["message_id"];
      type = fullData!["message_type"];
      fullData!["data"] =
          // ignore: lines_longer_than_80_chars
          "enc${await encryptionService.encrypt1(nonce: nonce!, cnonce: cNonce!, data: fullData!['data'])}";
      isEncrypted = true;
      isDecrypted = false;
    }
    return this;
  }

  ///
  Future<SocketData> decrypt(Nonce? nonce, Nonce? cNonce) async {
    if (isEncrypted || !(fullData!["data"] is String)) {
      fullData!["data"] = await encryptionService.decrypt1(
          nonce: nonce!, cnonce: cNonce!, data: fullData!['data']);
    }
    isEncrypted = false;
    isDecrypted = true;
    return this;
  }
}

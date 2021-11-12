import 'dart:math';

import '../../yaz_server_api.dart';

///
enum VerificationStatus {
  ///
  verified,

  ///
  waiting,

  ///
  timeout,

  ///
  fail,

  ///
  creationFail,

  ///
  creating,

  ///
  noOther,

  ///
  cancel
}

///
enum VerificationType {
  ///
  mail,

  ///
  phone,

  ///
  device
}

///
class VerificationSession {
  ///
  VerificationSession._(
      {required this.type,
      required this.id,
      required this.code,
      required this.mail,
      this.duration = const Duration(seconds: 60),
      required this.topic,
      required this.onTimeout});


  ///
  static Future<VerificationSession?> create(String id, String mail,
      String topic, VerificationType type, void Function() onTimeout,
      {Duration duration = const Duration(seconds: 60)}) async {
    var res = await server.databaseApi
        .insertQuery(Query.allowAll(queryType: QueryType.insert)
          ..collection = "verifications"
          ..data = {
            "verification_id": id,
            "duration": duration.inMilliseconds,
            "verification_topic": topic,
            "status": VerificationStatus.creating.index,
            "verification_type": VerificationType.mail.index,
            "mail": mail,
            "used": false
          });

    print("Verif Creating: $res");
    if (res != null) {
      return VerificationSession._(
          type: type,
          id: id,
          code: _randomNumbers(6),
          mail: mail,
          topic: topic,
          onTimeout: onTimeout,
          duration: duration);
    }
    return null;
  }

  static String _randomNumbers(int length) {
    var buf = StringBuffer();
    var i = 0;
    while (i < length) {
      buf.write(Random().nextInt(10).toString());
      i++;
    }
    return buf.toString();
  }

  ///
  String id, topic, code, mail;

  ///
  bool timeOut = false;

  ///
  Duration duration;

  ///
  VerificationType type;

  ///
  void Function() onTimeout;

  ///
  void sendCode() {}

  ///
  void watch() {
    Future.delayed(duration).then((value) async {
      onTimeout.call();
      timeOut = true;
      await server.databaseApi
          .update(Query.allowAll(queryType: QueryType.update, equals: {
        "verification_id": id
      }, update: {
        "\$set": {"status": VerificationStatus.verified.index}
      })
            ..collection = "verifications");
    });
  }

  ///
  Future<bool> verify(String verificationCode) async {
    if (timeOut) return false;
    if (code == verificationCode) {
      var res = await server.databaseApi
          .update(Query.allowAll(queryType: QueryType.update, equals: {
        "verification_id": id
      }, update: {
        "\$set": {"status": VerificationStatus.verified.index}
      })
            ..collection = "verifications");

      return res != null;
    }
    return false;
  }
}

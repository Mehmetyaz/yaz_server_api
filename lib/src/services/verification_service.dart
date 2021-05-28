import '../../yaz_server_api.dart';
import '../models/socket_data_model.dart';
import '../models/verification.dart';
import '../models/web_socket_listener.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

///
class VerificationService {
  ///
  factory VerificationService() => _internal;

  VerificationService._();

  static final VerificationService _internal = VerificationService._();

  ///
  late String mail, pass;

  ///
  void init(String mail, String pass) {
    this.mail = mail;
    this.pass = pass;
    server.operationService..addCustomOperation(
        "verification_code", onVerify)..addCustomOperation(
        "verification_request", onRequest);
  }

  ///
  Future<void> sendMail(String toAddress, String code) async {
    final smtpServer = yandex(mail, pass);
    // Use the SmtpServer class to configure an SMTP server:
    // final smtpServer = SmtpServer('smtp.domain.com');
    // See the named arguments of SmtpServer for further configuration
    // options.

    // Create our message.
    final message = Message()
      ..from = Address(mail, 'Dikimall Password Reset')
      ..recipients.add(toAddress)
      ..subject = 'Dikimall Password Reset'
      ..text = ''
      ..html =
          "<h1>Test</h1>\n<p> Bu Kod ile Şifrenizi Yenileyebilirsiniz: $code</p>";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent: ${code}.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
    // DONE

    var connection = PersistentConnection(smtpServer);

    // Send the first message
    await connection.send(message);

    // close the connection
    await connection.close();
  }

  ///
  Map<String, VerificationSession> verifications = {};

  ///
  Future<void> onVerificationUse(WebSocketListener listener,
      SocketData data) async {
    if (data.data == null) return;

    var res = await useVerification(
        topic: data.data!["topic"],
        id: data.data!["id"],
        token: data.data!["token"],
        device: listener.deviceID!);

    sendMessage(listener.client, data.response({})
      ..success = true);
    return;
  }

  ///
  Future<Map<String, dynamic>?> useVerification({
    required String topic,
    required String id,
    required String token,
    required String device,
  }) async {
    var exists = await checkVerification(id, topic);
    if (exists != null) {
      var res = await server.databaseApi.update((collection("verifications")
        ..where("verification_id", isEqualTo: id)..where(
            "status", isEqualTo: VerificationStatus.verified.index)..where(
            "used", isEqualTo: false)..where("verification_topic", isEqualTo: topic))
          .toQuery(QueryType.update ,allowAll: true)
        ..update = {
          "\$set": {
            "used": true,
            "use_info": {
              "device": device,
              "token": token,
            }
          }
        });

      return res;
    }

    return null;
  }

  ///
  Future<void> onVerify(WebSocketListener listener, SocketData data) async {
    var id = data.data!["id"];
    var code = data.data!["code"];
    if (verifications[id] == null) {
      sendMessage(listener.client,
          data.response({"error": "not_found"})
            ..success = false);
      return;
    }

    var res = await verifications[id]!.verify(code);

    sendMessage(listener.client,
        data.response({"success": true, "verified": true})
          ..success = res);
    return;
  }

  ///
  Future<void> onRequest(WebSocketListener listener, SocketData data) async {
    if (data.data != null) {
      var id = data.data!["id"];
      verifications[id] = (await VerificationSession.create(
          id,
          data.data!["mail"],
          data.data!["topic"],
          VerificationType.values[data.data!["type"]], () {
        verifications.remove(id);
      }, duration: Duration(milliseconds: data.data ? ["duration"])))!;

      await sendMail(verifications[id]!.mail, verifications[id]!.code);
      sendMessage(listener.client,
          data.response({"status": VerificationStatus.waiting.index}));
    }
  }

  ///
  Future<Map<String, dynamic>?> checkVerification(String id,
      String topic) async {
    print("CHECKING");
    try {
      var res = await server.databaseApi.query((collection("verifications")
        ..where("verification_id", isEqualTo: id)..where(
            "status", isEqualTo: VerificationStatus.verified.index)..where(
            "used", isEqualTo: false)..where("verification_topic", isEqualTo: topic))
          .toQuery(QueryType.query,allowAll: true));
      print("VERIF CHECK RES $res");
      return res;
    } catch (e , s) {
      print("CHECKING HATA: $e \n $s");
    }
  }
}

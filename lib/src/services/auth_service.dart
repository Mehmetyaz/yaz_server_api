import 'dart:async';

import 'package:cryptography/cryptography.dart';

import '../../yaz_server_api.dart';
import '../models/socket_data_model.dart';
import '../models/web_socket_listener.dart';
import 'verification_service.dart';

///
class AuthService {
  ///
  factory AuthService() => _internal;

  ///
  AuthService._();

  static final AuthService _internal = AuthService._();

  ///
  void init(String mail, String pass) {
    server.operationService
      ..addCustomOperation("login", login)
      ..addCustomOperation("register", register)
      ..addCustomOperation("user_exists", userExists)
      ..addCustomOperation("login_admin", loginAdmin)
      ..addCustomOperation("set_new_password", setNewPassword);
    verificationService.init(mail, pass);
  }

  final _db = server.databaseApi;

  ///
  final VerificationService verificationService = VerificationService();



  ///
  Future<void> setNewPassword(
      WebSocketListener listener, SocketData socketData) async {
    print("NEW PASS${socketData.fullData}");
    try {
      if (socketData.data == null) return;
      var data = socketData.data!;

      var res = await verificationService.checkVerification(
          data["id"], "password_reset");

      if (res == null) return;

      var userDoc = await server.databaseApi
          .query(Query.allowAll(queryType: QueryType.query, equals: {
        "user_mail": res["mail"],
      })
            ..collection = "users");

      if (userDoc == null) {
        print("user data is null: $userDoc");
        return;
      }
      print("user doc DATA: $userDoc");

      var secret = <String, dynamic>{
        'user_mail': res['mail'],
        'password': data["password"]
      };

      var secretEncrypted = await encryptionService.encrypt3(secret);

      var used = await verificationService.useVerification(
          topic: "password_reset",
          id: data["id"],
          token: data["token"],
          device: listener.deviceID!);

      print("used DATA: $used");

      var update = await server.databaseApi.update(
        Query.allowAll(
            queryType: QueryType.update,
            equals: {"user_id": userDoc["user_id"]})
          ..collection = "users_secret"
          ..update = {
            "\$set": {'data': secretEncrypted}
          },
      );

      print("UPDATE DATA: $update");

      sendMessage(
          listener.client,
          socketData.response({
            "success": update!["success"],
          })
            ..success = update["success"]);
    } on Exception catch (e, s) {
      sendMessage(
          listener.client,
          socketData.response({"success": false, "reason": e, "stack_trace": s})
            ..success = false);
    }
    return;
  }

  ///
  Future<void> userExists(WebSocketListener listener, SocketData data) async {
    var res = await _db.exists((collection("users")
          ..where("user_mail", isEqualTo: data.data!["mail_or_phone"]))
        .toQuery(QueryType.exists,
            allowAll: true, token: AccessToken.fromToken(data.data!["token"])));
    print("EXISTS QQQQ: ${res}");
    sendMessage(listener.client,
        data.response(res ?? {"success": false})..success = true);
    return;
  }

  ///
  Future<void> register(WebSocketListener listener, SocketData data) async {
    var dbRes = await _db.addUserToDb(data.data, listener.deviceID);
    var res = await SocketData.fromFullData({
      'message_id': data.messageId,
      'message_type': data.type,
      'data': dbRes,
      "success": true
    }).encrypt(listener.nonce, listener.cnonce);
    sendMessage(listener.client, res);
    return;
  }

  ///
  Future<void> loginAdmin(WebSocketListener listener, SocketData data) async {
    var _dbRes = await (_db.confirmUser(data.data, listener.deviceID));

    if (_dbRes == null) return;

    var isAdmin = (await _db.exists(Query.allowAll(
      queryType: QueryType.exists,
      equals: {"mail": _dbRes['secret']['user_mail']},
    )))!["exists"];
    if (!isAdmin) {
      return;
    }
    AccessToken token;
    if (_dbRes['success']) {
      token = AccessToken.generateForUser(
          authType: AuthType.admin,
          mail: _dbRes['secret']['user_mail'],
          deviceID: listener.deviceID!,
          uId: _dbRes['open']['user_id']);
      _dbRes['open']['token'] = await token.encryptedToken;
    }
    // print(_dbRes['open']);

    sendMessage(
        listener.client,
        await SocketData.fromFullData({
          'message_id': data.messageId,
          'message_type': data.type,
          'success': _dbRes['success'],
          'data': _dbRes['open']
        }).encrypt(listener.nonce, listener.cnonce));
    return;
  }

  ///
  Future<void> login(WebSocketListener listener, SocketData data) async {
    var _dbRes = await (_db.confirmUser(data.data, listener.deviceID));
    AccessToken token;
    if (_dbRes == null) {
      sendMessage(
          listener.client,
          await SocketData.fromFullData({
            'message_id': data.messageId,
            'message_type': data.type,
            'success': false,
          }).encrypt(listener.nonce, listener.cnonce));
      return;
    }
    if (_dbRes['success']) {
      token = AccessToken.generateForUser(
          authType: AuthType.loggedIn,
          mail: _dbRes['secret']['user_mail'],
          deviceID: listener.deviceID!,
          uId: _dbRes['open']['user_id']);
      _dbRes['open']['token'] = await token.encryptedToken;
    }
    // print(_dbRes['open']);

    sendMessage(
        listener.client,
        await SocketData.fromFullData({
          'message_id': data.messageId,
          'message_type': data.type,
          'success': _dbRes['success'],
          'data': _dbRes['open']
        }).encrypt(listener.nonce, listener.cnonce));
    return;
  }
}

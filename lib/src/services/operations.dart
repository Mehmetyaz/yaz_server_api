import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:mongo_dart/mongo_dart.dart';

import '../models/listener.dart';
import '../models/query.dart';
import '../models/socket_data_model.dart';
import '../models/token/token.dart';
import '../models/web_socket_listener.dart';
import 'mongo_db_service.dart';
import 'trigger_service.dart';

///
Operation socketOperations = Operation();

///Mongo db Operations class
class Operation {
  ///Singleton class constructor
  factory Operation() => _instance;

  Operation._internal();

  static final _instance = Operation._internal();

  final MongoDb _db = MongoDb();

  final TriggerService _triggerService = TriggerService();

  ///
  final Map<String, CustomOperation> _customOperations =
      <String, CustomOperation>{};

  ///
  void addCustomOperation(String name, CustomOperation operation) {
    _customOperations[name] = operation;
  }

  ///
  void clearCustomOperation(String name) {
    _customOperations.remove(name);
  }

  ///Operate
  // ignore: missing_return
  Future<String> operate(WebSocketListener listener, SocketData data) async {
    ///data : full socket data
    ///

    if (data.type == 'register') {
      var res = await SocketData.fromFullData({
        'message_id': data.messageId,
        'message_type': data.type,
        'data': await _db.addUserToDb(data.data, listener.deviceID)
      }).encrypt(listener.nonce, listener.cnonce);
      sendMessage(listener.client, res);

      return 'ok';
    } else if (data.type == 'login') {
      var _dbRes = await (_db.confirmUser(data.data, listener.deviceID)
          as FutureOr<Map<String, dynamic>>);
      AccessToken token;
      if (_dbRes['success']) {
        token = AccessToken.generateForUser(
            authType: AuthType.loggedIn,
            mail: _dbRes['secret']['user_mail'],
            deviceID: listener.deviceID!,
            uId: _dbRes['open']['user_id'],
            passWord: _dbRes['secret']['password']);
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
      return 'ok';
    } else if (data.type == 'login_admin') {
      var _dbRes = await (_db.confirmUser(data.data, listener.deviceID)
          as FutureOr<Map<String, dynamic>>);

      var isAdmin = (await _db.exists(Query.allowAll(
        queryType: QueryType.exists,
        equals: {"mail": _dbRes['secret']['user_mail']},
      )))!["exists"];
      if (!isAdmin) {
        return "false";
      }
      AccessToken token;
      if (_dbRes['success']) {
        token = AccessToken.generateForUser(
            authType: AuthType.admin,
            mail: _dbRes['secret']['user_mail'],
            deviceID: listener.deviceID!,
            uId: _dbRes['open']['user_id'],
            passWord: _dbRes['secret']['password']);
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
      return 'ok';
    } else if (data.type == "remove_stream") {
      if (data.data != null &&
          data.data!["message_id"] != null &&
          data.data!["object_id"] != null) {
        _triggerService.removeListener(
            data.data!["object_id"], data.data!["message_id"]);
      }
      return "ok";
    } else if (data.type == 'query') {
      if (data.data != null) {
        late Query q;
        Map<String, dynamic>? dbResponse;
        try {
          // print("ON OP: ${data.data}");
          q = Query.fromMap(data.data!['query']);
        } on Exception catch (e) {
          dbResponse = {"success": false, "reason": e.toString()};
        }

        if (dbResponse != null) {
          sendMessage(
              listener.client,
              await SocketData.fromFullData({
                'message_id': data.messageId,
                'message_type': data.type,
                'success': dbResponse['success'],
                'data': dbResponse
              }).encrypt(listener.nonce, listener.cnonce));
          return "ok";
        }

        var isListen = false;
        switch (q.queryType) {
          case QueryType.query:
            dbResponse = await _db.query(q);
            break;
          case QueryType.delete:
            dbResponse = await _db.delete(q);
            break;
          case QueryType.listQuery:
            dbResponse = await _db.listQuery(q);
            break;
          case QueryType.insert:
            dbResponse = await _db.insertQuery(q);
            break;
          case QueryType.update:
            dbResponse = await _db.update(q);
            break;
          case QueryType.exists:
            dbResponse = await _db.exists(q);
            break;
          case QueryType.streamQuery:
            dbResponse = await _db.query(q);
            isListen = true;
            break;
          case QueryType.count:
            dbResponse = await _db.count(q);
            break;
          default:
            break;
        }

        // print("DB RESPONSE \nDB RESPONSE \nDB RESPONSE \nDB RESPONSE \n"
        //     "${q.queryType}   $isListen"
        //     "DB RESPONSE \nDB RESPONSE \nDB RESPONSE \nDB RESPONSE \n");

        sendMessage(
            listener.client,
            await SocketData.fromFullData({
              'message_id': data.messageId,
              'message_type': data.type,
              'success': dbResponse!['success'],
              'data': dbResponse
            }).encrypt(listener.nonce, listener.cnonce));

        if (isListen) {
          _triggerService.addListener(DbListener(
              messageId: data.messageId,
              collection: q.collection,
              id: dbResponse["_id"],
              listener: listener));
        }

        return 'ok';
      } else {
        return "false";
      }
    } else if (_customOperations.containsKey(data.type)) {
      try {
        await _customOperations[data.type!]!(listener, data);
        return "ok";
      } on Exception {
        //TODO: ADD ERROR
        return "error";
      }
    } else {
      return "undefined";
    }
  }
}

///
typedef CustomOperation = Future<void> Function(
    WebSocketListener listener, SocketData socketData);

/*else if (data.type == 'upload_image') {
      print("IMAGE UPLOADED START");
      if (data.data != null) {
        print("IMAGE UPLOADED");
        var mediaService = MediaService();
        var bytes = Statics.uint8Cast(data.data['image_bytes']);
        print("IMAGE UPLOADED IMAGE BYTES:::: ${bytes.length}");
        var imageID = await mediaService.addImage(bytes, "");
        print("IMAGE UPLOADED IMAGE ID:::: $imageID");

        print("IMAGE UPLOADED:::: $imageID");
        sendMessage(
            listener.client,
            await SocketData.fromFullData({
              'message_id': data.messageId,
              'message_type': data.type,
              'success': true,
              'data': {"image_id": imageID}
            }).encrypt(listener.nonce, listener.cnonce));
        return 'ok';
      } else {
        return 'false';
      }
    } else if (data.type == 'update_document') {
      print("UPDATE STARTED");
      if (data.data != null) {
        var q = Query.fromMap(data.data);
        var dbResponse = await _db.update(q);
        print(dbResponse);
        sendMessage(
            listener.client,
            await SocketData.fromFullData({
              'message_id': data.messageId,
              'message_type': data.type,
              'success': dbResponse['success'],
              'data': dbResponse
            }).encrypt(listener.nonce, listener.cnonce));
        return 'ok';
      } else {
        return "false";
      }
    }*/

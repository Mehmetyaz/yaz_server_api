import 'dart:async';

import '../../yaz_server_api.dart';
import '../models/listener.dart';
import '../models/query.dart';
import '../models/socket_data_model.dart';
import '../models/token/token.dart';
import '../models/web_socket_listener.dart';
import 'trigger_service.dart';

///
Operation socketOperations = Operation();

///Mongo db Operations class
class Operation {
  ///Singleton class constructor
  factory Operation() => _instance;

  Operation._internal();

  static final _instance = Operation._internal();

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
    final _db = server.databaseApi;
    if (data.type == "remove_stream") {
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


import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

import '../models/listener.dart';
import '../models/query.dart';
import '../models/socket_data_model.dart';
import '../models/web_socket_listener.dart';
import 'mongo_db_service.dart';
import 'permission_handler.dart';

///On Document Create Function
typedef OnCreate = Future<void> Function(Query query);

///On Document Delete Function
typedef OnDelete = Future<void> Function(
    Query query, Map<String, dynamic> before);

///On Document Update Function
typedef OnUpdate = Future<void> Function(
    Query query, Map<String, dynamic> before, Map<String, dynamic> after);

///
typedef OnChange = Future<void> Function(
    DbListener listener, MongoDbOperationType type, Map<String, dynamic> after);

///
typedef PeriodicTrigger = Future<void> Function();

///
TriggerService triggerService = TriggerService();

///
class TriggerService {
  ///
  factory TriggerService() => _instance;

  TriggerService._internal();

  static final TriggerService _instance = TriggerService._internal();

  final Map<String, List<OnCreate>> _onCreateTriggers =
      <String, List<OnCreate>>{};

  final Map<String, List<OnDelete>> _onDeleteTriggers =
      <String, List<OnDelete>>{};

  final Map<String, List<OnUpdate>> _onUpdateTriggers =
      <String, List<OnUpdate>>{};

  final Map<String, Timer> _periodic = <String, Timer>{};

  ///
  final Map<String, bool> _resourceRequiresDelete = <String, bool>{};
  final Map<String, bool> _resourceRequiresUpdate = <String, bool>{};

  ///
  Duration timeout = const Duration(seconds: 30);

  ///
  void cancelPeriodic(String name) {
    if (_periodic[name] != null) {
      if (_periodic[name].isActive) {
        _periodic[name].cancel();
      }
      _periodic.remove(name);
    }
  }

  ///
  void periodic(String name, Duration duration, PeriodicTrigger callback) {
    var timer = Timer.periodic(duration, (t) {
      callback().timeout(timeout, onTimeout: () {
        print('PERIODIC FUNCTION TIMEOUT');
      });
    });
    _periodic[name] = timer;
  }

  ///
  void onCreate(String collection, OnCreate onCreate) {
    if (_onCreateTriggers[collection] == null) {
      _onCreateTriggers[collection] = <OnCreate>[];
    }
    _onCreateTriggers[collection].add(onCreate);
  }

  ///
  void onDelete(String collection, OnDelete onDelete,
      {bool beforeRequired = false}) {
    if (_onDeleteTriggers[collection] == null) {
      _onDeleteTriggers[collection] = <OnDelete>[];
    }
    _resourceRequiresDelete[collection] = beforeRequired;
    _onDeleteTriggers[collection].add(onDelete);
  }

  ///
  void onUpdate(String collection, OnUpdate onUpdate,
      {bool beforeRequired = false}) {
    if (_onUpdateTriggers[collection] == null) {
      _onUpdateTriggers[collection] = <OnUpdate>[];
    }
    _resourceRequiresUpdate[collection] = beforeRequired;
    _onUpdateTriggers[collection].add(onUpdate);
  }

  ///
  void addListener(DbListener dbListener) {
    // print("EKLENDI:::::: ${dbListener.id} \n\n\n\n");

    if ( _listeners[dbListener.id] == null){
      _listeners[dbListener.id] = <String , DbListener>{};
    }

    _listeners[dbListener.id][dbListener.messageId] = dbListener;
  }

  _addChatListener(DbListener dbListener) {

  }


  ///
  final Map<ObjectId, Map<String , DbListener>> _listeners =
      <ObjectId, Map<String , DbListener>>{};
  final Map<ObjectId, Map<String , DbListener>> _chatListener =
  <ObjectId, Map<String , DbListener>>{};
  /// millis epoch
  final Map<ObjectId, int> queueLast = <ObjectId, int>{};

  ///
  void removeListener(ObjectId objectId, String messageID) {
    if ( _listeners[objectId] == null){
      _listeners[objectId] = <String , DbListener>{};
    }
    _listeners[objectId].remove(messageID);
    if (_listeners[objectId].isEmpty) {
      _listeners.remove(objectId);
    }
    //TODO:REMOVE
    print("OBJECTID: ${_listeners[objectId]}");
  }

  final Map<ObjectId, List<DbListener>> _listenersToRemove =
      <ObjectId, List<DbListener>>{};

  ///
  void _remove() {
    _removing = true;
    print(_listenersToRemove.keys);
    for (var removedID in _listenersToRemove.keys) {
      for (var removingListener in _listenersToRemove[removedID]) {
        _listeners[removedID].remove(removingListener);
      }
    }
    _removing = false;
  }

  bool _removing = false;

  Future<void> _notify(
      ObjectId objectId, Map<String, dynamic> data, int millis) async {
    try {
      if (_listeners.containsKey(objectId)) {
        print("contains");
        await Future.delayed(const Duration(seconds: 2));

        // ignore: literal_only_boolean_expressions
        while (true) {
          if (!_removing) {
            break;
          } else {
            await Future.delayed(const Duration(milliseconds: 3));
          }
        }

        if ((queueLast[objectId] != null && queueLast[objectId] == millis)) {
          for (var element in _listeners[objectId].values ?? <String, DbListener>{}.values) {


            if (element.collection != "user_chat_documents" && element.isOutDate) {
              if ( _listeners[objectId] == null){
                _listeners[objectId] = <String , DbListener>{};
              }
              // _listeners[objectId].remove(element.messageId);
              // if (_listeners[objectId].isEmpty) {
              //   _listeners.remove(objectId);
              // }
              if (_listenersToRemove[objectId] == null) {
                _listenersToRemove[objectId] = <DbListener>[];
              }
              _listenersToRemove[objectId].add(element);
            } else {
              print("sending : ${element.messageId}");

              //ignore: unawaited_futures
              sendAndWaitMessage(
                      element.listener,
                      await SocketData.fromFullData(<String, dynamic>{
                        'message_id': element.messageId,
                        'message_type': "streaming",
                        'success': true,
                        'data': data
                      }).encrypt(
                          element.listener.nonce, element.listener.cnonce),
                      waitingType: "stream_received",
                      waitingID: element.messageId)
                  .timeout(const Duration(seconds: 5), onTimeout: () {
                print("timeout");

                if (_listenersToRemove[objectId] == null) {
                  _listenersToRemove[objectId] = <DbListener>[];
                }
                _listenersToRemove[objectId].add(element);


                // if ( _listeners[objectId] == null){
                //   _listeners[objectId] = <String , DbListener>{};
                // }
                // _listeners[objectId].remove(element.messageId);
                // if (_listeners[objectId].isEmpty) {
                //   _listeners.remove(objectId);
                // }
                /*

                if (_listenersToRemove[objectId] == null) {
                  _listenersToRemove[objectId] = <DbListener>[];
                }
                _listenersToRemove[objectId].add(element);*/
                return null;
              });
            }
          }
          _remove();
        }
      } else {
        print("not contains");
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  ///
  void notifyListeners(ObjectId objectId, Map<String, dynamic> data) {
    var date = DateTime.now().millisecondsSinceEpoch;
    queueLast[objectId] = date;
    _notify(objectId, data, date);
  }

  void _triggerUpdates(Query query, Map<String, dynamic> before, afterReq,
      Map<String, dynamic> res) {
    // print("UPDATE LISTENERS LEN: : "
    // ignore: lines_longer_than_80_chars
    //     ": ${_listeners[res["data"]["_id"]] == null ? null : _listeners[res["data"]["_id"]].length}");

    var isListen = _listeners[res["data"]["_id"]] != null &&
        _listeners[res["data"]["_id"]].isNotEmpty;

    print("ISLISTEN::: $isListen");

    if (afterReq || isListen) {
      PermissionHandler.resource(query).then((value) {
        for (var trig in _onUpdateTriggers[query.collection] ?? <OnUpdate>[]) {
          trig(query, before, value).timeout(timeout, onTimeout: () {
            print("OnUpdate Function Timeout");
          });
        }
        value["type"] = "update";
        notifyListeners(res["data"]["_id"], value);
      });
    } else {
      for (var trig in _onUpdateTriggers[query.collection] ?? <OnUpdate>[]) {
        trig(query, before, null).timeout(timeout, onTimeout: () {
          print("OnUpdate Function Timeout");
        });
      }
    }
  }

  /// Only Use Update Operation

  void _triggerDeletes(
      Query query, Map<String, dynamic> before, Map<String, dynamic> res) {
    for (var trig in _onDeleteTriggers[query.collection] ?? <OnDelete>[]) {
      trig(query, before).timeout(timeout, onTimeout: () {
        print("OnDelete Function Timeout");
      });
    }
    notifyListeners(res["_id"], {"type": "delete"});
  }

  void _triggerCreates(Query query, Map<String, dynamic> res) {
    for (var trig in _onCreateTriggers[query.collection] ?? <OnCreate>[]) {
      trig(query).timeout(timeout, onTimeout: () {
        print("OnCreate Function Timeout");
      });
    }
  }


  ///Trigger
  Future<Map<String, dynamic>> triggerAndReturn(
      Query query, Interop interop) async {
    switch (query.operationType) {
      case MongoDbOperationType.update:
        Map<String, dynamic> res;
        var req = _resourceRequiresUpdate[query.collection] ?? false;
        Map<String, dynamic> before;
        if (req) {
          before = await PermissionHandler.resource(query);
        }
        res = await interop();
        _triggerUpdates(
            query,
            before,
            _onUpdateTriggers[query.collection] != null &&
                _onUpdateTriggers[query.collection].isNotEmpty,
            res);
        return res;
        break;
      case MongoDbOperationType.delete:
        Map<String, dynamic> res;
        var req = _resourceRequiresDelete[query.collection] ?? false;
        Map<String, dynamic> before;
        if (req) {
          before = await PermissionHandler.resource(query);
        }

        res = await interop();
        _triggerDeletes(query, before, res);
        return res;
        break;
      case MongoDbOperationType.read:
        return interop();
        break;
      case MongoDbOperationType.create:
        Map<String, dynamic> res;
        res = await interop();
        _triggerCreates(query, res);
        return res;
        break;

      default:
        return interop();
    }
  }
}

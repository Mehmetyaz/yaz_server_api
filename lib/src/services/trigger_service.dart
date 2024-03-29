import 'dart:async';

import '../models/listener.dart';
import '../models/query.dart';
import '../models/socket_data_model.dart';
import '../models/user/current_user.dart';
import '../models/web_socket_listener.dart';
import 'database/database_abstract.dart';
import 'permission_handler.dart';

///On Document Create Function
typedef OnCreate = Future<void> Function(Query query);

///On Document Delete Function
typedef OnDelete = Future<void> Function(
    Query query, Map<String, dynamic>? before);

///On Document Update Function
typedef OnUpdate = Future<void> Function(
    Query query, Map<String, dynamic>? before, Map<String, dynamic>? after);

///
typedef OnChange = Future<void> Function(
    DbListener listener, DbOperationType type, Map<String, dynamic> after);

///
typedef PeriodicTrigger = Future<void> Function();

/// User logged in
typedef OnUserLoggedIn = Future<void> Function(YazApiUser user);

/// User register
typedef OnUserRegister = Future<void> Function(YazApiUser user);

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

  final Map<String, OnUserLoggedIn> _userLoggedIn = {};

  final Map<String, OnUserRegister> _userRegister = {};

  ///
  void onUserLoggedIn(String triggerName, OnUserLoggedIn onUserLoggedIn) {
    _userLoggedIn[triggerName] = onUserLoggedIn;
  }

  ///
  void onUserRegister(String triggerName, OnUserRegister onUserRegister) {
    _userRegister[triggerName] = onUserRegister;
  }

  ///
  void removeUserTrigger(String triggerName) {
    _userLoggedIn.remove(triggerName);
    _userRegister.remove(triggerName);
  }

  ///
  void cancelPeriodic(String name) {
    if (_periodic[name] != null) {
      if (_periodic[name]!.isActive) {
        _periodic[name]!.cancel();
      }
      _periodic.remove(name);
    }
  }

  ///
  void periodic(String name, Duration duration, PeriodicTrigger callback) {
    var timer = Timer.periodic(duration, (t) {
      callback().timeout(timeout, onTimeout: () {});
    });
    _periodic[name] = timer;
  }

  ///
  void onCreate(String collection, OnCreate onCreate) {
    if (_onCreateTriggers[collection] == null) {
      _onCreateTriggers[collection] = <OnCreate>[];
    }
    _onCreateTriggers[collection]!.add(onCreate);
  }

  ///
  void onDelete(String collection, OnDelete onDelete,
      {bool beforeRequired = false}) {
    if (_onDeleteTriggers[collection] == null) {
      _onDeleteTriggers[collection] = <OnDelete>[];
    }
    _resourceRequiresDelete[collection] = beforeRequired;
    _onDeleteTriggers[collection]!.add(onDelete);
  }

  ///
  void onUpdate(String collection, OnUpdate onUpdate,
      {bool beforeRequired = false}) {
    if (_onUpdateTriggers[collection] == null) {
      _onUpdateTriggers[collection] = <OnUpdate>[];
    }
    _resourceRequiresUpdate[collection] = beforeRequired;
    _onUpdateTriggers[collection]!.add(onUpdate);
  }

  ///
  void addListener(DbListener dbListener) {


    if (_listeners[dbListener.id] == null) {
      _listeners[dbListener.id] = <String?, DbListener>{};
    }

    _listeners[dbListener.id]![dbListener.messageId] = dbListener;
  }

  ///
  final Map<String?, Map<String?, DbListener>> _listeners =
      <String?, Map<String?, DbListener>>{};

  /// millis epoch
  final Map<String?, int> queueLast = <String?, int>{};

  /// millis epoch
  final Map<String?, int> lastSends = <String?, int>{};

  ///
  void removeListener(String objectId, String? messageID) {
    if (_listeners[objectId] == null) {
      _listeners[objectId] = <String?, DbListener>{};
    }
    _listeners[objectId]!.remove(messageID);
    if (_listeners[objectId]!.isEmpty) {
      _listeners.remove(objectId);
    }
  }

  final Map<String?, List<DbListener>> _listenersToRemove =
      <String?, List<DbListener>>{};

  ///
  void _remove() {
    _removing = true;
    for (var removedID in _listenersToRemove.keys) {
      for (var removingListener in _listenersToRemove[removedID]!) {
        _listeners[removedID]!.remove(removingListener);
        if (_listeners[removedID] != null && _listeners[removedID]!.isEmpty) {
          _listeners.remove(removedID);
          queueLast.remove(removedID);
          lastSends.remove(removedID);
        }
      }
    }
    _removing = false;
  }

  bool _removing = false;

  Future<void> _notify(
      String? objectId, Map<String, dynamic> data, int millis) async {
    try {

      if (_listeners.containsKey(objectId)) {
        await Future.delayed(const Duration(seconds: 2));

        // ignore: literal_only_boolean_expressions
        while (true) {
          if (!_removing) {
            break;
          } else {
            await Future.delayed(const Duration(milliseconds: 3));
          }
        }

        var a = (queueLast[objectId] != null && queueLast[objectId] == millis);
        var b = (lastSends[objectId] != null &&
            DateTime.now().millisecondsSinceEpoch - lastSends[objectId]! >
                2000);


        if (a || b) {
          lastSends[objectId] = DateTime.now().millisecondsSinceEpoch;
          for (var element in List.from(_listeners[objectId]!.values)) {
            if (element.collection != "user_chat_documents" &&
                element.isOutDate) {
              if (_listeners[objectId] == null) {
                _listeners[objectId] = <String?, DbListener>{};
              }
              // _listeners[objectId].remove(element.messageId);
              // if (_listeners[objectId].isEmpty) {
              //   _listeners.remove(objectId);
              // }
              if (_listenersToRemove[objectId] == null) {
                _listenersToRemove[objectId] = <DbListener>[];
              }
              _listenersToRemove[objectId]!.add(element);
            } else {
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
                if (_listenersToRemove[objectId] == null) {
                  _listenersToRemove[objectId] = <DbListener>[];
                }
                _listenersToRemove[objectId]!.add(element);

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
      } else {}
    } on Exception {
      //TODO: ADD ERROR
    }
  }

  ///
  void notifyListeners(String? objectId, Map<String, dynamic> data) {
    var date = DateTime.now().millisecondsSinceEpoch;
    queueLast[objectId] = date;
    _notify(objectId, data, date);
  }

  void _triggerUpdates(Query query, Map<String, dynamic>? before, afterReq,
      Map<String, dynamic> res) {


    if (res.containsKey("data") && res["data"] != null) {
      var isListen = _listeners[res["data"]["_id"].toString()] != null &&
          _listeners[res["data"]["_id"].toString()]!.isNotEmpty;


      if (afterReq || isListen) {
        PermissionHandler.resource(query).then((value) {
          for (var trig
              in _onUpdateTriggers[query.collection!] ?? <OnUpdate>[]) {
            trig(query, before, value).timeout(timeout, onTimeout: () {});
          }
          value!["type"] = "update";
          notifyListeners(res["data"]["_id"].toString(), value);
        });
      } else {
        for (var trig in _onUpdateTriggers[query.collection!] ?? <OnUpdate>[]) {
          trig(query, before, null).timeout(timeout, onTimeout: () {});
        }
      }
    }
  }

  /// Only Use Update Operation

  void _triggerDeletes(
      Query query, Map<String, dynamic>? before, Map<String, dynamic> res) {
    for (var trig in _onDeleteTriggers[query.collection!] ?? <OnDelete>[]) {
      trig(query, before).timeout(timeout, onTimeout: () {});
    }
    notifyListeners(res["_id"].toString(), {"type": "delete"});
  }

  void _triggerCreates(Query query, Map<String, dynamic> res) {
    for (var trig in _onCreateTriggers[query.collection!] ?? <OnCreate>[]) {
      trig(query).timeout(timeout, onTimeout: () {});
    }
  }

  ///Trigger
  Future<Map<String, dynamic>> triggerAndReturn(
      Query query, Interop interop) async {
    switch (query.operationType) {
      case DbOperationType.update:
        Map<String, dynamic> res;
        var req = _resourceRequiresUpdate[query.collection!] ?? false;
        Map<String, dynamic>? before;
        if (req) {
          before = await PermissionHandler.resource(query);
        }
        res = await interop();
        _triggerUpdates(
            query,
            before,
            _onUpdateTriggers[query.collection!] != null &&
                _onUpdateTriggers[query.collection!]!.isNotEmpty,
            res);
        return res;

      case DbOperationType.delete:
        Map<String, dynamic> res;
        var req = _resourceRequiresDelete[query.collection!] ?? false;
        Map<String, dynamic>? before;
        if (req) {
          before = await PermissionHandler.resource(query);
        }

        res = await interop();
        _triggerDeletes(query, before, res);
        return res;

      case DbOperationType.read:
        return interop();

      case DbOperationType.create:
        Map<String, dynamic> res;
        res = await interop();
        _triggerCreates(query, res);
        return res;

      case DbOperationType.login:
        var res = await interop();
        try {
          if (res["success"]) {
            var user = YazApiUser.fromJson(res["open"]);
            if (_userLoggedIn.isNotEmpty) {
              _triggerUserLoggedIn(user);
            }
          }
          return res;
        } on Exception {
          return res;
        }

      case DbOperationType.register:
        var res = await interop();
        try {
          if (res["success"]) {
            var user = YazApiUser.fromJson(res["user"]);
            if (_userRegister.isNotEmpty) {
              _triggerUserRegister(user);
            }
          }
          return res;
        } on Exception {
          return res;
        }

      case DbOperationType.log:
        return interop();
    }
  }

  void _triggerUserRegister(YazApiUser user) {
    for (var triggers in _userRegister.entries) {
      triggers.value(user);
    }
  }

  void _triggerUserLoggedIn(YazApiUser user) {
    for (var triggers in _userLoggedIn.entries) {
      triggers.value(user);
    }
  }
}

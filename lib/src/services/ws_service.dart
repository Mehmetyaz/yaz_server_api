import 'dart:io';

import '../models/socket_types.dart';

import '../models/web_socket_listener.dart';

///
WebSocketService socketService = WebSocketService();

///
class WebSocketService {
  ///
  factory WebSocketService() => _service;

  ///Singleton Bloğu
  WebSocketService._internal();

  static final WebSocketService _service = WebSocketService._internal();

  ///Waiting Web Socket Connect Request
  List<WebSocketConnectRequest> connectRequests = <WebSocketConnectRequest>[];

  ///Active listener count
  List<WebSocketListener> activeListeners = <WebSocketListener>[];

  ///Get active web socket connection
  int get activeListenerCount {
    return activeListeners.length;
  }

  ///
  Future<void> addListener(WebSocket client) async {
    var listener = WebSocketListener(client);
    await listener.listen();
    if ((await listener
            .connectionRequest()
            .onError((dynamic error, stackTrace) => false) ??
        false)) {
      if (activeListeners.contains(listener)) {
        activeListeners.remove(listener);
        await closeListener(listener);
      }
      activeListeners.add(listener);
    } else {
      await closeListener(listener);
    }
  }

  ///
  Future<void> clear() async {
    var newL = List.from(activeListeners);
    for (var l in newL) {
      await closeListener(l);
    }
  }

  ///
  Future<void> closeListener(WebSocketListener listener) async {
    if (listener.timer != null && listener.timer!.isActive) {

      listener.timer!.cancel();
    } else {

    }

    await listener.client?.close(3500, 'CLOSING');

    listener
      ..timer = null
      ..client = null;
    activeListeners.remove(listener);
  }
}

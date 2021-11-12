import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/socket_types.dart';
import 'encryption.dart';
import 'ws_service.dart';

///
typedef HttpRequestHandler = Future<void> Function(HttpRequest);

///
const Map<String, dynamic> _defaultHeaders = {
  "Access-Control-Allow-Origin": '*',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
};

///
HttpServerService httpServerService = HttpServerService();

///
class HttpServerService {
  ///
  factory HttpServerService() => _instance;

  HttpServerService._internal();

  static final HttpServerService _instance = HttpServerService._internal();

  ///
  final Map<String, HttpRequestHandler> _handlers =
      <String, HttpRequestHandler>{};

  late HttpServer _server;
  // final String _ima = "jpg";

  ///
  Future<void> init(Future<HttpServer> httpServer,
      {Map<String, dynamic> defaultResponseHeaders = _defaultHeaders}) async {
    _server = await httpServer;
    _headers.addAll(defaultResponseHeaders);
    _addHeaders();
    //ignore: unawaited_futures
    _listenServer();
  }

  final Map<String, dynamic> _headers = {};

  ///
  void setResponseHeaders(Map<String, dynamic> headers) {
    _headers.addAll(headers);
    _addHeaders();
  }

  ///
  void use(String name, HttpRequestHandler handler) {
    _handlers[name] = handler;
  }

  ///
  Future<void> _listenServer() async {
    try {
      // ignore: avoid_print
      print("HTTP SERVER LISTENING ON: ${_server.address}:${_server.port}");
      await for (HttpRequest request in _server) {
        //ignore: unawaited_futures
        _handleHttpRequest(request);
      }
    } on Exception catch (e) {
      // ignore: avoid_print
      print("SERVER ERROR: $e");
    }
    // ignore: avoid_print
    print("Server Closed");
  }

  ///
  Future<void> _handleHttpRequest(HttpRequest request) async {
    final wsService = WebSocketService();
    if (request.uri.toString() != "/favicon.ico") {
      if (_handlers.containsKey(request.uri.toString().split("?").first)) {
        await _handlers[request.uri.toString().split("?").first]!(request);
      } else if (request.uri.toString() == '/ws') {
        try {
          var soc = await WebSocketTransformer.upgrade(request);
          await wsService.addListener(soc);
        } on Exception {
          //TODO: ADD ERROR
        }
      } else if (request.uri.toString().split("?").first == "/socket_request") {
        var conReq = WebSocketConnectRequest(
            connectionInfo: request.connectionInfo!, headers: request.headers);

        if (!wsService.connectRequests.contains(conReq)) {
          var res = await encryptionService.encrypt4(conReq.id!);
          request.response.headers.set('Content-Type', 'application/json');
          request.response
              .add(utf8.encode(json.encode({'success': true, 'req_id': res})));
          wsService.connectRequests.add(conReq);
          await request.response.close();
        } else {
          request.response.headers.set('Content-Type', 'application/json');
          request.response.statusCode = 400;
          request.response.add(utf8.encode(json.encode(
              {'success': false, 'reason': 'Device already connected'})));
          await request.response.close();
        }
      } else if (true) {
        //TODO:
      } else {
        await request.response.close();
      }
    }
  }

  void _addHeaders() {
    for (var header in _headers.entries) {
      _server.defaultResponseHeaders.add(header.key, header.value);
    }
  }

  ///
  Uint8List mergeList(List<Uint8List> list) {
    var uint = <int>[];
    for (var _a in list) {
      uint.addAll(_a);
    }
    return Uint8List.fromList(uint);
  }
}

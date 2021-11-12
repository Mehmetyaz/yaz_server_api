



import 'dart:html';

import 'package:yaz_server_api/src/models/web_socket_listener.dart';

/// RequestHandler, handle web socket or http(s) requests
class RequestHandler {

  ///
  factory RequestHandler() => _handler;
  RequestHandler._();
  static final RequestHandler _handler = RequestHandler._();



  Future<void> handle(String name, Map data, {HttpRequest? request, WebSocketListener? socketListener}) async {

  }





}
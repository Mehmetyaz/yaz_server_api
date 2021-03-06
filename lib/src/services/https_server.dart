import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:path/path.dart' as path;

import '../models/socket_types.dart';
import '../models/token/token.dart';
import 'encryption.dart';
import 'media_service.dart';
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
  final String _ima = "jpg";

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
        } on Exception  {
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
          request.response.add(utf8.encode(json.encode(
              {'success': false, 'reason': 'Device already connected'})));
          await request.response.close();
        }
      } else if (request.uri.toString().split("?").first == "/upload") {
        try {
          var q = request.uri.queryParameters;

          // print(q);

          if (q["token"] == null) {
            await request.response.close();
          } else {
            var token = AccessToken.fromToken(q["token"]!.replaceAll(" ", "+"));

            ///
            //ignore: unawaited_futures, cascade_invocations
            token.decryptToken();
            var stream = request.asBroadcastStream();

            var file = MultipartFile.fromBytes(
                "file", mergeList(await stream.toList()));
            var byte = file.finalize();
            var byteData = await byte.toBytes();

            // print("Doc Length :  : : :   :  :  : ${byteData.length}");
            //
            // print("Base64 Doc: ${utf8.decode(byteData.sublist(0, 162))}");

            var str = utf8.decode(byteData);

            // print("DOC: ${utf8.decode(byteData).substring(0, 500)}");

            var imageStr =
                str.replaceAll(RegExp(r'data:image/[^;]+;base64,'), "");
            var strippedStr = imageStr
                .replaceFirst(
                    RegExp(
                        r'--dart-http-boundary[^;]+\r\n[^;]+:[^;]+\r\ncontent-disposition: [^;]+; name=[^;]+\r\n\r\n'),
                    "")
                .replaceFirst(RegExp(r'\r\n--dart-http-boundary[^;]+'), "");
            var mediaServer = MediaService();

            token = await token.decryptToken();

            var id = await (mediaServer.addImage(
                base64.decode(strippedStr), token.uId) as FutureOr<String>);
            request.response.add(utf8.encode(id));
            await request.response.close();
          }
        } on Exception  {
          await request.response.close();
          //TODO: ADD ERROR
        }
      } else if (request.uri.toString().split("?").first == "/upload_video") {
//          var stream = request.asBroadcastStream();
//          int i = 0;
//          stream.listen((event) {
//            print(event.length);
//            i+=event.length;
//          });
//          print(i);
//
//          var file =
//              MultipartFile.
//              fromBytes("file", mergeList(await stream.toList()));
//          var byte = await file.finalize();
//          var byteData = await byte.toBytes();
//
//          print("Doc Length :  : : :   :  :  : ${byteData.length}");
//
//          var str = utf8.decode(byteData);
//
//          var imageStr = str.split(RegExp(r'data:video/[^;]+;base64,'))[1];
//          var strippedStr = imageStr.split("\r\n--dart-http-boundary")[0];
//
//          var mediaServer = MediaService();
//          var id = await mediaServer.addVideo(base64.decode(strippedStr));
//          request.response.add(utf8.encode(id));
        await request.response.close();
      } else if (request.uri.toString().split("?").first == "/get") {
        await _sendImage(request);
      } else {
        await request.response.close();
      }
    }
  }

  ///
  Future<void> _sendImage(HttpRequest request) async {
    var q = Map.from(request.uri.queryParameters);

    if (q["id"] == null) {
      q["id"] = "image";
    }

    q["type"] = _imageTypes[q["type"]];

    var separator = path.separator;

    // print(q);

    var newFile = File('${path.current}$separator'
        'var$separator'
        'images$separator'
        '${q["id"]}$separator'
        '${q["type"]}.$_ima');
    if (newFile.existsSync()) {
      try {
        var raw = newFile.readAsBytesSync();
        request.response.headers.set('Content-Type', 'image/$_ima');
        request.response.headers.set('Content-Length', raw.length);
        request.response.add(raw);
        await request.response.close();
      } on Exception  {
        //TODO: ADD ERROR
        await request.response.close();
      }
    } else {
      var newFile2 = File('${path.current}$separator'
          'var$separator'
          'images$separator'
          'ex$separator'
          '${q["id"]}$separator'
          '${q["type"]}.png');

      if (newFile2.existsSync()) {
        var raw = newFile2.readAsBytesSync();
        request.response.headers.set('Content-Type', 'image/png');
        request.response.headers.set('Content-Length', raw.length);
        request.response.add(raw);
        await request.response.close();
        q["id"] = "image";
      }
    }
  }

  ///
  final Map<String, String> _imageTypes = <String, String>{
    "full": "profile",
    "mid": "mid",
    "thumb": "profile_thumb"
  };

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

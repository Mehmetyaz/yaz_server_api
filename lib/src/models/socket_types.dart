import 'dart:io';

import 'package:meta/meta.dart';

///Socket Connecting Request
@immutable
class WebSocketConnectRequest {
  ///
  WebSocketConnectRequest(
      {required HttpConnectionInfo this.connectionInfo, this.headers})
      : id =
            "${connectionInfo.remotePort}:${connectionInfo.remoteAddress.host}";

  ///Received Only ID
  WebSocketConnectRequest.received(this.id)
      : headers = null,
        connectionInfo = null;

  ///Request ID
  final String? id;

  ///Request Headers
  final HttpHeaders? headers;

  ///Request info
  final HttpConnectionInfo? connectionInfo;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != WebSocketConnectRequest) {
      throw Exception('Type not equal');
    }

    return id == other.id;
  }

  @override
  int get hashCode => super.hashCode;
}

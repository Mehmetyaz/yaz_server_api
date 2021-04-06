library yaz_server_api;

import 'dart:io';

import 'src/services/chat_service.dart';
import 'src/services/database/database_abstract.dart';
import 'src/services/encryption.dart';
import 'src/services/https_server.dart';
import 'src/services/operations.dart';
import 'src/services/permission_handler.dart';
import 'src/services/trigger_service.dart';
import 'src/services/ws_service.dart';

export 'src/extensions/date_time.dart';
export 'src/models/listener.dart';
export 'src/models/query.dart';
export 'src/models/socket_data_model.dart';
export 'src/models/socket_types.dart';
export 'src/models/statics.dart';
export 'src/models/token/token.dart';
export 'src/models/web_socket_listener.dart'
    show sendMessage, sendAndWaitMessage, waitMessage, WebSocketListener;
export 'src/services/encryption.dart';
export 'src/services/mongo_db_service.dart' show mongoDb;
export 'src/services/permission_handler.dart'
    show PermissionHandler, PermissionChecker, Checker, DbOperationType;

///
late YazServerApi server;

///
class YazServerApi {
  ///
  YazServerApi({
    required this.databaseApi,
  }) {
    server = this;
  }

  ///
  final Operation operationService = Operation();

  ///
  final WebSocketService socketService = WebSocketService();

  ///
  final PermissionHandler permissionHandler = PermissionHandler();

  ///
  final EncryptionService encryptionService = EncryptionService();

  ///
  final DatabaseApi databaseApi;

  ///
  final HttpServerService httpServerService = HttpServerService();

  ///
  final TriggerService triggerService = TriggerService();

  ///
  final ChatService chatService = ChatService();

  ///
  void init(
      {required String clientSecretKey1,
      required String clientSecretKey2,
      required String tokenSecretKey1,
      required String tokenSecretKey2,
      required String deviceIdSecretKey,
      required Future<HttpServer> httpServer,
      required Map<String, dynamic> connectionConfiguration,
      bool initDatabase = true,
      Function? initialDb}) {
    server = this;
    encryptionService.init(clientSecretKey1, clientSecretKey2, tokenSecretKey1,
        tokenSecretKey2, deviceIdSecretKey);
    if (initDatabase) {
      databaseApi.init(connectionConfiguration, initial: initialDb);
    }
    httpServerService.init(httpServer);
  }
}

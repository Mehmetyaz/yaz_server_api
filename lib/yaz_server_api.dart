library yaz_server_api;

import 'dart:io';

import 'package:yaz_server_api/src/services/database/database_abstract.dart';

import 'src/services/encryption.dart';
import 'src/services/https_server.dart';
import 'src/services/mongo_db_service.dart';

export 'src/extensions/date_time.dart';
export 'src/models/listener.dart';
export 'src/models/query.dart';
export 'src/models/socket_data_model.dart';
export 'src/models/socket_types.dart';
export 'src/models/statics.dart';
export 'src/models/token/token.dart';
export 'src/models/web_socket_listener.dart';
export 'src/services/chat_service.dart' show chatService;
export 'src/services/encryption.dart';
export 'src/services/https_server.dart';
export 'src/services/media_service.dart';
export 'src/services/mongo_db_service.dart';
export 'src/services/operations.dart';
export 'src/services/permission_handler.dart';
export 'src/services/trigger_service.dart';
export 'src/services/ws_service.dart';

///
class YazServerApi {
  ///
  YazServerApi({
    required this.databaseApi,
  });

  ///
  final EncryptionService encryptionService = EncryptionService();

  ///
  final DatabaseApi databaseApi;

  ///
  final HttpServerService httpServerService = HttpServerService();

  ///
  void init(
      {required String clientSecretKey1,
      required String clientSecretKey2,
      required String tokenSecretKey1,
      required String tokenSecretKey2,
      required String deviceIdSecretKey,
      required Future<HttpServer> server,
      required String mongoDbAddress,
      Function? initialDb}) {
    encryptionService.init(clientSecretKey1, clientSecretKey2, tokenSecretKey1,
        tokenSecretKey2, deviceIdSecretKey);
    databaseApi.init({"address": mongoDbAddress}, initial: initialDb);
    httpServerService.init(server);
  }
}

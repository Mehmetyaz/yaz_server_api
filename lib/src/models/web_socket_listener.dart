import 'dart:async';
import 'dart:convert';
import 'dart:io';


import '../services/chat_service.dart';
import '../services/encryption.dart';
import '../services/mongo_db_service.dart';
import '../services/operations.dart';
import '../services/ws_service.dart';
import 'query.dart';
import 'socket_data_model.dart';
import 'socket_types.dart';
import 'statics.dart';
import 'token/token.dart';

///Message waiting exception
class TimeoutOnWaitingMessageException implements Exception {
  ///
  const TimeoutOnWaitingMessageException();

  @override
  String toString() => 'Message is not received';
}

///Wait Message from stream web socket
/// [id] or [type] must defined
Future<SocketData> waitMessage(Stream stream,
    {String id, String type, Function onTimeout}) async {
  try {
    // print(' $id $type');
    assert(id != null || type != null, "[id] or [type] must defined");

    var completer = Completer.sync();
    var _subscription =
    stream.timeout(const Duration(seconds: 30), onTimeout: (sink) {
      if (onTimeout != null) {
        onTimeout();
      }

      sink.close();
      completer.complete(null);
    }).where((event) {
      // print("SOCKET EVENT ON WAIT MESSAGE: $event");

      try {
        var _d = SocketData.fromSocket(event);
        if (type != null && id != null) {
          return _d.type == type && _d.messageId == id;
        } else if (type == null && id != null) {
          return _d.messageId == id;
        } else if (id == null && type != null) {
          return _d.type == type;
        } else {
          return true;
        }
      } on Exception {
        //TODO:ADD ERROR ON ANALYSIS
        completer.complete(null);
        return false;
      }
    }).listen((event) {
      // print("SOCKET LISTEN : $event");
      completer.complete(event);
    });

    var completed = await completer.future;
    // print(completed);
    await _subscription.cancel();
    if (completed != null) {
      // print('IS NOT EMPTY : $completed');
      return SocketData.fromSocket(completed);
    } else {
      // print('IS EMPTY');
      return SocketData.fromFullData({
        "reason": "Message Not Found In Expected Time",
        "message_type": type,
        "success": false,
        "data": {}
      });
    }
  } on Exception catch (e) {
    return SocketData.fromFullData({
      "reason": "Message Not Found : $e",
      "message_type": type,
      "success": false,
      "data": {}
    });
  }
}

///Send Message with defined web socket
void sendMessage(WebSocket webSocket, SocketData socketData,
    {Function onError}) {
  try {
    if (webSocket != null && webSocket.closeCode == null) {
      // print("SEND MESSAGE IN : ${socketData.fullData}");
      webSocket.addUtf8Text(utf8.encode(json.encode(socketData.toJson())));
    } else {
      if (onError != null) onError();
      // print("SEND AND WAIT MESSAGE IN CLOSED: ${socketData.fullData}");
    }
  } on Exception {
    if (onError != null) onError();
    //TODO:ADD ERROR ANALYSIS
  }
}

///Send and wait message with defined web socket
Future<SocketData> sendAndWaitMessage(WebSocketListener socketListener,
    SocketData socketData,
    {String waitingID,
      String waitingType,
      bool anyID = false,
      bool anyType = false,
      Function onError,
      Function onTimeout}) async {
  try {
    // print("SEND AND WAIT MESSAGE IN : ${socketData.fullData}");
    sendMessage(socketListener.client, socketData, onError: onError);
  } on Exception {
    //TODO: ADD ERROR
    return null;
  }
  return waitMessage(
    socketListener.socketBroadcast,
    id: waitingID != null
        ? waitingID
        : anyID
        ? null
        : socketData.messageId,
    type: waitingType != null
        ? waitingType
        : anyType
        ? null
        : socketData.type,
  );
}

///Web Socket Listener
class WebSocketListener {
  ///Construct with Client
  WebSocketListener(this.client) {
    streamController.sink.addStream(client).whenComplete(() {
      streamController.close();
      //
      // print("controller closed");
    });
    // timer = Timer.periodic(const Duration(seconds: 120000), (timer) {
    //   checkConnection();
    // });
    lastOnline = DateTime
        .now()
        .millisecondsSinceEpoch;
  }

  @override
  String toString() {
    return "User $userId on device: $deviceID";
  }

  ///
  bool isLogged = false;

  ///
  String userId;

  ///Check connection online
  void checkConnection() {
    try {
      sendAndWaitMessage(
          this,
          SocketData.fromFullData({
            'message_id': Statics.getRandomId(20),
            'message_type': 'connection_confirmation',
            "data": {}
          }))
          .then((value) => null)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        close();
      });
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      close();
    }
  }

  ///Socket Client
  WebSocket client;

  ///Soketlerin dinleyicisi
  ///her soket için ayrı ayrı oluşturuluyor

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other.runtimeType != WebSocketListener) {
      throw Exception(
          "WebSocketListener not have equals operator with : ${other
              .runtimeType}");
    } else {
      WebSocketListener socketListener = other;
      return deviceID == socketListener.deviceID;
    }
  }

  ///Operation Class
  /// All operations (exclude [connectionRequest]) process in this class.
  Operation operation = Operation();

  ///Global web socket service
  WebSocketService service = WebSocketService();

  ///Connected device id
  String deviceID;

  ///Stream Controller
  StreamController streamController = StreamController.broadcast();

  ///Web Socket data broadcast
  Stream get socketBroadcast => streamController.stream;

  /// Unsuccess Permission Request
  int unSuccessPermissionRequestCount = 0;

  ///Server side nonce for this session
  Nonce nonce;

  ///Client side nonce for this session
  Nonce cnonce;

  ///Close this connection
  Future<void> close() async {
    if (isLogged) {
      chatService.removeOnline(userId, this);
    }
    await subscription.cancel();
    await streamController.close();
    await service.closeListener(this);
  }

  ///Check this client
  Future<bool> connectionRequest() async {
    ///Client tarafına benzer şekilde(aynı şekilde )
    ///4 aşamalı bağlantı protokolü var
    try {
      // print("CONNECTION  STARTED");

      ///
      ///                       type
      ///                       -----
      ///                        id
      ///
      ///
      ///   Server Side                            Client Side
      ///   Server Side                            Client Side
      ///
      ///
      ///   deviceID       request_connection
      ///       |      <-----------------------     deviceID
      ///       |               requestID
      ///       |
      ///       |
      ///       |
      ///       |           nonce_sending
      ///  serverNonce  ------------------------>  serverNonce
      ///                     requestID                 |
      ///                                               |
      ///                                               |
      ///                                               |
      ///                                               |
      ///   auth_data      c_nonce_sending            auth_data
      ///  clientNonce  <--------------------------  clientNonce
      ///       |              secondID
      ///       |
      ///       |
      ///       |
      ///       |
      ///       |           token_sending                 ✅
      ///  auth_token   --------------------------->  auth token
      ///                     secondID                    ✅
      ///
      ///

      ///Received connection request
      ///{
      /// id: string,
      /// type : 'request_connection',
      /// device_id : string
      ///}
      var stage1Data =
      await waitMessage(socketBroadcast, type: 'request_connection');

      if (stage1Data == null ||
          stage1Data.fullData == null ||
          stage1Data.type == null ||
          stage1Data.messageId == null) {
        throw Exception('Message is null');
      }
      // print('CONNECTION REQUESTED DATA : ${stage1Data.runtimeType}');

      ///unique id for each request
      var requestID = stage1Data.messageId;

      if (stage1Data.fullData['device_id'] == null) return null;

      ///unique device id
      deviceID =
      await encryptionService.decrypt4(
          (stage1Data.fullData['device_id']) ?? "");

      // print("DEVICE ID REVEIVED ::: $deviceID");

      var req = WebSocketConnectRequest.received(deviceID);

      if (service.connectRequests.contains(req)) {
        service.connectRequests.remove(req);
      }

      ///log device id and request id
      var db = MongoDb();
      await db.logConnection({
        'id': requestID,
        'deviceID': deviceID,
        'timestamp': DateTime
            .now()
            .millisecondsSinceEpoch,
      });

      ///generate server side nonce
      nonce = Nonce.random();

      /// Sending "nonce_sending" and waiting "c_nonce_sending"
      /// ----------------------------------------
      /// !!!! These messages are different id !!!!
      /// ------------------------------------------
      /// send stage 2 data
      /// {
      ///   id : requestID
      ///   nonce : server side nonce Uint8List
      ///   type : 'nonce_sending'
      /// }
      /// wait stage 3 data
      /// {
      ///  id : secondID
      ///  c_nonce: client side nonce Uint8List
      ///  type : 'c_nonce_sending'
      ///  data : encrypted auth data
      /// }
      ///
      ///
      var stage3Data = await sendAndWaitMessage(
          this,
          SocketData.fromFullData({
            'message_id': requestID,
            'nonce': nonce.list,
            'message_type': 'nonce_sending',
            'success': true,
            'data': {}
          }),
          waitingType: 'c_nonce_sending',
          anyID: true);
      // print('STAGE 3 : $stage3Data');
      if (stage3Data == null ||
          stage3Data.fullData == null ||
          stage3Data.type == null ||
          stage3Data.messageId == null) {
        throw Exception('Message is null');
      }
      var secondID = stage3Data.fullData['message_id'];

      if (!stage3Data.success) return false;

      ///client nonce
      cnonce = Statics.nonceCast(stage3Data.fullData['c_nonce']);

      ///decrypt stage3 data
      await stage3Data.decrypt(nonce, cnonce);
      // print(stage3Data.data);
      if (stage3Data.data['auth_type'] == null) {
        return false;
      } else if (stage3Data.data['auth_type'] == 'auth') {
        var userData = await db.confirmUser(stage3Data.data, deviceID);
        if (userData != null && userData['success']) {
          // print("USER CONFIRMED : $userData");

          ///User Confirmed
          var token = await AccessToken
              .generateForUser(
              authType: AuthType.loggedIn,
              deviceID: deviceID,
              mail: userData['open']['user_mail'],
              passWord: stage3Data.data['password'],
              uId: userData['open']['user_id'])
              .encryptedToken;

          isLogged = true;
          userId = userData['open']['user_id'];
          chatService.addOnline(userId, this);
          var sending = SocketData.fromFullData({
            'message_id': secondID,
            'message_type': 'token_sending',
            'success': true,
            'data': {
              'token': token,
              'timestamp': DateTime
                  .now()
                  .millisecondsSinceEpoch,
              'timeout': 30,
              'auth_type': 'auth',
              'user_data': userData['open']
            }
          });

          // print(
          //"ACCESS::: ${await AccessToken.fromToken(token).decryptToken()}");

          // print("SENDING DATA STAGE 4 : ${sending.fullData}");

          await sending.encrypt(nonce, cnonce);

          ///Send token
          sendMessage(client, sending);
          return true;
        } else {
          // print("USER NOT CONFIRMED");

          ///User Confirmed
          var token =
          await AccessToken
              .generateForGuess(AuthType.guess, deviceID)
              .encryptedToken;

          sendMessage(
              client,
              SocketData.fromFullData({
                'message_id': secondID,
                'message_type': 'token_sending',
                'success': true,
                'data': {
                  'token': token,
                  'timestamp': DateTime
                      .now()
                      .millisecondsSinceEpoch,
                  'timeout': 30,
                  'auth_type': 'guess'
                }
              }));
          return true;
        }

        /// if auth type admin
      } else if (stage3Data.data['auth_type'] == '_admin') {
        var isAdmin = (await db.exists(Query.allowAll(
          queryType: QueryType.exists,
          equals: {"mail": stage3Data.data["user_mail"]},
        )))["exists"];

        if (!isAdmin) {
          var userData = await db.confirmUser(stage3Data.data, deviceID);
          if (userData != null && userData['success']) {
            // print("USER CONFIRMED : $userData");

            ///User Confirmed
            var token = await AccessToken
                .generateForUser(
                authType: AuthType.admin,
                deviceID: deviceID,
                mail: userData['open']['user_mail'],
                passWord: stage3Data.data['password'],
                uId: userData['open']['user_id'])
                .encryptedToken;

            isLogged = true;
            userId = userData['open']['user_id'];
            chatService.addOnline(userId, this);
            var sending = SocketData.fromFullData({
              'message_id': secondID,
              'message_type': 'token_sending',
              'success': true,
              'data': {
                'token': token,
                'timestamp': DateTime
                    .now()
                    .millisecondsSinceEpoch,
                'timeout': 30,
                'auth_type': 'admin',
                'user_data': userData['open']
              }
            });

            // print(
            //"ACCESS::: ${await AccessToken.fromToken(token).decryptToken()}");

            // print("SENDING DATA STAGE 4 : ${sending.fullData}");

            await sending.encrypt(nonce, cnonce);

            ///Send token
            sendMessage(client, sending);
            return true;
          } else {
            // print("USER NOT CONFIRMED");

            ///User Confirmed
            var token =
            await AccessToken
                .generateForGuess(AuthType.guess, deviceID)
                .encryptedToken;

            sendMessage(
                client,
                SocketData.fromFullData({
                  'message_id': secondID,
                  'message_type': 'token_sending',
                  'success': true,
                  'data': {
                    'token': token,
                    'timestamp': DateTime
                        .now()
                        .millisecondsSinceEpoch,
                    'timeout': 30,
                    'auth_type': 'guess'
                  }
                }));
            return true;
          }
        } else {
          throw Exception("Not Admin");
        }
      } else {
        stage3Data.data['timestamp'] = DateTime
            .now()
            .millisecondsSinceEpoch;

        var token = await AccessToken
            .generateForGuess(AuthType.guess, deviceID)
            .encryptedToken;

        ///Send token
        sendMessage(
            client,
            await SocketData.fromFullData({
              'message_id': secondID,
              'message_type': 'token_sending',
              'success': true,
              'data': {
                'token': token,
                'timestamp': DateTime
                    .now()
                    .millisecondsSinceEpoch,
                'timeout': 30,
                'auth_type': 'guess'
              }
            }).encrypt(nonce, cnonce));
        return true;
      }
    } on Exception {
      //TODO:ADD ERROR
      return false;
    }
  }

  ///
  StreamSubscription subscription;

  ///Listen this connection
  Future<void> listen() async {
    /**
     * Socket listener for each identified device
     */
    subscription = socketBroadcast.listen(
            (event) async {
          ///data oluşturuluyor

          try {
            lastOnline = DateTime
                .now()
                .millisecondsSinceEpoch;
            if (event.runtimeType != String) {
              // print(utf8.decode(event));
            }
            var data = SocketData.fromSocket(event);

            if (data.type == 'error') {
              sendMessage(client, data);
            } else if (data.type == 'close') {
              // print("CLOSE CLOSE CLOSE");
              await close();
            } else if (data.type == 'connection_confirmation') {
              // print("connection_confirmation");
            } else {
              if (data.isEncrypted) {
                try {
                  if (cnonce != null && nonce != null) {
                    await data.decrypt(nonce, cnonce);
                  }

                  await operation.operate(this, data);
                } on Exception {
                  // TODO:ADD ERROR
                }
              } else {
                // print('DATA NULLLL : ${data.data}');
              }
            }
          } on Exception {
            // TODO:ADD ERROR
          }
        },
        onError: (e) async {
          // print(e);
          await close();
        },
        cancelOnError: true,
        onDone: () {
          close();

          ///closed
          ///service.closeListener(this);
        });
  }

  ///Check Timer
  Timer timer;

  /// Last online time millis epoch
  int lastOnline;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => super.hashCode;
}

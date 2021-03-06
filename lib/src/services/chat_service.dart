import '../../yaz_server_api.dart';

// ignore_for_file: constant_identifier_names , public_member_api_docs
const String MESSAGE_TIME = "message_time";
const String RECEIVE_TIME = "receive_time";
const String CONVERSATION_ID = "conversation_id";
const String SEEN_TIME = "seen_time";
const String MESSAGE_SEEN_BY_OTHER = "message_seen_by_other";
const String MESSAGE_SEEN_BY_OWN = "message_seen_by_own";
const String NEW_MESSAGE_FROM_OTHER = "new_message_from_other";
const String NEW_MESSAGE_FROM_OWN = "new_message_from_own";
const String CHAT_COLLECTIONS = "*conversations";
const String LAST_ACTIVITY = "last_activity";
const String MESSAGE_COLLECTION = "*messages";
const String START_CHAT_OPERATION = "start_chat";
const String RECEIVE_CONFIRM = "receive_confirm";
const String SEND_MESSAGE_OPERATION = "send_message";
const String SET_SEEN_DATA = "set_seen";
const String GET_CONVERSATIONS = "get_conversations";

///
ChatService chatService = ChatService();

///
class ChatService {
  ///
  factory ChatService() => _instance;

  ///
  ChatService._internal();

  ///
  static final ChatService _instance = ChatService._internal();

  final Map<String, Map<String, WebSocketListener>> _onlineUsers =
      <String, Map<String, WebSocketListener>>{};

  Map<String, int> get onlineUsers => _onlineUsers.map((key, value) => MapEntry(key, value.length));

  ///
  void init() {
    socketOperations
      ..addCustomOperation(SEND_MESSAGE_OPERATION, onRequestNewMessage)
      ..addCustomOperation(START_CHAT_OPERATION, onRequestNewConversation)
      // ..addCustomOperation(GET_CONVERSATIONS, onRequestConversation)
      ..addCustomOperation("remove_stream_chat", onRequestRemoveStream)
      ..addCustomOperation("start_stream_chat", onRequestStartStream)
      ..addCustomOperation(SET_SEEN_DATA, onSeenChat);
  }

  ///
  Future<void> onSeenChat(
      WebSocketListener listener, SocketData socketData) async {
    var chatId = socketData.data[CONVERSATION_ID] as String;
    var token = AccessToken.fromToken(socketData.data["token"]);
    var decryptToken = await token.decryptToken();

    var isStarter = socketData.data["starter_id"] == decryptToken.uId;
    var isReceiver = socketData.data["receiver_id"] == decryptToken.uId;

    if (!(isStarter || isReceiver)) return null;

    // await mongoDb.update(
    //   Query.allowAll(queryType: QueryType.update, equals: {
    //     "chat_id": chatId
    //   }, update: {
    //     "\$set": {
    //       "last_activity": time,
    //     }
    //   })
    //     ..collection = CHAT_COLLECTIONS,
    // );

    var chatDoc = socketData.data;

    var ownID = isStarter ? chatDoc["starter_id"] : chatDoc["receiver_id"];
    var otherId = !isStarter ? chatDoc["starter_id"] : chatDoc["receiver_id"];
    var isOnline =
        _onlineUsers[otherId] != null && _onlineUsers[otherId].isNotEmpty;

    var isOnlineOwn =
        _onlineUsers[ownID] != null && _onlineUsers[ownID].isNotEmpty;



    await mongoDb.update(
        Query.allowAll(queryType: QueryType.update, limit: 10000, equals: {
      CONVERSATION_ID: chatId,
      "receiver_id": ownID
    }, update: {
      "\$set": {
        "receiver_seen": true,
        "seen_time": DateTime.now().millisecondsSinceEpoch
      }
    })
          ..collection = MESSAGE_COLLECTION);

    //TODO: UPDATE MESSAGES
    socketData.data.remove("token");
    if (isOnlineOwn) {
      var l = Map.from(_onlineUsers[ownID])..remove(listener.deviceID);
      for (var _listener in l.entries) {
        sendSeenToOnline(_listener.value, true, socketData.data);
      }
    }

    if (isOnline) {
      var l = _onlineUsers[otherId];
      for (var _listener in l.entries) {
        sendSeenToOnline(_listener.value, false, socketData.data);
      }
    }
    // else {
    //   // _addUserChatDoc(chatDoc, isStarter);
    // }

    sendMessage(listener.client, socketData.response({})..success = true);
  }

  ///
  Future<void> onRequestStartStream(
      WebSocketListener listener, SocketData socketData) async {
    await sendAndWaitMessage(
        listener, SocketData.create(data: {}, type: "stream_chat"));
    addOnline(listener.userId, listener);
  }

  ///
  void removeOnline(String userId, WebSocketListener listener) {

    if (_onlineUsers[userId] != null && _onlineUsers[userId].isNotEmpty) {
      _onlineUsers[userId].remove(listener);
    }
  }

  ///
  void addOnline(String userId, WebSocketListener listener) {
    _onlineUsers[userId] ??= <String, WebSocketListener>{};
    _onlineUsers[userId][listener.deviceID] = listener;
  }

  ///
  Future<void> onRequestRemoveStream(
      WebSocketListener listener, SocketData socketData) async {
    removeOnline(listener.userId, listener);
  }

  ///
  Future<void> onRequestNewMessage(
      WebSocketListener listener, SocketData socketData) async {
    var chatId = socketData.data["message"][CONVERSATION_ID] as String;
    var token = AccessToken.fromToken(socketData.data["token"]);
    var decryptToken = await token.decryptToken();

    // var chatDoc = await mongoDb.query(
    //   Query.allowAll(queryType: QueryType.query, equals: {"chat_id": chatId})
    //     ..collection = CHAT_COLLECTIONS,
    // );

    // var isStarter = chatDoc["starter_id"] == decryptToken.uId;
    // var isReceiver = chatDoc["receiver_id"] == decryptToken.uId;
    //
    // if (!(isStarter || isReceiver)) return null;
    var time = socketData.data["message"][MESSAGE_TIME] as int;
    // chatDoc[LAST_ACTIVITY] = time;
    await mongoDb.update(
      Query.allowAll(queryType: QueryType.update, equals: {
        CONVERSATION_ID: chatId
      }, update: {
        "\$set": {
          LAST_ACTIVITY: time,
        },
        "\$inc": {"total_message_count": 1}
      })
        ..collection = CHAT_COLLECTIONS,
    );

    // chatDoc["init_messages"] = [socketData.data["message"]];
    await mongoDb.insertQuery(Query.allowAll(
      queryType: QueryType.insert,
    )
      ..collection = MESSAGE_COLLECTION
      ..data = socketData.data["message"]);
    var chatDoc = await mongoDb.query(
      Query.allowAll(
          queryType: QueryType.query, equals: {CONVERSATION_ID: chatId})
        ..collection = CHAT_COLLECTIONS,
    );

    var isStarter = chatDoc["starter_id"] == decryptToken.uId;

    var ownID = isStarter ? chatDoc["starter_id"] : chatDoc["receiver_id"];
    var otherId = !isStarter ? chatDoc["starter_id"] : chatDoc["receiver_id"];






    var isOnline =
        _onlineUsers[otherId] != null && _onlineUsers[otherId].isNotEmpty;

    var isOnlineOwn =
        _onlineUsers[ownID] != null && _onlineUsers[ownID].isNotEmpty;





    if (isOnlineOwn) {
      var l = Map.from(_onlineUsers[ownID])..remove(listener.deviceID);
      for (var _listener in l.entries) {
        sendMessageToOnline(_listener.value, true, {
          CONVERSATION_ID: chatDoc[CONVERSATION_ID],
          "message": socketData.data["message"],
          "conversation_data": chatDoc
        });
      }
    }

    if (isOnline) {
      var l = _onlineUsers[otherId];
      for (var _listener in l.entries) {
        sendMessageToOnline(_listener.value, false, {
          "message": socketData.data["message"],
          "conversation_data": chatDoc
        });
      }
    }

    sendMessage(listener.client, socketData.response({})..success = true);
  }

  ///
  // ignore: avoid_positional_boolean_parameters
  void sendSeenToOnline(
      // ignore: avoid_positional_boolean_parameters
      WebSocketListener _listener, bool own, Map<String, dynamic> chatDoc) {
    sendAndWaitMessage(
        _listener,
        SocketData.create(
            data: chatDoc
              ..["type"] = own ? MESSAGE_SEEN_BY_OWN : MESSAGE_SEEN_BY_OTHER,
            type: "stream_chat"),
        waitingType: "stream_chat_received",
        anyID: true, onError: () {
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    }, onTimeout: () {
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    });
  }

  ///
  // ignore: avoid_positional_boolean_parameters
  void sendMessageToOnline(
      // ignore: avoid_positional_boolean_parameters
      WebSocketListener _listener, bool own, Map<String, dynamic> chatDoc) {
    sendAndWaitMessage(
        _listener,
        SocketData.create(
            data: chatDoc
              ..["type"] = own ? NEW_MESSAGE_FROM_OWN : NEW_MESSAGE_FROM_OTHER,
            type: "stream_chat"),
        waitingType: "stream_chat_received",
        anyID: true, onError: () {
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    }, onTimeout: () {
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    });
  }

  // void _addUserChatDoc(Map<String, dynamic> chatDoc, bool isStarter) {
  //   mongoDb.update(
  //     Query.allowAll(queryType: QueryType.update, equals: {
  //       "user_id": isStarter ? chatDoc["receiver_id"] : chatDoc["starter_id"],
  //     }, update: {
  //       "\$push": {"new_messages": chatDoc}
  //     })
  //       ..collection = "user_chat_documents",
  //   );
  // }

  ///
  Future<void> onRequestNewConversation(
      WebSocketListener listener, SocketData socketData) async {
    try {
      var token = AccessToken.fromToken(socketData.data["token"]);
      var receiver = socketData.data["receiver"] as String;
      var chatId = socketData.data[CONVERSATION_ID] as String;

      var decryptToken = await token.decryptToken();

      var doc = await mongoDb.insertQuery(Query.allowAll(
        queryType: QueryType.insert,
      )
        ..collection = CHAT_COLLECTIONS
        ..data = {
          CONVERSATION_ID: chatId,
          "receiver_id": receiver,
          LAST_ACTIVITY: DateTime.now().millisecondsSinceEpoch,
          "starter_id": decryptToken.uId,
          "total_message_count": 0
        });

      sendMessage(listener.client,
          socketData.response({"document": doc["ops"][0]})..success = true);
    } on Exception {
      //TODO: ADD ERROR
    }
  }

  ///
// Future<void> onRequestConversation(
//     WebSocketListener listener, SocketData socketData) async {
//   try {
//     var token = AccessToken.fromToken(socketData.data["token"]);
//     var last = socketData.data[LAST_ACTIVITY];
//     var decryptToken = await token.decryptToken();
//
//     var chats = (await mongoDb
//         .listQuery(Query.allowAll(queryType: QueryType.listQuery, filters: {
//       "gte": {LAST_ACTIVITY: last}
//     }, equals: {
//       "starter_id": decryptToken.uId,
//       "receiver_id": decryptToken.uId
//     })
//           ..collection = CHAT_COLLECTIONS))["list"] as List;
//
//     var chatList = chats.map((e) => e["chat_id"]);
//
//     var messages = (await mongoDb
//         .listQuery(Query.allowAll(queryType: QueryType.listQuery, filters: {
//       "gte": {LAST_ACTIVITY: last}
//     }, equals: {
//       "chat_id": chatList,
//     })
//           ..collection = MESSAGE_COLLECTION))["list"] as List;
//
//     var res = {};
//
//     for (var m in messages) {
//       var chatID = m["chat_id"];
//       res[chatID] ??= [];
//       res[chatID].add(m);
//     }
//
//     var resList = chats.map((e) {
//       if (res[e["chat_id"]] != null) {
//         e["init_messages"] = res[e["chat_id"]];
//       }
//       return e;
//     }).toList();
//
//     sendMessage(listener.client,
//         socketData.response({"list": resList})..success = true);
//   } on Exception {
//     //TODO: ADD ERROR
//   }
// }
}

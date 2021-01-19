import '../../yaz_server_api.dart';

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

  final Map<String, Map<String , WebSocketListener>> _onlineUsers =
  <String, Map<String , WebSocketListener>>{};

  ///
  void init() {
    socketOperations
      ..addCustomOperation("send_message", onRequestNewMessage)
      ..addCustomOperation("start_chat", onRequestNewConversation)
      ..addCustomOperation("get_conversations", onRequestConversation)
      ..addCustomOperation("remove_stream_chat", onRequestRemoveStream)
      ..addCustomOperation("start_stream_chat", onRequestStartStream)
      ..addCustomOperation("set_seen", onSeenChat);
  }

  ///
  Future<void> onSeenChat(
      WebSocketListener listener, SocketData socketData) async {
    var chatId = socketData.data["chat_id"] as String;
    var token = AccessToken.fromToken(socketData.data["token"]);
    var decryptToken = await token.decryptToken();

    var chatDoc = await mongoDb.query(
      Query.allowAll(queryType: QueryType.query, equals: {"chat_id": chatId})
        ..collection = "conversations",
    );

    var isStarter = chatDoc["starter_id"] == decryptToken.uId;
    var isReceiver = chatDoc["receiver_id"] == decryptToken.uId;

    if (!(isStarter || isReceiver)) return null;
    var time = DateTime.now().millisecondsSinceEpoch;

    chatDoc["last_activity"] = time;
    if (isReceiver) {
      chatDoc["last_activity_seen_receiver"] = time;
    } else {
      chatDoc["last_activity_seen_sender"] = time;
    }
    await mongoDb.update(
      Query.allowAll(queryType: QueryType.update, equals: {
        "chat_id": chatId
      }, update: {
        "\$set": {
          "last_activity": DateTime.now().millisecondsSinceEpoch,
          "last_activity_seen_sender": chatDoc["last_activity_seen_sender"],
          "last_activity_seen_receiver": chatDoc["last_activity_seen_receiver"]
        }
      })
        ..collection = "conversations",
    );

    var isOnline = isStarter
        ? _onlineUsers[chatDoc["receiver_id"]] != null &&
            _onlineUsers[chatDoc["receiver_id"]].isNotEmpty
        : _onlineUsers[chatDoc["starter_id"]] != null &&
            _onlineUsers[chatDoc["starter_id"]].isNotEmpty;

    if (isOnline) {
      var l = isStarter
          ? _onlineUsers[chatDoc["receiver_id"]]
          : _onlineUsers[chatDoc["starter_id"]];
      for (var _listener in l.entries) {
        sendSeenToOnline(_listener.value, isStarter, chatDoc);
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
        listener,
        SocketData.create(
            data: await mongoDb.query(Query.allowAll(
                queryType: QueryType.query,
                equals: {"user_id": listener.userId})
              ..collection = "user_chat_documents"),
            type: "stream_chat"));
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
    var chatId = socketData.data["message"]["chat_id"] as String;
    var token = AccessToken.fromToken(socketData.data["token"]);
    var decryptToken = await token.decryptToken();

    var chatDoc = await mongoDb.query(
      Query.allowAll(queryType: QueryType.query, equals: {"chat_id": chatId})
        ..collection = "conversations",
    );

    var isStarter = chatDoc["starter_id"] == decryptToken.uId;
    var isReceiver = chatDoc["receiver_id"] == decryptToken.uId;

    if (!(isStarter || isReceiver)) return null;
    var time = DateTime.now().millisecondsSinceEpoch;

    chatDoc["last_activity"] = time;
    if (isReceiver) {
      chatDoc["last_activity_seen_receiver"] = time;
    } else {
      chatDoc["last_activity_seen_sender"] = time;
    }
    await mongoDb.update(
      Query.allowAll(queryType: QueryType.update, equals: {
        "chat_id": chatId
      }, update: {
        "\$set": {
          "last_activity": DateTime.now().millisecondsSinceEpoch,
          "last_activity_seen_sender": chatDoc["last_activity_seen_sender"],
          "last_activity_seen_receiver": chatDoc["last_activity_seen_receiver"]
        },
        "\$inc": {"total_message_count": 1}
      })
        ..collection = "conversations",
    );

    chatDoc["init_messages"] = [socketData.data["message"]];
    await mongoDb.insertQuery(Query.allowAll(
      queryType: QueryType.insert,
    )
      ..collection = "messages"
      ..data = socketData.data["message"]);

    var isOnline = isStarter
        ? _onlineUsers[chatDoc["receiver_id"]] != null  &&
            _onlineUsers[chatDoc["receiver_id"]].isNotEmpty
        : _onlineUsers[chatDoc["starter_id"]] != null &&
            _onlineUsers[chatDoc["starter_id"]].isNotEmpty;

    if (isOnline) {
      var l = isStarter
          ? _onlineUsers[chatDoc["receiver_id"]]
          : _onlineUsers[chatDoc["starter_id"]];

      print("message sent to : ${l.entries.map((e) => e.key)}");

      for (var _listener in l.entries) {
        sendMessageToOnline(_listener.value, isStarter, socketData.data["message"]);
      }
    }

    sendMessage(listener.client, socketData.response({})..success = true);
  }

  ///
  void sendSeenToOnline(WebSocketListener _listener, bool isStarter,
      Map<String, dynamic> chatDoc) {
    sendAndWaitMessage(
        _listener, SocketData.create(data: chatDoc..["type"] = "message_seen", type: "stream_chat"),
        waitingType: "stream_chat_received", anyID: true, onError: () {
      print("ONERROR");
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    }, onTimeout: () {
      print("ONERROR1");
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    });
  }

  ///
  // ignore: avoid_positional_boolean_parameters
  void sendMessageToOnline(WebSocketListener _listener, bool isStarter,
      Map<String, dynamic> chatDoc) {
    sendAndWaitMessage(
        _listener,
        SocketData.create(
            data: chatDoc..["type"] = "new_message", type: "stream_chat"),
        waitingType: "stream_chat_received",
        anyID: true, onError: () {
      print("ONERROR");
      removeOnline(_listener.userId, _listener);
      // _addUserChatDoc(chatDoc, isStarter);
    }, onTimeout: () {
      print("ONERROR1");
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
      var chatId = socketData.data["chat_id"] as String;

      var decryptToken = await token.decryptToken();

      var doc = await mongoDb.insertQuery(Query.allowAll(
        queryType: QueryType.insert,
      )
        ..collection = "conversations"
        ..data = {
          "chat_id": chatId,
          "receiver_id": receiver,
          "last_activity": DateTime.now().millisecondsSinceEpoch,
          "starter_id": decryptToken.uId
        });

      sendMessage(listener.client,
          socketData.response({"document": doc})..success = true);
    } on Exception catch (e) {}
  }

  ///
  Future<void> onRequestConversation(
      WebSocketListener listener, SocketData socketData) async {
    try {
      var token = AccessToken.fromToken(socketData.data["token"]);
      var last = socketData.data["last_activity"];
      var decryptToken = await token.decryptToken();

      var chats = (await mongoDb
          .listQuery(Query.allowAll(queryType: QueryType.listQuery, filters: {
        "gt": {"last_activity": last}
      }, equals: {
        "starter_id": decryptToken.uId,
        "receiver_id": decryptToken.uId
      })
            ..collection = "conversations"))["list"] as List;

      var chatList = chats.map((e) => e["chat_id"]);

      var messages = (await mongoDb
          .listQuery(Query.allowAll(queryType: QueryType.listQuery, filters: {
        "gt": {"last_activity": last}
      }, equals: {
        "chat_id": chatList,
      })
            ..collection = "messages"))["list"] as List;

      var res = {};

      for (var m in messages) {
        var chatID = m["chat_id"];
        res[chatID] ??= [];
        res[chatID].add(m);
      }

      var resList = chats.map((e) {
        if (res[e["chat_id"]] != null) {
          e["init_messages"] = res[e["chat_id"]];
        }
        return e;
      }).toList();

      sendMessage(listener.client,
          socketData.response({"list": resList})..success = true);
    } on Exception catch (e) {}
  }
}

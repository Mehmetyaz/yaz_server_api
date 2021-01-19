
import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../extensions/date_time.dart';
import 'web_socket_listener.dart';


///

///
@immutable
class DbListener {
  ///
  DbListener(
      {@required this.messageId,
      @required this.collection,
      @required this.id,
      @required this.listener})
      : createDate = DateTime.now();

  ///
  final String messageId;

  ///
  final WebSocketListener listener;

  ///
  final ObjectId id;

  ///
  final String collection;

  ///
  final DateTime createDate;

  ///
  static final int _outDateMinute = 15;

  ///
  bool get isOutDate {
    var dif = DateTime.now() - createDate;
    return dif.inMinutes != null && dif.inMinutes >= _outDateMinute;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != DbListener) {
      return false;
    }
    return other is DbListener && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

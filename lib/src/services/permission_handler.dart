

import '../models/query.dart';
import 'mongo_db_service.dart';

///Mongo Db Operation Type
enum MongoDbOperationType {
  ///Update Document
  update,

  ///Delete Document
  delete,

  ///Read Document
  read,

  ///Create Document
  create
}

///PermissionChecker
typedef PermissionChecker = Map<String, Map<MongoDbOperationType, Checker>>
    Function(Query query);

Map<String, Map<MongoDbOperationType, Checker>> _defaultPermissionChecker(
    Query query) {
  return <String, Map<MongoDbOperationType, Checker>>{};
}

///
typedef Checker = Future<bool> Function();

///
PermissionHandler permissionHandler = PermissionHandler();

///
class PermissionHandler {
  ///Singleton Block
  factory PermissionHandler() => _handler;

  PermissionHandler._internal();

  static final PermissionHandler _handler = PermissionHandler._internal();

  ///Permission Checker
  PermissionChecker permissionChecker = _defaultPermissionChecker;

  ///Default Rule For All Fields by Operation Type
  Map<MongoDbOperationType, bool> defaultRules = fillAllRules(rule: false);

  ///Deny
  // ignore: prefer_constructors_over_static_methods
  static Map<MongoDbOperationType, bool> fillAllRules({bool rule = false}) =>
      {for (var e in MongoDbOperationType.values) e: rule};

  /// Parser for field name
  /// components.AY85swGc.vote
  /// to
  /// components.{}.vote
  static String parseField(String field) {
    var list = field.split('.');
    var res = '';
    for (var i = 0; i < list.length; i++) {
      if (i % 2 == 0) {
        res += list[i];
      } else {
        res += '{}';
      }
    }
    return res;
  }

  ///Increment Limit
  // ignore: comment_references
  ///If [min] or [max] is [null] don't control and return true
  ///
  ///Include [max] and  [min]
  ///
  static bool checkIncrementLimit(String field, Map<String, dynamic> request,
      {num min, num max}) {
    if (request['\$inc'] != null) {
      var parsedFieldName = parseField(field);

      if (request['\$inc'][parsedFieldName] == null) return true;

      if (!(request['\$inc'] is Map)) return true;
      Map<String, dynamic> map = request['\$inc']
        ..updateAll((key, value) => MapEntry(parseField(key), value));

      var inc = num.parse(map[parsedFieldName]);
      if (max != null) {
        if (min != null) {
          return inc <= max && inc >= min;
        } else {
          return inc <= max;
        }
      } else {
        if (min != null) {
          return inc >= min;
        }
      }
    }
    return true;
  }

  ///Resource
  static Future<Map<String, dynamic>> resource(Query query) {
    // print("RESOURCE GET : $query");
    return MongoDb().getResource(query);
  }

  /// Only Use Update Operation
  static bool checkByFixedFields(List<String> fields,
      Map<String, dynamic> resource, Map<String, dynamic> request) {
    /// Request {
    ///     '$inc' :  {
    ///         'field.subfield1.subfield2...' : 2
    ///     }
    /// }
    for (var op in request?.keys) {
      /// If update operation key not start update operations
      /// Request denied
      ///
      /// Mongo Db Update Operations Documentation :
      /// https://docs.mongodb.com/manual/reference/operator/update/
      ///
      if (op.startsWith('\$')) {
        // ignore: avoid_as
        var operation = request[op];

        Iterable<String> opFields = operation.keys;
        for (var operationFieldRaw in opFields) {
          /// If update operation field key contains fixed keys
          /// Request denied
          if (fields.contains(operationFieldRaw)) {
            return false;
          }
        }
      } else {
        return false;
      }
    }

    /// In Default return true

    return true;
  }

  ///
  Future<bool> _checkRule(Query query) async {
    var checker = permissionChecker(query);
    if (checker.containsKey(query.collection)) {
      var data = await checker[query.collection][query.operationType]()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return false;
      });
      // print("PERMISSION CHECKED $data");
      return data ?? defaultRules[query.operationType];
    } else {
      return defaultRules[query.operationType];
    }
  }

/*  static String replacedFieldName(String raw){
    raw.replaceAll('', '');
  }*/

  ///
  Future<bool> check(Query query) async {
    if (query.allowAll) return true;
    if (query == null) throw Exception('Query Must Not be null');

    if (query.operationType == null) {
      throw Exception('Query Type Must Not be null');
    }

    if (query.token == null) throw Exception('Token Must Not Be Null');

    if (!query.token.isDecrypted) await query.token.decryptToken();

    if (query.operationType == MongoDbOperationType.update) {
      if (resource == null) {
        throw Exception('Resource Data must not be null in update query');
      }
    } else if (query.operationType == MongoDbOperationType.delete) {
      if (resource == null) {
        throw Exception('Resource Data must not be null in update query');
      }
    } else if (!(query.operationType == MongoDbOperationType.read ||
        query.operationType == MongoDbOperationType.create)) {
      throw Exception(
          'Query Type must be [create] or [delete] or [update] or [read]');
    }
    return _checkRule(query);
  }

 /* ///
  Future<bool> checkMessagePermission(Query query) async {
    var l = query.collection.split("-");
    if (!query.token.isDecrypted) {
      await query.token.decryptToken();
    }
    if (query.token.authType != AuthType.loggedIn) {
      return false;
    }

    if (query.queryType == QueryType.update) {
      return (query.equals["type"] != null &&
              query.equals["type"] == "conversation_info") ||
          (query.equals["type"]);
    }

    if (query.operationType == MongoDbOperationType.delete) {
      return false;
    }

    return l.contains(query.token.uId);
  }*/
}

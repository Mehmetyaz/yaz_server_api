

import '../models/query.dart';
import '../models/token/token.dart';
import 'mongo_db_service.dart';

///Mongo Db Operation Type
enum DbOperationType {
  ///Update Document
  update,

  ///Delete Document
  delete,

  ///Read Document
  read,

  ///Create Document
  create,

  /// User login op
  login,

  /// User register op
  register,

  ///
  log
}

///PermissionChecker
typedef PermissionChecker = Map<String, Map<DbOperationType, Checker>>
    Function(Query query);

Map<String, Map<DbOperationType, Checker>> _defaultPermissionChecker(
    Query query) {
  return <String, Map<DbOperationType, Checker>>{};
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
  Map<DbOperationType, bool> defaultRules = fillAllRules(rule: false);

  ///Deny
  // ignore: prefer_constructors_over_static_methods
  static Map<DbOperationType, bool> fillAllRules({bool rule = false}) =>
      {for (var e in DbOperationType.values) e: rule};

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
      {num? min, num? max}) {
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
  static Future<Map<String, dynamic>?> resource(Query query) {
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
    for (var op in request.keys) {
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
  Future<bool?> _checkRule(Query query) async {
    var checker = permissionChecker(query);
    if (checker.containsKey(query.collection)) {
      var data = await checker[query.collection!]![query.operationType]!()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return false;
      });
      // print("PERMISSION CHECKED $data");
      return data;
    } else {
      return defaultRules[query.operationType];
    }
  }

/*  static String replacedFieldName(String raw){
    raw.replaceAll('', '');
  }*/

  ///
  Future<bool?> check(Query query) async {
    if (query.allowAll) return true;

    if (query.token == null) throw Exception('Token Must Not Be Null');

    if (!query.token!.isDecrypted) await query.token!.decryptToken();


    //TODO: Starts  with * : so implement chat doc

    if (query.collection!.startsWith("_")) {
      return query.token!.authType == AuthType.admin;
    }


    // if (query.operationType == null) {
    //   throw Exception('Query Type Must Not be null');
    // }

    if (query.operationType == DbOperationType.update) {
      // ignore: unnecessary_null_comparison
      if (resource == null) {
        throw Exception('Resource Data must not be null in update query');
      }
    } else if (query.operationType == DbOperationType.delete) {
      // ignore: unnecessary_null_comparison
      if (resource == null) {
        throw Exception('Resource Data must not be null in update query');
      }
    } else if (!(query.operationType == DbOperationType.read ||
        query.operationType == DbOperationType.create)) {
      throw Exception(
          'Query Type must be [create] or [delete] or [update] or [read]');
    }
    return _checkRule(query);
  }
}

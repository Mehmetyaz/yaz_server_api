import 'package:mongo_dart/mongo_dart.dart';
import 'package:yaz_server_api/yaz_server_api.dart';

import '../services/permission_handler.dart';
import 'token/token.dart';

///Type cast from [Map<String,int>] to [Map<String,Sorting>]
///Sorting for the mongodb. "ASC" , "DSC"
Map<String, Sorting> sortingCast(Map<String, dynamic> listInt) {
  var list = <String, Sorting>{};
  for (var entry in listInt.entries) {
    list[entry.key] = Sorting.values[int.parse(entry.value.toString())];
  }
  return list;
}

///Sorting to integer
Map<String, int> sortingToInt(Map<String, Sorting> listSorting) {
  var list = <String, int>{};
  for (var entry in listSorting.entries) {
    list[entry.key] = entry.value.index;
  }
  return list;
}

///Type Cast
MongoDbOperationType mongoDbOperationTypeCast(String type) {
  switch (type) {
    case 'read':
      return MongoDbOperationType.read;
    case 'update':
      return MongoDbOperationType.update;
    case 'delete':
      return MongoDbOperationType.delete;
    case 'create':
      return MongoDbOperationType.create;
  }
  return MongoDbOperationType.read;
}

///
enum QueryType {
  ///
  query,

  ///
  listQuery,

  ///
  insert,

  ///
  update,

  ///
  exists,

  ///
  streamQuery,

  ///
  delete
}

///
MongoDbOperationType operationTypeFromQueryType(QueryType? type) {
  switch (type) {
    case QueryType.query:
      return MongoDbOperationType.read;
    case QueryType.listQuery:
      return MongoDbOperationType.read;
    case QueryType.insert:
      return MongoDbOperationType.create;
    case QueryType.update:
      return MongoDbOperationType.update;
    case QueryType.exists:
      return MongoDbOperationType.create;
    case QueryType.delete:
      return MongoDbOperationType.delete;
    case QueryType.streamQuery:
      return MongoDbOperationType.read;

    default:
      return MongoDbOperationType.read;
  }
}

///Query scheme for mongo db query
class Query {
  ///Query from socket data scheme
  Query.fromMap(Map<String, dynamic> map)
      : assert(map['query_type'] != null, "query_type must not be null"),
        assert(map["query_type"].runtimeType == int,
            "query_type must be an integer"),
        queryType = QueryType.values[map["query_type"]],
        token = AccessToken.fromToken(map['token']),
        allowAll = false {
    operationType = operationTypeFromQueryType(queryType);
    collection = map['collection'];
    if (collection == null) {
      throw Exception('Collcetion Must be null');
    }

    if (map['token'] == null) {
      throw Exception('Token must not be null');
    }

    data = map['document'] ?? null;
    filters = map['filters'] ?? <String, dynamic>{};
    equals = map['equals'] ?? <String, dynamic>{};
    sorts = sortingCast(map['sorts']);
    update = map['update'] ?? <String, dynamic>{};
    limit = map['limit'] ?? 1000;
    offset = map['offset'] ?? 0;
  }

  ///AllowAll Query
  Query.allowAll(
      {this.queryType,
      this.token,
      this.filters = const <String, dynamic>{},
      this.equals = const <String, dynamic>{},
      this.sorts = const <String, dynamic>{},
      this.update = const <String, dynamic>{},
      this.limit = 1000,
      this.offset = 0})
      : allowAll = true,
        operationType = operationTypeFromQueryType(queryType);

  ///Allow All Query
  final bool allowAll;

  ///Access Token
  final AccessToken? token;

  ///Query collection
  ///eg users , posts
  String? collection;

  ///Query document
  Map<String, dynamic>? data;

  ///Query Type
  ///update
  ///create
  ///delete
  ///read
  MongoDbOperationType? operationType;

  ///
  final QueryType? queryType;

  ///Query filter
  ///
  Map<String, dynamic> filters = <String, dynamic>{};

  ///Query equals
  /// e.g. {user_name : "mehmedyaz"}   , {name : Mehmet}
  Map<String, dynamic> equals = <String, dynamic>{};

  ///
  Map<String, dynamic> notEquals = <String, dynamic>{};

  ///Sorts
  Map<String, dynamic> sorts = <String, Sorting>{};

  ///Update data
  Map<String, dynamic> update = <String, dynamic>{};

  ///
  Map<String, bool> fileds = <String, bool>{};

  ///Data counts
  int? limit, offset;

  ///query to mongo db selector
  SelectorBuilder selector() {
    var builder = where;
    var _first = true;

    /// Equals
    for (var eq in equals.entries) {
      if (_first) {
        if (eq.value is List<dynamic> ||
            eq.value is Iterable ||
            eq.value is List<String>) {
          for (var e in eq.value) {
            if (_first) {
              builder.eq(eq.key, e);
            } else {
              builder.or(where.eq(eq.key, e));
            }
            _first = false;
          }
        } else {
          builder.eq(eq.key, eq.value);
        }
      } else {
        if (eq.value is List<dynamic> ||
            eq.value is Iterable ||
            eq.value is List<String>) {
          for (var e in eq.value) {
            builder.or(where.eq(eq.key, e));
          }
        } else {
          builder.and(where.eq(eq.key, eq.value));
        }
      }
      _first = false;
    }

    /// Not Equals
    for (var notEq in notEquals.entries) {
      if (_first) {
        if (notEq.value is List<dynamic> ||
            notEq.value is Iterable ||
            notEq.value is List<String>) {
          for (var e in notEq.value) {
            if (_first) {
              builder.ne(notEq.key, e);
            } else {
              builder.or(where.ne(notEq.key, e));
            }
            _first = false;
          }
        } else {
          builder.ne(notEq.key, notEq.value);
        }
      } else {
        if (notEq.value is List<dynamic> ||
            notEq.value is Iterable ||
            notEq.value is List<String>) {
          for (var e in notEq.value) {
            builder.or(where.ne(notEq.key, e));
          }
        } else {
          builder.and(where.ne(notEq.key, notEq.value));
        }
      }
      _first = false;
    }

    /// Sorts
    for (var sort in sorts.entries) {
      builder.sortBy(sort.key, descending: sort.value == Sorting.descending);
    }

    /// Fields
    if (fileds.values.contains(true)) {
      builder.fields(fileds.keys.where((element) => fileds[element]!).toList());
    }

    /// Exclude Fields
    if (fileds.values.contains(false)) {
      builder.excludeFields(
          fileds.keys.where((element) => !fileds[element]!).toList());
    }

    /// Limit and offsets
    builder
      ..limit(limit!)
      ..skip(offset!);

    /// Filters
    for (var filt in filters.keys) {
      /// Greater Than or equal
      if (filt == "gte") {
        var map = filters[filt];
        if (map is Map) {
          for (var field in map.entries) {
            builder.gte(field.key, field.value);
          }
        }
      }

      /// Greater Than
      if (filt == "gt") {
        var map = filters[filt];
        if (map is Map) {
          for (var field in map.entries) {
            builder.gt(field.key, field.value);
          }
        }
      }

      /// Less than or equal
      if (filt == "lte") {
        var map = filters[filt];
        if (map is Map) {
          for (var field in map.entries) {
            builder.lte(field.key, field.value);
          }
        }
      }

      /// Less Than
      if (filt == "lt") {
        var map = filters[filt];
        if (map is Map) {
          for (var field in map.entries) {
            builder.lt(field.key, field.value);
          }
        }
      }
    }

    return builder;
  }

  /*///
  List<String> get getChangesFields {
    var list = <String>[];

    if (queryType != QueryType.update) {
      return <String>[];
    } else {
      for (var op in update.keys) {
        /// If update operation key not start update operations
        /// Request denied
        ///
        /// Mongo Db Update Operations Documentation :
        /// https://docs.mongodb.com/manual/reference/operator/update/
        ///
        if (op.startsWith('\$')) {
          // ignore: avoid_as
          Map<String, dynamic> operation = update[op];
          list.addAll(operation.keys.toList());
        } else {
          list.addAll(update.keys.toList());
        }
      }
      return list;
    }
  }*/

  ///query to map for socket data
  Map<String, dynamic> toMap() {
    return {
      'collection': collection,
      'document': data,
      'filters': filters,
      'token': token!.uId,
      'equals': equals,
      'sorts': sortingToInt(sorts as Map<String, Sorting>),
      'update': update,
      'limit': limit,
      'offset': offset
    };
  }
}

///Sorting asc or dsc ?
enum Sorting {
  ///asc
  ascending,

  ///dsc
  descending
}

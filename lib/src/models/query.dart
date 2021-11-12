// ignore: import_of_legacy_library_into_null_safe
import 'package:mongo_dart/mongo_dart.dart';
import '../../yaz_server_api.dart';

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
DbOperationType mongoDbOperationTypeCast(String type) {
  switch (type) {
    case 'read':
      return DbOperationType.read;
    case 'update':
      return DbOperationType.update;
    case 'delete':
      return DbOperationType.delete;
    case 'create':
      return DbOperationType.create;
  }
  return DbOperationType.read;
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
  delete,

  ///
  count,

  ///
  register,

  ///
  login,

  /// Logging
  log,
}

///
DbOperationType operationTypeFromQueryType(QueryType type) {
  switch (type) {
    case QueryType.query:
      return DbOperationType.read;
    case QueryType.listQuery:
      return DbOperationType.read;
    case QueryType.insert:
      return DbOperationType.create;
    case QueryType.update:
      return DbOperationType.update;
    case QueryType.exists:
      return DbOperationType.create;
    case QueryType.delete:
      return DbOperationType.delete;
    case QueryType.streamQuery:
      return DbOperationType.read;
    case QueryType.register:
      return DbOperationType.register;
    case QueryType.login:
      return DbOperationType.login;
    case QueryType.log:
      return DbOperationType.log;
    case QueryType.count:
      return DbOperationType.read;
  }
}

/// Start creating collection
QueryBuilder collection(String collection) => QueryBuilder._create(collection);

///
class QueryBuilder {
  QueryBuilder._create(this._collection);

  /// [ { "a" : "b" } ,  { "a" : "c" }  , {"a" : "d" , "arg" : { "1" : "2"}}]
  ///
  /// where("a", isEqualTo: "b") => {"a" : "b"}
  /// where("arg.1" , isEqualTo: "2") => {"a" : "d" , "arg" : { "1" : "2"}}
  ///
  /// Only use equalTo or notEqualTo
  void where(String fieldName, {dynamic isEqualTo, dynamic isNotEqualTo}) {
    assert(isEqualTo == null || isNotEqualTo == null, "Only use one");
    assert(isNotEqualTo != null || isEqualTo != null, "Use one condition");
    if (isEqualTo != null) {
      _equals[fieldName] = isEqualTo;
    }
    if (isNotEqualTo != null) {
      _notEquals[fieldName] = isNotEqualTo;
    }
  }

  /// [ {"name" : "x" , "age" : 15} ,
  /// {"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  /// filter("age", isGreaterThan: 20) => {"name" : "z" , "age" : 25}
  /// filter("age", isGreaterOrEqualThan: 20) =>
  /// [{"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  void filter(String fieldName,
      {dynamic isGreaterThan,
      dynamic isGreaterOrEqualThan,
      dynamic isLessThan,
      dynamic isLessOrEqualThan}) {
    var _l = List<bool>.generate(4, (index) {
      if (index == 0) return isGreaterThan != null;
      if (index == 1) return isGreaterOrEqualThan != null;
      if (index == 2) return isLessThan != null;
      if (index == 3) return isLessOrEqualThan != null;
      return false;
    });

    assert(_l.where((element) => element).length == 1, "Only use one");
    assert(
        isGreaterThan != null ||
            isGreaterOrEqualThan != null ||
            isLessThan != null ||
            isLessOrEqualThan != null,
        "Use one condition");

    if (isGreaterThan != null) {
      _filters["\$gt"] ??= <String, dynamic>{};
      _filters["\$gt"][fieldName] = isGreaterThan;
    }
    if (isGreaterOrEqualThan != null) {
      _filters["\$gte"] ??= <String, dynamic>{};
      _filters["\$gte"][fieldName] = isGreaterOrEqualThan;
    }
    if (isLessThan != null) {
      _filters["\$lt"] ??= <String, dynamic>{};
      _filters["\$lt"][fieldName] = isLessThan;
    }
    if (isLessOrEqualThan != null) {
      _filters["\$lte"] ??= <String, dynamic>{};
      _filters["\$lte"][fieldName] = isLessOrEqualThan;
    }
  }

  /// Document Limit for list query
  void limit(int limit) {
    assert(limit > 0, "Limit must be greater than 0");
    _limit = limit;
  }

  /// Document Skip count on start for list query
  void offset(int offset) {
    assert(offset >= 0, "offset must be greater than or equal to 0");
    _offset = offset;
  }

  /// [ {"name" : "x" , "age" : 15} ,
  /// {"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  /// sort("age" , Sorting.ascending)  =>
  /// (first element) {"name" : "x" , "age" : 15}
  ///
  void sort(String fieldName, Sorting sorting) {
    _sorts[fieldName] = sorting;
  }

  ///
  /// Query Response include or exclude document fields
  void fields({List<String>? includes, List<String>? excludes}) {
    if (includes != null && includes.isNotEmpty) {
      for (var f in includes) {
        _fileds[f] = true;
      }
    }

    if (excludes != null && excludes.isNotEmpty) {
      for (var f in excludes) {
        _fileds[f] = false;
      }
    }
  }

  ///Query collection
  ///eg users , posts
  final String? _collection;

  ///Query filter
  ///
  final Map<String, dynamic> _filters = <String, dynamic>{};

  ///Query equals
  /// e.g. {user_name : "mehmedyaz"}   , {name : Mehmet}
  final Map<String, dynamic> _equals = <String, dynamic>{};

  ///
  final Map<String, dynamic> _notEquals = <String, dynamic>{};

  ///Sorts
  final Map<String, dynamic> _sorts = <String, Sorting>{};

  ///
  final Map<String, bool> _fileds = <String, bool>{};

  ///Data counts
  int? _limit = 1000, _offset = 0;

  ///
  Query toQuery(QueryType type, {AccessToken? token, bool allowAll = false}) {
    return Query.create(
        collection: _collection,
        allowAll: allowAll,
        equals: _equals,
        queryType: type,
        filters: _filters,
        limit: _limit,
        notEquals: _notEquals,
        offset: _offset,
        sorts: _sorts,
        token: token);
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
        allowAll = false,
        operationType =
            operationTypeFromQueryType(QueryType.values[map["query_type"]]) {
    collection = map['collection'];
    if (collection == null) {
      throw Exception('Collcetion Must be null');
    }

    // if (map['token'] == null) {
    //   throw Exception('Token must not be null');
    // }

    data = map['document'] ?? null;
    filters = map['filters'] ?? <String, dynamic>{};
    equals = map['equals'] ?? <String, dynamic>{};
    notEquals = map['not_equals'] ?? <String, dynamic>{};
    sorts = sortingCast(map['sorts']);
    update = map['update'] ?? <String, dynamic>{};
    limit = map['limit'] ?? 1000;
    offset = map['offset'] ?? 0;
    fileds = (map["fields"] as Map<String, dynamic>? ?? <String, dynamic>{})
        .cast<String, bool>();
  }

  ///AllowAll Query
  Query.create(
      {required this.collection,
      required this.queryType,
      this.token,
      this.filters = const <String, dynamic>{},
      this.equals = const <String, dynamic>{},
      this.sorts = const <String, dynamic>{},
      this.notEquals = const <String, dynamic>{},
      this.update = const <String, dynamic>{},
      this.fileds = const <String, bool>{},
      this.limit = 1000,
      required this.allowAll,
      this.offset = 0})
      : operationType = operationTypeFromQueryType(queryType);

  ///AllowAll Query
  Query.allowAll(
      {required this.queryType,
      this.token,
      this.filters = const <String, dynamic>{},
      this.equals = const <String, dynamic>{},
      this.sorts = const <String, dynamic>{},
      this.update = const <String, dynamic>{},
      this.fileds = const <String, bool>{},
      this.limit = 1000,
      this.offset = 0})
      : allowAll = true,
        operationType = operationTypeFromQueryType(queryType);

  ///Allow All Query
  bool allowAll = false;

  ///Access Token
  AccessToken? token;

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
  DbOperationType operationType;

  ///
  QueryType queryType;

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

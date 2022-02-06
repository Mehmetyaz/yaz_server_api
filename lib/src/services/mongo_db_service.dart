import 'dart:async';
import 'dart:convert';

// ignore: import_of_legacy_library_into_null_safe
import 'package:mongo_dart/mongo_dart.dart';

import '../models/query.dart';
import '../models/statics.dart';
import 'database/database_abstract.dart';
import 'encryption.dart';
import 'permission_handler.dart';

///
class TokenDecryptedError implements Error {
  @override
  StackTrace get stackTrace =>
      StackTrace.fromString('Token must be decrypted when permission checked');
}

///
MongoDb mongoDb = MongoDb();

///Mongo Db Service
class MongoDb extends DatabaseApi {
  ///
  factory MongoDb() => _instance;

  MongoDb._internal();

  static final MongoDb _instance = MongoDb._internal();

  ///
  late Db mongoDb;

  //  String _hostName = 'mongodb://127.0.0.1';
  //  String _port = '9298';
  // String _dbName = 'dikimall-db';
  //  final String _address = '$_hostName:$_port/$_dbName';

  // ///
  // @override
  // Future<void> init(Map<String, dynamic> config, {Function? initial}) async {
  //   _address = config["address"];
  //   mongoDb = Db(_address);
  //   _initialFunction = initial;
  //
  //   var _r =
  //       await connect().timeout(const Duration(seconds: 10), onTimeout: () {

  //     return false;
  //   });
  //   if (_r) {
  //   }
  // }

  // void tr() async {
  //   var l = [
  //     "g5mbSfIxXqaeK2regafliAadvDkkqo",
  //     "RpukxKMdzhtJplDCi01kz0j8ukrYcT",
  //     "Fma4IMG4WY0SNTzrQMHh87WEezLLhy",
  //     "M8SKZ235spmqrxNgXjD10gEp7Uo2Xj",
  //     "6dqwb3x6PdrXMFW5LIAeGNfrPrBnRr",
  //   ];
  //
  //   for (var usr in l) {
  //     var d =
  //
  // await _mongoDb.collection("users").findOne(where.eq("user_id", usr));
  //     var pp = d["profile_picture"];
  //
  //     var separator = path.separator;
  //
  //
  //     var profile = File('${path.current}$separator'
  //         'lib$separator'
  //         'src$separator'
  //         'ex$separator'
  //         '$pp$separator'
  //         'profile.png');
  //     var mid = File('${path.current}$separator'
  //         'lib$separator'
  //         'src$separator'
  //         'ex$separator'
  //         '$pp$separator'
  //         'mid.png');
  //     var thumb = File('${path.current}$separator'
  //         'lib$separator'
  //         'src$separator'
  //         'ex$separator'
  //         '$pp$separator'
  //         'profile_thumb.png');
  //
  //
  //     Directory('${path.current}$separator'
  //         'lib$separator'
  //         'src$separator'
  //         '$usr$separator').createSync();
  //
  //     if (profile.existsSync()) {
  //      File('${path.current}$separator'
  //               'lib$separator'
  //               'src$separator'
  //               '$usr$separator'
  //               'profile.jpg').createSync();
  //
  //       profile
  //           .copySync('${path.current}$separator'
  //               'lib$separator'
  //               'src$separator'
  //               '$usr$separator'
  //               'profile.jpg');
  //     }
  //
  //
  //
  //     if (mid.existsSync()) {
  //
  //
  //
  //       File('${path.current}$separator'
  //           'lib$separator'
  //           'src$separator'
  //           '$usr$separator'
  //           'mid.jpg')
  //           .createSync();
  //
  //
  //
  //       mid
  //           .copySync('${path.current}$separator'
  //               'lib$separator'
  //               'src$separator'
  //               '$usr$separator'
  //               'mid.jpg');
  //     }
  //
  //     if (thumb.existsSync()) {
  //       File('${path.current}$separator'
  //           'lib$separator'
  //           'src$separator'
  //           '$usr$separator'
  //           'profile_thumb.jpg')
  //           .createSync();
  //       thumb
  //           .copySync('${path.current}$separator'
  //               'lib$separator'
  //               'src$separator'
  //               '$usr$separator'
  //               'profile_thumb.jpg');
  //     }
  //   }
  // }

  ///Starting session trigger
//   void trigger() async {
//     var l = await _mongoDb
//         .collection("posts")
//         .aggregateToStream((AggregationPipelineBuilder()
//               ..addStage(Match(where
//                   .gte('create_date', 0)
//                   .sortBy("create_date", descending: true)
//                   .limit(5)
//                   .map['\$query'])))
//             .build())
//         .toList();
//
//
//     Timer.periodic(const Duration(milliseconds: 50), (t) {
//       l.shuffle();
//
//       update(Query.allowAll(queryType: QueryType.update)
//         ..operationType = MongoDbOperationType.update
//         ..collection = "posts"
//         ..update = {
//           "\$inc": {"upVote": 1}
//         }
//         ..equals = {"post_id": l[0]["post_id"]});
//     });
//
// //    _mongoDb
// //        .collection("posts")
// //        .aggregateToStream((AggregationPipelineBuilder()
// //              ..addStage(Match(where.gte('createDate', 0).map['\$query'])))
// //            .build());
// //
// //     _mongoDb
// //         .collection("users")
// //         .aggregateToStream(AggregationPipelineBuilder()
// //             .addStage(Match(where.gte("user_id", "000").map['\$query']))
// //             .build())
// //         .listen((event) {
// //
// //       _mongoDb.collection("users").update(where.eq("_id", event["_id"]), {
// //         "\$rename": {
// //           "name": "user_first_name",
// //           "last_name": "user_last_name",
// //           "createDate": "create_date",
// //           "birthDate": "birth_date",
// //           "biography": "user_biography",
// //           "mail": "user_mail"
// //         },
// //         "\$set": {"user_first_login": false},
// //         "\$unset": {"type": 0, "first_login": 0, "token": 0}
// //       });
// //
// //       _mongoDb
// //           .collection("users_secret")
// //           .remove(where.eq("user_id", event["user_id"]));
//
//     // event["create_date"] = event["createDate"] ?? "";
//     // event["wrote_user_id"] = event["userID"] ?? "";
//     // event["refac"] = true;
//
//     // event..remove("createDate")..remove("userID")..remove("_id");
//
//     // _mongoDb.collection("posts").insert(event);
//
//     // _mongoDb.collection("posts").update(where.eq("_id", event["_id"]), {
//     //   "\$unset": {"refac": 0}
//     // });
//   }

  ///Connect mongo db
  ///Used for session starting and reconnecting
  @override
  Future<bool> connect() async {
    mongoDb = Db(connectionConfig["address"]);
    await mongoDb.open().timeout(const Duration(seconds: 5), onTimeout: () {
      return false;
    }).onError((error, stackTrace) {
    });

    connected = mongoDb.isConnected;

    if (connected) {
      if (initialFunction != null) {
        initialFunction!();
      }
      return true;
    } else {
      return false;
    }
  }

  // ///http style arg parser
  // static String argParser(Map<String, dynamic> args) {
  //   return args.entries.map((p) => '${p.key}=${p.value}').join('&');
  // }
  //
  // /// Mongo Db Errors
  // static String errorName(String? name) {
  //   switch (name) {
  //     case 'DuplicateKey':
  //       return 'DuplicateID';
  //     case 'argument_error':
  //       return 'ArgumentError';
  //     default:
  //       return 'Undefined Error';
  //   }
  // }

  /// Use for admin operation
  @override
  Future<Map<String, dynamic>?> getResource(Query query) {
    return mongoDb.collection(query.collection!).findOne(query.selector());
  }

  ///Update Operation
  @override
  Future<Map<String, dynamic>?> update(Query _query) async {
    return operation(_query, () async {
      var dat = await mongoDb.collection(_query.collection!).update(
          _query.selector(), _query.update,
          upsert: true, writeConcern: WriteConcern.UNACKNOWLEDGED);

      // ignore: unnecessary_null_comparison
      if (dat != null) {
        return {
          'success': true,
          'data': await PermissionHandler.resource(_query)
        };
      } else {
        return {'success': false, 'reason': 'document is not exists'};
      }
    });
  }

  ///Update Operation
  @override
  Future<Map<String, dynamic>?> delete(Query _query) async {
    return operation(_query, () async {
      var dat = await mongoDb
          .collection(_query.collection!)
          .remove(_query.selector(), writeConcern: WriteConcern.UNACKNOWLEDGED);

      // ignore: unnecessary_null_comparison
      if (dat != null) {
        return {
          'success': true,
          'data': await PermissionHandler.resource(_query)
        };
      } else {
        return {'success': false, 'reason': 'document is not exists'};
      }
    });
  }

  ///Exist query
  @override
  Future<Map<String, dynamic>?> exists(Query query) async {
    return operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection!).count(query.selector());
      if (dat > 0) {
        return {'success': true, 'exists': true};
      } else {
        return {'success': true, 'exists': false};
      }
    });
  }

  ///query single document
  @override
  Future<Map<String, dynamic>?> count(Query query) async {
    return operation(query, () async {
      var dat = <String, dynamic>{};
      var res =
          await mongoDb.collection(query.collection!).count(query.selector());
      // ignore: unnecessary_null_comparison
      if (res != null) {
        dat['success'] = true;

        dat["count"] = res;
        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///query single document
  @override
  Future<Map<String, dynamic>?> query(Query query) async {
    return operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection!).findOne(query.selector());
      // ignore: unnecessary_null_comparison
      if (dat != null) {
        dat['success'] = true;

        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///List query
  @override
  Future<Map<String, dynamic>?> listQuery(Query query) async {
    return operation(query, () async {
      var dat = <String, dynamic>{
        "list": await mongoDb
            .collection(query.collection!)
            .find(query.selector())
            .toList()
      };


      // ignore: unnecessary_null_comparison
      if (dat != null) {
        dat['success'] = true;
        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///insert query
  @override
  Future<Map<String, dynamic>?> insertQuery(Query query) async {

    return operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection!).insertOne(query.data!);

      if (dat.success) {
        return {
          "success": dat.success,
        };
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///add user to db
  @override
  Future<Map<String, dynamic>?> addUserToDb(
      Map<String, dynamic>? args, String? deviceID) async {
    return operation(Query.allowAll(queryType: QueryType.register), () async {
      if (args == null ||
          !args.containsKey("user_mail") ||
          !args.containsKey("password")) {
        return {'success': false, "reason": "user_mail or password invalid"};
      }

      var qB = collection("users")
        ..where("user_mail", isEqualTo: args["user_mail"]);

      var mailEx = await exists(qB.toQuery(QueryType.exists, allowAll: true));
      if (mailEx!["success"] && mailEx["exists"]) {
        return {'success': false, "reason": "user_mail already use"};
      }

      var secret = <String, dynamic>{
        'user_mail': args['user_mail'],
        'password': args['password']
      };



      var open = args;
      // ignore: cascade_invocations
      open.remove('password');
      var secretEncrypted = await encryptionService.encrypt3(secret);

      var res = await mongoDb
          .collection("users")
          .insert(open, writeConcern: WriteConcern.ACKNOWLEDGED);

      var res2 = await mongoDb.collection("users_secret").insert(
          {'data': secretEncrypted, 'user_id': args['user_id']},
          writeConcern: WriteConcern.ACKNOWLEDGED);

      if ((res['ok'] != null && res2['ok'] != null) &&
          (res['ok'].toDouble() == 1.0 && res2['ok'].toDouble() == 1.0)) {
        return {'success': true, 'user': open};
      } else {
        return {'success': false};
      }
    });
  }

  ///confirm user
  @override
  Future<Map<String, dynamic>?> confirmUser(
      Map<String, dynamic>? args, String? deviceID) async {
    return operation(Query.allowAll(queryType: QueryType.login), () async {
      var userD = {
        'user_mail': args!['user_mail'],
        'password': args['password']
      };


      var encryptedSecret = await encryptionService.encrypt3(userD);


      var userDataEncrypted = await mongoDb
          .collection("users_secret")
          .findOne(where.eq('data', encryptedSecret));



      //ignore: unnecessary_null_comparison
      if (userDataEncrypted != null && userDataEncrypted['data'] != null) {
        var userData =
            await (encryptionService.decrypt3(userDataEncrypted['data']));

        if (userData == null) {
          return {"success": false, 'error': 'user_data_undefined'};
        }

        if (userData['user_mail'] == args['user_mail'] &&
            userData['password'] == args['password']) {
          ///User Conirmed



          var userOpenData = await mongoDb
              .collection("users")
              .findOne(where.all('user_id', [userDataEncrypted['user_id']]));

          //ignore: unnecessary_null_comparison
          if (userOpenData != null) {
            userOpenData['success'] = true;
            return {'success': true, 'secret': userData, 'open': userOpenData};
          } else {
            return {'success': false, 'error': 'user_data_undefined'};
          }
        } else {

          return {'success': false, 'error': 'invalid_password'};
        }
      } else {
        return {'success': false, 'error': 'invalid_password'};
      }
    });
  }

  ///log user connection
  @override
  Future<Map<String, dynamic>?> logConnection(Map<String, dynamic> args) async {
    return operation(Query.allowAll(queryType: QueryType.log), () async {
      var id = Statics.getRandomId(24);
      args['id'] = id;
      var res = await mongoDb
          .collection("logs")
          .insert(args, writeConcern: WriteConcern.ACKNOWLEDGED);
      res['id'] = id;
      return res;
    });
  }
}

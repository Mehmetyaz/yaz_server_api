import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

import '../models/query.dart';
import '../models/socket_data_model.dart';
import '../models/statics.dart';
import 'encryption.dart';
import 'permission_handler.dart';
import 'trigger_service.dart';

///Mongo Db Inter Operation
typedef Interop = Future<Map<String, dynamic>> Function();

///
class TokenDecryptedError implements Error {
  @override
  StackTrace get stackTrace =>
      StackTrace.fromString('Token must be decrypted when permission checked');
}

///
MongoDb mongoDb = MongoDb();

///Mongo Db Service
class MongoDb {
  ///Bu da singleton
  ///localde çalışan bir mongo db manual db
  factory MongoDb() => _instance;

  MongoDb._internal();

  static final MongoDb _instance = MongoDb._internal();

  bool _connected = false;

  ///
  Db mongoDb;

  //  String _hostName = 'mongodb://127.0.0.1';
  //  String _port = '9298';
  // String _dbName = 'dikimall-db';
  //  final String _address = '$_hostName:$_port/$_dbName';

  String _address;

  Function _initialFunction;

  ///
  Future<void> init(String address, {Function initial}) async {
    _address = address;
    mongoDb = Db(_address);
    _initialFunction = initial;

    await connect();

    // ignore: avoid_print
    print("Mongo Connected: ${mongoDb.isConnected}");
  }

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
  //     // print(q);
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
//     print("Lıst leng : $l");
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
// //            .build())
// //        .listen(print);
// //
// //     _mongoDb
// //         .collection("users")
// //         .aggregateToStream(AggregationPipelineBuilder()
// //             .addStage(Match(where.gte("user_id", "000").map['\$query']))
// //             .build())
// //         .listen((event) {
// //       print("EVENT: $event");
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
  Future<bool> connect() async {
    await mongoDb.open().timeout(const Duration(seconds: 5), onTimeout: () {
      return false;
    });

    _connected = mongoDb.isConnected;

    if (_connected) {
      if (_initialFunction != null) {
        _initialFunction();
      }
      return true;
    } else {
      return false;
    }
  }

  ///http style arg parser
  static String argParser(Map<String, dynamic> args) {
    return args.entries.map((p) => '${p.key}=${p.value}').join('&');
  }

  /// Mongo Db Errors
  static String errorName(String name) {
    switch (name) {
      case 'DuplicateKey':
        return 'DuplicateID';
        break;
      case 'argument_error':
        return 'ArgumentError';
        break;
      default:
        return 'Undefined Error';
    }
  }

  ///
  Future<Map<String, dynamic>> getResource(Query query) {
    return mongoDb.collection(query.collection).findOne(query.selector());
  }

  ///PermissionHandler
  final PermissionHandler permissionHandler = PermissionHandler();

  ///Trigger Service
  final TriggerService triggerService = TriggerService();

  ///Mongo Db operasyonları standardı kalıp halinde
  Future<Map<String, dynamic>> _operation(Query query, Interop interop) async {
    try {
      ///Try Operation
      if (await permissionHandler.check(query)) {
        var dat = await triggerService.triggerAndReturn(query, interop);
        //
        // print("DATA ON INTEROP TRIGGER $dat \n"
        //     "QUERY: ${query.collection}  ${query.queryType}");

        return dat;
      } else {
        // print('Permission Denied for 1'
        //     ' \ncollection ${query.collection}\n${query.queryType}');
        return {
          'success': false,
          'error_code': 816,
          'reason': 'Permission Denied for 2'
              ' \ncollection ${query.collection}\n${query.queryType}'
        };
      }

      // ignore: avoid_catching_errors
    } on MongoDartError {
      ///Connection Exception - Try one more

      var msg = await connect();
      if (_connected) {
        // ignore: avoid_catching_errors
        try {
          ///Try Operation

          if (await permissionHandler.check(query)) {
            return await triggerService.triggerAndReturn(query, interop);
          } else {
            // print('Permission Denied for'
            //     ' \ncollection ${query.collection}\n${query.queryType}');

            return {
              'success': false,
              'reason': 'Permission Denied for'
                  ' \ncollection ${query.collection}\n${query.queryType}'
            };
          }
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          //TODO: ADD ERROR
          // ignore: lines_longer_than_80_chars
          // print('CONNECTED AND ERROR AGAIN . type :'
          //     ' ${e.runtimeType} , message : ${e.toString()}');

          ///Return exception details
          ///should'nt connection error
          return SocketData.fromFullData(
              {'success': false, 'reason': errorName(e['codeName'])}).data;
        }
      } else {
        ///unsuccessful connection
        //TODO: ADD ERROR
        return SocketData.fromFullData(
            {"success": false, "reason": msg ?? "Undefined Error"}).data;
      }
    } on Exception catch (e) {
      //TODO: ADD ERROR

      ///Other Exception
      return SocketData.fromFullData(
          {'success': false, 'reason': errorName(e.toString())}).data;
    }
  }

  ///
  Future<int> documentCount(String collection, [dynamic selector]) {
    return mongoDb.collection(collection).count(selector);
  }

  ///Update Operation
  Future<Map<String, dynamic>> update(Query _query) async {
    return _operation(_query, () async {
      var dat = await mongoDb.collection(_query.collection).update(
          _query.selector(), _query.update,
          upsert: true, writeConcern: WriteConcern.UNACKNOWLEDGED);
      // print("UPDATE QUERY : $dat");
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
  Future<Map<String, dynamic>> exists(Query query) async {
    return _operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection).count(query.selector());
      if (dat != null && dat > 0) {
        return {'success': true, 'exists': true};
      } else {
        return {'success': true, 'exists': false};
      }
    });
  }

  ///query single document
  Future<Map<String, dynamic>> query(Query query) async {
    return _operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection).findOne(query.selector());
      if (dat != null) {
        dat['success'] = true;
        // print("QUERY RESULT : $dat");
        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///List query
  Future<Map<String, dynamic>> listQuery(Query query) async {
    return _operation(query, () async {
      var dat = <String, dynamic>{
        "list": await mongoDb
            .collection(query.collection)
            .find(query.selector())
            .toList()
      };

      // print("LİST QUERY : $dat \n\n${query.toMap()}");
      if (dat != null) {
        dat['success'] = true;
        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///insert query
  Future<Map<String, dynamic>> insertQuery(Query query) async {
    // print("INSERT:::::: ${query.data}");
    return _operation(query, () async {
      var dat =
          await mongoDb.collection(query.collection).insertOne(query.data);

      // print("INSERT QUERY : : $dat");
      if (dat != null) {
        dat["success"] = true;
        return dat;
      } else {
        return {'success': false, 'error': 'data_is_null'};
      }
    });
  }

  ///add user to db
  Future<Map<String, dynamic>> addUserToDb(
      Map<String, dynamic> args, String deviceID) async {
    return _operation(Query.allowAll(), () async {
      var secret = <String, dynamic>{
        'user_mail': args['user_mail'],
        'password': args['password']
      };

      var open = args;
      // ignore: cascade_invocations
      open.remove('password');
      var secretEncrypted = await encryptionService.encrypt3(secret);
      // print("ARGS: $args \n\nOPEN: $open \n\nSECRET::$secret");
      var res = await mongoDb
          .collection("users")
          .insert(open, writeConcern: WriteConcern.ACKNOWLEDGED);
      // print("ADD USER OP START4");
      var res2 = await mongoDb.collection("users_secret").insert(
          {'data': secretEncrypted, 'user_id': args['user_id']},
          writeConcern: WriteConcern.ACKNOWLEDGED);

      if ((res['ok'] != null && res2['ok'] != null) &&
          (res['ok'].toDouble() == 1.0 && res2['ok'].toDouble() == 1.0)) {
        return {'success': true, 'user_id': open['user_id']};
      } else {
        return {'success': false};
      }
    });
  }

  ///confirm user
  Future<Map<String, dynamic>> confirmUser(
      Map<String, dynamic> args, String deviceID) async {
    return _operation(Query.allowAll(), () async {
      var userD = {
        'user_mail': args['user_mail'],
        'password': args['password']
      };
      // print(userD);

      var encryptedSecret = await encryptionService.encrypt3(userD);
      // print("Search User: : $encryptedSecret");

      var userDataEncrypted = await mongoDb
          .collection("users_secret")
          .findOne(where.eq('data', encryptedSecret));

      // print("Encrypted User Data: $userDataEncrypted");

      if (userDataEncrypted != null && userDataEncrypted['data'] != null) {
        var userData =
            await encryptionService.decrypt3(userDataEncrypted['data']);

        // print("Decrypted User Data: $userData");
        if (userData['user_mail'] == args['user_mail'] &&
            userData['password'] == args['password']) {
          ///User Conirmed
          // print("USER CONFIRMED");
          // print('CONFIRM USER :::: $userData');

          var userOpenData = await mongoDb
              .collection("users")
              .findOne(where.all('user_id', [userDataEncrypted['user_id']]));

          if (userOpenData != null) {
            userOpenData['success'] = true;
            return {'success': true, 'secret': userData, 'open': userOpenData};
          } else {
            return {'success': false, 'error': 'user_data_undefined'};
          }
        } else {
          // print("USER NOT CONFIRMED");
          return {'success': false, 'error': 'invalid_password'};
        }
      } else {
        return {'success': false, 'error': 'invalid_password'};
      }
    });
  }

  ///log user connection
  Future<Map<String, dynamic>> logConnection(Map<String, dynamic> args) async {
    return _operation(Query.allowAll(), () async {
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

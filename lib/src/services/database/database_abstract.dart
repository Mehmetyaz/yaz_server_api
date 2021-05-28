import 'dart:async';

import '../../../yaz_server_api.dart';

///Mongo Db Inter Operation
typedef Interop = Future<Map<String, dynamic>> Function();

///
abstract class DatabaseApi<T extends Exception> {
  /// Database connection configuration
  /// You can fill your want
  late Map<String, dynamic> connectionConfig;

  ///
  bool connected = false;

  ///
  Function? initialFunction;

  ///
  Future<Map<String, dynamic>?> getResource(Query query);

  ///
  Future<void> init(Map<String, dynamic> connectionConfig,
      {Function? initial}) async {
    this.connectionConfig = connectionConfig;
    initialFunction = initial;

    var _r =
        await connect().timeout(const Duration(seconds: 10), onTimeout: () {
      // ignore: avoid_print
      print("Database not connected : timeout");
      return false;
    });
    connected = _r;
    if (_r) {
      // ignore: avoid_print
      print("Database connected");
    } else {
      // ignore: avoid_print
      print("Database Connection failed");
      throw Exception("Database Connection failed");
    }
  }

  /// You can connect with connectionConfig
  /// dont forget return bool is connection success
  Future<bool> connect();

  ///Mongo Db operasyonları standardı kalıp halinde
  Future<Map<String, dynamic>?> operation(Query query, Interop interop) async {
    try {
      ///Try Operation
      if ((await (server.permissionHandler.check(query)) ?? false)) {
        var dat = await server.triggerService.triggerAndReturn(query, interop);
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
    } on T {
      ///Connection Exception - Try one more

      var msg = await connect();
      if (connected) {
        // ignore: avoid_catching_errors
        try {
          ///Try Operation

          if (await (server.permissionHandler.check(query)) ?? false) {
            return await server.triggerService.triggerAndReturn(query, interop);
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
        } catch (e,s) {
          //TODO: ADD ERROR
          // ignore: lines_longer_than_80_chars
          // print('CONNECTED AND ERROR AGAIN . type :'
          //     ' ${e.runtimeType} , message : ${e.toString()}');

          ///Return exception details
          ///should'nt connection error
          return {
            'success': false,
            "message_type": "error",
            'reason': (e.toString()),
            "data": {
              "stack_trace" : s.toString()
            }
          };
        }
      } else {
        ///unsuccessful connection
        //TODO: ADD ERROR
        return SocketData.fromFullData({"success": false, "reason": msg}).data;
      }
    } on Exception catch (e) {
      //TODO: ADD ERROR

      ///Other Exception
      return SocketData.fromFullData(
          {'success': false, 'reason': (e.toString())}).data;
    }
  }

  ///Update Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           'data': <your response data>,
  ///           'reason' : null
  ///         };
  /// ```
  ///
  /// if success false you can type reason field
  ///
  Future<Map<String, dynamic>?> update(Query _query);

  /// Delete Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           'data': <your response data>,
  ///           'reason' : null
  ///         };
  /// ```
  ///
  // ignore_for_file: comment_references
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> delete(Query _query);

  /// Exist Query Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           'exists' : true, // or false
  ///         };
  /// ```
  ///
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> exists(Query query);

  /// Exist Query Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           'count' : response, // int
  ///         };
  /// ```
  ///
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> count(Query query);

  /// Exist Query Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           ...
  ///           ... // responsed data
  ///         };
  /// ```
  ///
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> query(Query query);

  /// Exist Query Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///           'list' : [response]
  ///         };
  /// ```
  ///
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> listQuery(Query query);

  /// Exist Query Operation
  ///
  /// ```
  /// return {
  ///           'success': true, // or false
  ///         };
  /// ```
  ///
  /// if [success] false you can type [reason] field
  ///
  Future<Map<String, dynamic>?> insertQuery(Query query);

  /// add user to db
  /// type you want
  Future<Map<String, dynamic>?> addUserToDb(
      Map<String, dynamic>? args, String? deviceID);

  ///confirm user
  /// type you want
  Future<Map<String, dynamic>?> confirmUser(
      Map<String, dynamic>? args, String? deviceID);

  ///log user connection
  Future<Map<String, dynamic>?> logConnection(Map<String, dynamic> args);
}

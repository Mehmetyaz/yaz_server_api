
A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style  
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).


## Yaz Server Api

### Framework
Yaz server  api is useful framework for database-server-client connection.
[yaz_client_package](https://pub.dev/packages/yaz_client)
Yaz Client package supports **web** and **mobile**.

- **Web Secket :** As default all server-client communications done via **WebSocket**.
- **Encrypted:** Almost all data is **encrypted** with different tokens for each session.
- **Send Data:** You can instantly send data to all connected devices.
- **Database Implement:** You can forward incoming requests directly to the database.
- **Triggers:** You can define triggers for operations on the database.
- **Periodic Operations:** You can set periodic operations
- **Listen DB Operations:** You can listen db changes
- **Permission Handler:** You can control operation permissions based on user or source data.
- **Auth Service:** You can use Auth Operations
- **Chat Service:** You can use simply Chat operations
- **Custom Socket Operations:** You can listen custom web socket messages and define operations
-  **Custom Http Request Implement** You can listen http request and define custom requests
-  **Query standardization**
-  **SocketData standardization**





## Usage

A simple usage example for server:

#### Init Once
```dart  
import 'package:yaz_server_api/yaz_server_api.dart';  
  
main() {  
  /// Mongo Db Database implemented  
  /// from yaz_server_api  
  ///   
  var mongoDb = MongoDb();  
    
  /// init your database api  
  /// with your database connectionConfiguration  
  /// and secret keys  
  /// and http server  
  YazServerApi(databaseApi: mongoDb).init(  
         clientSecretKey1: "secret",  
          clientSecretKey2: "secret",  
          tokenSecretKey1: "secret",  
          tokenSecretKey2: "secret",  
          deviceIdSecretKey: "secret",  
          server: HttpServer.bind("localhost", 1234),  
          connectionConfiguration: {  
           "address" : "mongodb://127.0.0.1:1235/db-name"  
          } /// for mongo db  
  );  
}  
```  

#### Implement Your Database
Now, in yaz_server_api implement only mongo db operations
But other databases implements coming soon
You can implement Your Database like mongo db example:
 ```dart
 ///Mongo Db Service  
class MongoDb extends DatabaseApi {
	///...
	@override  
	Future<bool> connect() async {  
		mongoDb = Db(connectionConfig["address"]);
		///....
	}

	///query single document
	@override  
	Future<Map<String, dynamic>?> query(Query query) async {  
	  return operation(query, () async {  
			/// if you want to encapsulate; 
			/// [permission handler]
			/// [database triggers]
			/// [listen]
			/// you can wrap your function with
			/// operation(query , Map<String , dynamic> Function())
	  }
	// Supported operations
	@override
	Future<Map<String, dynamic>?> update(Query _query);
	Future<Map<String, dynamic>?> delete(Query _query);
	Future<Map<String, dynamic>?> exists(Query query);
	Future<Map<String, dynamic>?> count(Query query);
	Future<Map<String, dynamic>?> listQuery(Query query);
	Future<Map<String, dynamic>?> insertQuery(Query query);
	Future<Map<String, dynamic>?> addUserToDb(  
	  Map<String, dynamic>? args, String? deviceID);
	Future<Map<String, dynamic>?> confirmUser(  
	  Map<String, dynamic>? args, String? deviceID);
}
```

#### Check Permission
You can set default rules for all operation types
```dart
permissionHandler  
  ..defaultRules = PermissionHandler.fillAllRules(rule: true)
```
or
```dart
permissionHandler  
  ..defaultRules = {  
	  DbOperationType.create : false,  
	  DbOperationType.read : true,  
	  DbOperationType.delete : false,
	  ///....
   }
```


Check Permission:
```dart
permissionHandler
	..permissionChecker = (query) {
		"collection_name" : {
			DbOperationType.read: () async => true,
			///other operation types
			///if not type use default
		},

		/// Users example
		'users': {  
			  /// Block out of your client  
			  DbOperationType.read: () async {  
						  return query.token != null;  
					 },
					 
			  /// everyone can create an account for themselves  
			  DbOperationType.create: () async =>  
						  query.token!.uId == query.data!['user_id'],  
  
			  /// everyone can update an users data for your document  
			  DbOperationType.update: () async {  
						  return query.token != null &&  
							  query.token!.authType == AuthType.loggedIn &&  
							  query.token!.uId == query.equals["user_id"];  
						},
			  /// delete is false as default
		},
	}
```


#### Set Triggers

##### Database Triggers

OnUpdate
```
triggerService.onUpdate("posts", (query, before, after) async {  
  print("post updated from $before  to $after  by ${query.token!.uId}");
  /// post updated from null to <user-data>  by <user-id>
  /// before is null. Because beforeRequired is false
} ,beforeRequired: false);
```
On Create
```
triggerService.onCreate('collection', (query) async {  
  /// query have created data
});
```
OnDelete
```
triggerService.onDelete("collection", (query, before) async {  
  print("Document Deleted: $before");  
}, beforeRequired: true);
```
##### Auth Triggers
```dart
triggerService  
  ..onUserLoggedIn("my_first_logged_in", (user) async {  
	  print("USER LOGGED : ${user.toJson()}");  
 }) ..onUserRegister("my_first_register", (user) async {  
	  print("USER REGISTERED: ${user.toJson()}");  
 });
```

##### Periodic Triggers

```dart
triggerService.periodic("my_first_periodic", Duration(minutes: 30), () async {  
  print("Function Triggered Each 30 minutes");  
});

/// Remove
triggerService.cancelPeriodic("my_first_periodic");
```

##### Http Triggers
```dart  
httpServerService.use('/get_reviews', (req) async {  
  req.response.headers.set('Content-Type', 'application/json');  
  req.response.add(utf8.encode(json.encode(example..shuffle())));  
  await req.response.close();  
});
```

##### Http Triggers
```dart  
httpServerService.use('/get_reviews', (req) async {  
  req.response.headers.set('Content-Type', 'application/json');  
  req.response.add(utf8.encode(json.encode(example..shuffle())));  
  await req.response.close();  
});
```

##### On Web Socket Data Triggers
Triggered "random_posts" type socket data
this trigger as a different http triggers; encrypted, have token and posted by web socket
```dart
socketOperations.addCustomOperation("random_posts",  
 (listener, socketData) async {  
  /// Listener: connection that request type with server  
  print(listener.deviceID);  
  print(listener.userId);  
  
  /// requested type data  
  print(socketData.data);  
  
  var res = await sendAndWaitMessage(listener, socketData.response({"hello": "world!"}));  
  if (res!.success) {  
  print("data received by client");  
 }  
});
```

## More Futures And Documentation Coming Soon

### For Support : mehmedyaz@gmail.com

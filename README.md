A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:yaz_server_api/yaz_server_api.dart';

main() {
  YazServerApi.init(
         clientSecretKey1: "secret",
          clientSecretKey2: "secret",
          tokenSecretKey1: "secret",
          tokenSecretKey2: "secret",
          deviceIdSecretKey: "secret",
          server: HttpServer.bind("localhost", 1234),
          mongoDbAddress: "mongodb://127.0.0.1:1235/db-name" /// mongo db address
  );
}
```

## Features and bugs

Trigger Service
Permission Handler
Handle Custom Web Socket Operation
Handle Custom Http Request
Chat Service


Well Soon

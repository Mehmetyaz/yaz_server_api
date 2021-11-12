part of 'data.dart';





///
abstract class YazContext {
  ///
  YazContext({required this.deviceId, this.token});

  ///
  DeviceId deviceId;

  ///
  AccessToken? token;

  ///
  bool get encrypted {
    return token != null;
  }

  ///
  Future<String?> get userID async {
    //TODO:
  }

  ///
  Future<bool> checkToken() async {
    //TODO:
    return false;
  }
}

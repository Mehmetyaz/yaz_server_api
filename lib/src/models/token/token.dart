import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../../services/encryption.dart';

///User Auth Type
enum AuthType {
  ///
  guess,

  ///
  loggedIn,

  ///
  admin,

  ///
  undefined
}

///Access Token
class AccessToken {
  ///
  AccessToken.generateForGuess(this.authType, this.deviceID)
      : isHashed = false,
        isDecrypted = true,
        _token = null,
        // assert(authType, 'Auth Type must\'nt be null or undefined'),
        assert(
            authType == AuthType.guess,
            'This constructor for used only guess user '
            'Please use [.generateForUser] constructor for user');

  ///Generate for user
  AccessToken.generateForUser(
      {required this.authType,
      required String this.mail,
      required this.deviceID,
      required String this.uId})
      : isHashed = false,
        isDecrypted = true,
        _token = null,
        assert(
            authType == AuthType.loggedIn || authType == AuthType.admin,
            'This constructor for used only logged user '
            'Please use [.generateForGuess] constructor for guess');

  ///From Token
  AccessToken.fromToken(this._token)
      : isHashed = true,
        isDecrypted = false;

  @override
  String toString() {
    return "$authType $uId , $mail";
  }

  ///If Decrypted
  bool isDecrypted;

  ///İs Hashed
  bool isHashed;

  ///Auth Type
  late AuthType authType;

  ///user device ID
  late String deviceID;

  ///User ıd  (if logged)
  String? uId;

  ///user mail (if logged)
  String? mail;


  ///Token
  String? _token;

  /// Get Encrypted Token
  /// If Token hashed return token
  /// else once hash
  Future<String?> get encryptedToken async {
    if (isHashed) {
      return _token;
    } else {
      return _encrypt();
    }
  }

  /// Hash (encrypt) token
  Future<void> encryptToken() async {
    await _encrypt();
    isHashed = true;
    isDecrypted = true;
  }

  ///Decrypt Token
  ///Can reach uID, mail , password fields after decrypt
  Future<AccessToken> decryptToken() async {
    if (isHashed) {
      var data = await (_decrypt());

      isHashed = true;
      isDecrypted = true;

      switch (_getAuthType(data!['auth_type'])) {
        case AuthType.guess:
          authType = AuthType.guess;
          deviceID = data['device_id'];
          break;
        case AuthType.loggedIn:
          authType = AuthType.loggedIn;
          deviceID = data['device_id'];
          uId = data['user_id'];
          mail = data['mail'];
          break;
        default:
          authType = AuthType.undefined;
          break;
      }
    }
    return this;
  }

  Future<Map<String, dynamic>?> _decrypt() async {
    assert(_token != null, 'Token must not be null for decrypt token');
    var data = await encryptionService.decrypt2(data: _token!);
    return data;
  }

  /// Create access token encrypted from user info
  Future<String?> _encrypt() async {
    if (authType == AuthType.guess) {
      _token = await encryptionService
          .encrypt2(data: {'auth_type': 'guess', 'device_id': deviceID});
      return _token;
    } else {
      _token = await encryptionService.encrypt2(data: {
        'auth_type': 'auth',
        'device_id': deviceID,
        'user_id': uId,
        'mail': mail
      });
      return _token;
    }
  }

  ///Create access token from encrypted data
  // static Future<AccessToken> fromList(List<dynamic> list) async {
  //   var tokenList = Statics.uint8Cast(list);
  //   var _t = AccessToken.fromToken(tokenList);
  //   await _t.decryptToken();
  //   return _t;
  // }

  static AuthType _getAuthType(String? type) {
    if (type == 'guess') {
      return AuthType.guess;
    } else if (type == 'auth') {
      return AuthType.loggedIn;
    } else {
      return AuthType.undefined;
    }
  }

  ///Get String name from Auth Type
  static String getStringType(AuthType type) {
    if (type == AuthType.guess) {
      return 'guess';
    } else if (type == AuthType.loggedIn) {
      return 'auth';
    } else {
      return 'undefined';
    }
  }
}

///
Future<Map<String, dynamic>?> checkToken(String token) async {
  var comps = token.split(".");

  if (comps.length != 3) {
    throw Exception("Token format unknown");
  }

  try {
    var mes = "${comps[0]}.${comps[1]}";
    var mac = comps[2];
    var hm = Hmac.sha512();

    var secret =
    SecretBox(utf8.encode(mes), nonce: [], mac: Mac(base64Url.decode(mac)));
    await secret.checkMac(
        macAlgorithm: hm,
        secretKey: SecretKey(utf8.encode("11118111111155111511111191111112")),
        aad: []);

    var p = json.decode(utf8.decode(base64Url.decode(comps[1])));

    return p;
  } on Exception catch (e) {
    stdout.write(e);
    return null;
  }
}

///
Future<String> encryptToken(Map<String, dynamic> payload) async {
  var h = {"alg": "HS512", "typ": "JWT"};
  var base64H = base64Url.encode(utf8.encode(json.encode(h)));
  var base64P = base64Url.encode(utf8.encode(json.encode(payload)));
  var macMessage = "$base64H.$base64P";
  var mac = await Hmac.sha512().calculateMac(utf8.encode(macMessage),
      secretKey: SecretKey(utf8.encode("11118111111155111511111191111112")),
      aad: [],
      nonce: []);

  //


  return "$base64H.$base64P.${base64Url.encode(mac.bytes)}";
}

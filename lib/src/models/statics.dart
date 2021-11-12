import 'dart:math';
import 'dart:typed_data';

import '../../yaz_server_api.dart';

// ignore_for_file: prefer_constructors_over_static_methods
///Static functions
mixin Statics {
/*  ///Generate token with data
  static Future<Uint8List> generateToken(
      Nonce nonce, Nonce cnonce, Map<String, dynamic> data) async {
    return  EncryptionService.encrypt2(
         data: data);
  }*/

  ///Get random id defined length
  static String getRandomId(int len) {
    var _characters =
        'ABCDEFGHIJKLMNOPRSTUQYZXWabcdefghijqklmnoprstuvyzwx0123456789';
    var _listChar = _characters.split('');
    var _lentList = _listChar.length;
    var _randId = <String>[];

    for (var i = 0; i < len; i++) {
      var _randNum = Random();
      var _r = _randNum.nextInt(_lentList);
      _randId.add(_listChar[_r]);
    }
    var id = StringBuffer();
    for (var c in _randId) {
      id.write(c);
    }
    return id.toString();
  }

  ///Nonce from List<dynamic>
  static Nonce nonceCast(List<dynamic> nonce) {
    var nListInt = <int>[];
    for (var i in nonce) {
      if (i.runtimeType == int) {
        nListInt.add(i);
      } else {
        nListInt.add(int.parse(i));
      }
    }
    return Nonce(nListInt);
  }

  ///Uint8List cast form List<dynamic>
  static Uint8List uint8Cast(List listDynamic) {
    var nListInt = <int>[];
    for (var i in listDynamic) {
      if (i.runtimeType == int) {
        nListInt.add(i);
      } else {
        nListInt.add(int.parse(i));
      }
    }
    return Uint8List.fromList(nListInt);
  }
}

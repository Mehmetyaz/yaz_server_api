part of 'data.dart';

///
abstract class YazRequest {
  ///
  YazRequest({required this.type, required this.requestId, required this.body});

  ///
  YazRequest.create({String? customId, required this.body, required this.type})
      : requestId = customId ?? Statics.getRandomId(20);

  /// Response success
  Future<YazResponse?> response();

  /// Response Error
  Future<YazResponse?> error();

  ///
  String requestId;

  ///
  String type;

  /// Request side data
  Map<String, dynamic> body;
}

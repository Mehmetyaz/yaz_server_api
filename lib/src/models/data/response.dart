part of 'data.dart';
///
class YazResponse {
  ///
  YazResponse(
      {required this.id,
      required this.context,
      required this.type,
      required this.body,
      required this.statusCode});

  ///
  String id;

  ///
  String type;

  ///
  Map<String, dynamic> body;

  ///
  YazContext context;

  ///
  int statusCode;
}

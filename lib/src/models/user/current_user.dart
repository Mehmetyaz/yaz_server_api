
// ignore: import_of_legacy_library_into_null_safe
import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'current_user.g.dart';

///Current User Class
@JsonSerializable()
class YazApiUser extends YazApiUserFront {
  ///
  YazApiUser(String? firstName, String? lastName, String? userID,
      {required this.biography,
      required this.birthDate,
      required this.isFirstLogin,
      required this.mail,
      required this.createDate})
      : super(firstName, lastName, userID);

  // CurrentUser.create(
  //     {required this.mail,
  //     this.birthDate,
  //     String? firstName,
  //     String? lastName,
  //     this.biography})
  //     : createDate = DateTime.now(),
  //       isFirstLogin = false,
  //       super(firstName, lastName, Statics.getRandomId(30));

  ///
  @override
  factory YazApiUser.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserFromJson(json);

  ///
  @override
  Map<String, dynamic> toJson() => _$CurrentUserToJson(this);

  ///
  final DateTime createDate;

  ///user mail
  @JsonKey(name: 'user_mail', required: true, )
  String mail;

  // ///user address for purchase
  // @JsonKey(name: 'user_address', nullable: true, required: false)
  // UserAddress address;

  ///the session is first for this user
  @JsonKey(name: 'user_first_login', required: true, )
  bool isFirstLogin;

  ///User Age
  int get age => DateTime.now().year - birthDate!.year;

  ///User Bio
  @JsonKey(name: 'user_biography', defaultValue: '')
  String? biography;

  ///
  final DateTime? birthDate;

}



import 'user_model.dart';

part 'current_user.g.dart';

///Current User Class

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
  String mail;

  // ///user address for purchase
  // @JsonKey(name: 'user_address', nullable: true, required: false)
  // UserAddress address;

  ///the session is first for this user
  bool isFirstLogin;

  ///User Age
  int get age => DateTime.now().year - birthDate!.year;

  ///User Bio
  String? biography;

  ///
  final DateTime? birthDate;

}

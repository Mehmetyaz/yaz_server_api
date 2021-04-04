

part 'user_model.g.dart';

///Dikimall User

class YazApiUserFront {
  /// Default
  YazApiUserFront(this.firstName, this.lastName, this.userID);

  ///
  factory YazApiUserFront.fromJson(Map<String, dynamic> json) =>
      _$YazApiUserFromJson(json);

  ///
  Map<String, dynamic> toJson() => _$YazApiUserToJson(this);

  ///User First Name
  final String? firstName;

  ///User First Name
  final String? lastName;

  ///User ID
  final String? userID;

  ///User Full Name
  String get name => '$firstName $lastName';

  // ///Profile picture stored picture ID
  // @JsonKey(name: "user_profile_picture_id", defaultValue: "")
  // String profilePicture = '';

  // ///User Types
  // @JsonKey(name: 'user_types', nullable: true)
  // final List<UserType> types;

  @override
  String toString() {
    return '$firstName $lastName';
  }
}

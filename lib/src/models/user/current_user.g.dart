// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YazApiUser _$CurrentUserFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      requiredKeys: const ['user_id', 'user_mail', 'user_first_login']);
  return YazApiUser(
    json['user_first_name'] as String?,
    json['user_last_name'] as String?,
    json['user_id'] as String?,
    biography: json['user_biography'] as String? ?? '',
    birthDate: json['birth_date'] != null
        ? DateTime.fromMillisecondsSinceEpoch((json['birth_date'] as int?)!)
        : null,
    isFirstLogin: json['user_first_login'] as bool,
    mail: json['user_mail'] as String,
    createDate:
        DateTime.fromMillisecondsSinceEpoch((json['create_date'] as int?)!),
  );
}

Map<String, dynamic> _$CurrentUserToJson(YazApiUser instance) =>
    <String, dynamic>{
      'user_first_name': instance.firstName,
      'user_last_name': instance.lastName,
      'user_id': instance.userID,
      'create_date': instance.createDate.millisecondsSinceEpoch,
      'user_mail': instance.mail,
      'user_first_login': instance.isFirstLogin,
      'user_biography': instance.biography,
      'birth_date': instance.birthDate?.millisecondsSinceEpoch,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YazApiUserFront _$YazApiUserFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['user_id']);
  return YazApiUserFront(
    json['user_first_name'] as String?,
    json['user_last_name'] as String?,
    json['user_id'] as String?,
  );
}

Map<String, dynamic> _$YazApiUserToJson(YazApiUserFront instance) =>
    <String, dynamic>{
      'user_first_name': instance.firstName,
      'user_last_name': instance.lastName,
      'user_id': instance.userID,
    };

import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class UserOutDto {
  const UserOutDto({
    required this.id,
    required this.googleSub,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String googleSub;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserOutDto.fromJson(Map<String, dynamic> json) {
    return UserOutDto(
      id: json['id'] as String,
      googleSub: json['google_sub'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      googleSub: googleSub,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AccountSummaryResponseDto {
  const AccountSummaryResponseDto({
    required this.user,
    required this.activeSessions,
    required this.deviceOnline,
    required this.deviceLastSeenAt,
    required this.generatedAt,
  });

  final UserOutDto user;
  final int activeSessions;
  final bool deviceOnline;
  final DateTime? deviceLastSeenAt;
  final DateTime generatedAt;

  factory AccountSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return AccountSummaryResponseDto(
      user: UserOutDto.fromJson(json['user'] as Map<String, dynamic>),
      activeSessions: json['active_sessions'] as int,
      deviceOnline: json['device_online'] as bool? ?? false,
      deviceLastSeenAt: parseNullableDateTime(json['device_last_seen_at']),
      generatedAt: parseDateTime(json['generated_at']),
    );
  }

  AccountSummary toDomain() {
    return AccountSummary(
      user: user.toDomain(),
      activeSessions: activeSessions,
      deviceOnline: deviceOnline,
      deviceLastSeenAt: deviceLastSeenAt,
      generatedAt: generatedAt,
    );
  }
}

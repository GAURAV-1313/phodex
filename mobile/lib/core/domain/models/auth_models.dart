class UserProfile {
  const UserProfile({
    required this.id,
    required this.googleSub,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  final String id;
  final String googleSub;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}

import 'user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.role = UserRole.user,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    email: map['email'] as String,
    name: map['name'] as String?,
    avatarUrl: map['avatar_url'] as String?,
    role: UserRoleX.fromString(map['role'] as String?),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'name': name,
    'avatar_url': avatarUrl,
    'role': role.asString,
  };
}

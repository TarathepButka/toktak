// features/auth/domain/entities/user.dart

/// Pure domain entity — no JSON parsing, no Flutter imports.
/// This is the canonical User type used by use cases and BLoC.
class User {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
  });

  String get displayLabel => displayName ?? username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

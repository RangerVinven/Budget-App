class UserProfile {
  final String name;
  final String email;

  const UserProfile({
    required this.name,
    required this.email,
  });

  UserProfile copyWith({
    String? name,
    String? email,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
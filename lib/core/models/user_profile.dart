class UserProfile {
  final String? name;
  final String? username;
  final String? profileImagePath;

  const UserProfile({this.name, this.username, this.profileImagePath});

  UserProfile copyWith({
    String? name,
    String? username,
    String? profileImagePath,
    bool clearImagePath = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      profileImagePath: clearImagePath
          ? null
          : (profileImagePath ?? this.profileImagePath),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'profileImagePath': profileImagePath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      username: json['username'] as String?,
      profileImagePath: json['profileImagePath'] as String?,
    );
  }
}

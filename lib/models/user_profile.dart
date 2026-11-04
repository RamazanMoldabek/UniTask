class UserProfile {
  final int? id;
  final String fullName;
  final String university;
  final String email;

  const UserProfile({
    this.id,
    required this.fullName,
    required this.university,
    required this.email,
  });

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? university,
    String? email,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'full_name': fullName,
      'university': university,
      'email': email,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      fullName: map['full_name'] as String? ?? '',
      university: map['university'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }
}

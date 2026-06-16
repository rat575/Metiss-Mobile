class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? firstName;
  final String? lastName;

  UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.firstName,
    this.lastName,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json, String uid) {
    return UserEntity(
      id: uid,
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      name: json['firstName'] != null && json['lastName'] != null
          ? '${json['firstName']} ${json['lastName']}'
          : json['firstName'] ?? json['lastName'],
    );
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

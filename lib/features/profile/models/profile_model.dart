class ProfileModel {
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String jobTitle;
  final String phone;
  final String communicationPreference;
  final List<String> permissions;
  final String status;

  ProfileModel({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.jobTitle,
    required this.phone,
    required this.communicationPreference,
    required this.permissions,
    required this.status,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uuid: json['uuid'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      phone: json['phone'] ?? '',
      communicationPreference: json['communicationPreference'] ?? 'EMAIL',
      permissions: List<String>.from(json['permissions'] ?? []),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'jobTitle': jobTitle,
      'phone': phone,
      'communicationPreference': communicationPreference,
      'permissions': permissions,
      'status': status,
    };
  }

  ProfileModel copyWith({
    String? uuid,
    String? firstName,
    String? lastName,
    String? email,
    String? jobTitle,
    String? phone,
    String? communicationPreference,
    List<String>? permissions,
    String? status,
  }) {
    return ProfileModel(
      uuid: uuid ?? this.uuid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      jobTitle: jobTitle ?? this.jobTitle,
      phone: phone ?? this.phone,
      communicationPreference:
          communicationPreference ?? this.communicationPreference,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
    );
  }
}

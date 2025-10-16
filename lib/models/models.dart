class User {
  final int id;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final String? profileImageBase64;
  final Role role;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.profileImageBase64,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      profileImageUrl: json['profile_image_url'],
      profileImageBase64: json['profile_image_base64'],
      role: Role.fromJson(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'profile_image_base64': profileImageBase64,
      'role_id': role.id,
    };
  }
}

class UserCreate {
  final String email;
  final String password;
  final String? fullName;
  final String? profileImageUrl;
  final String? profileImageBase64;
  final int roleId;

  UserCreate({
    required this.email,
    required this.password,
    this.fullName,
    this.profileImageUrl,
    this.profileImageBase64,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'profile_image_base64': profileImageBase64,
      'role_id': roleId,
    };
  }
}

class UserUpdate {
  final String? email;
  final String? password;
  final String? fullName;
  final String? profileImageUrl;
  final String? profileImageBase64;
  final int? roleId;

  UserUpdate({
    this.email,
    this.password,
    this.fullName,
    this.profileImageUrl,
    this.profileImageBase64,
    this.roleId,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (email != null) json['email'] = email;
    if (password != null) json['password'] = password;
    if (fullName != null) json['full_name'] = fullName;
    if (profileImageUrl != null) json['profile_image_url'] = profileImageUrl;
    if (profileImageBase64 != null)
      json['profile_image_base64'] = profileImageBase64;
    if (roleId != null) json['role_id'] = roleId;
    return json;
  }
}

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class RoleCreate {
  final String name;

  RoleCreate({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

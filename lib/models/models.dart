import 'package:flutter/foundation.dart';

// --- MODELOS DE USER E ROLE (Existentes) ---

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
      'role': role.toJson(),
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
  final String? fullName;
  final String? profileImageUrl;
  final String? profileImageBase64;
  // --- MUDANÇA ---
  // A API não permite atualizar email, senha ou role por este endpoint
  // Vamos manter o modelo simples como está no seu código
  UserUpdate({
    this.fullName,
    this.profileImageUrl,
    this.profileImageBase64,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (fullName != null) json['full_name'] = fullName;
    if (profileImageUrl != null) json['profile_image_url'] = profileImageUrl;
    if (profileImageBase64 != null) {
      json['profile_image_base64'] = profileImageBase64;
    }
    // Removemos email, password e roleId para corresponder ao seu backend
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


// --- NOVOS MODELOS (Vakinha e Contribution) ---

class Contribution {
  final int id;
  final double amount;
  final DateTime createdAt;
  final String? proofBase64;
  final User user; // Usuário que pagou

  Contribution({
    required this.id,
    required this.amount,
    required this.createdAt,
    this.proofBase64,
    required this.user,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      amount: json['amount'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      proofBase64: json['proof_base64'],
      user: User.fromJson(json['user']),
    );
  }
}

class Vakinha {
  final int id;
  final String name;
  final DateTime createdAt;
  final String status; // "open" ou "closed"
  final String fetcherName;
  final String fetcherPhone;
  final User createdBy; // Admin que criou
  final DateTime? closedAt;
  final double? amountSpent;
  final double? amountLeftover;
  final List<Contribution> contributions;

  Vakinha({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.status,
    required this.fetcherName,
    required this.fetcherPhone,
    required this.createdBy,
    this.closedAt,
    this.amountSpent,
    this.amountLeftover,
    required this.contributions,
  });

  factory Vakinha.fromJson(Map<String, dynamic> json) {
    var contributionsList = json['contributions'] as List;
    List<Contribution> contributions = contributionsList
        .map((i) => Contribution.fromJson(i))
        .toList();

    return Vakinha(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
      fetcherName: json['fetcher_name'],
      fetcherPhone: json['fetcher_phone'],
      createdBy: User.fromJson(json['created_by']),
      closedAt: json['closed_at'] != null 
                ? DateTime.parse(json['closed_at']) 
                : null,
      amountSpent: json['amount_spent']?.toDouble(),
      amountLeftover: json['amount_leftover']?.toDouble(),
      contributions: contributions,
    );
  }

  // Helper para calcular o total arrecadado
  double get totalCollected {
    if (contributions.isEmpty) return 0.0;
    return contributions.map((c) => c.amount).reduce((a, b) => a + b);
  }
}

// --- Modelos para FORMS (Create/Close) ---

class VakinhaCreate {
  final String? name;
  final String fetcherName;
  final String fetcherPhone;

  VakinhaCreate({this.name, required this.fetcherName, required this.fetcherPhone});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fetcher_name': fetcherName,
      'fetcher_phone': fetcherPhone,
    };
  }
}

class VakinhaClose {
  final double amountSpent;
  final double amountLeftover;

  VakinhaClose({required this.amountSpent, required this.amountLeftover});

  Map<String, dynamic> toJson() {
    return {
      'amount_spent': amountSpent,
      'amount_leftover': amountLeftover,
    };
  }
}

class ContributionCreate {
  final double amount;
  final String? proofBase64;

  ContributionCreate({required this.amount, this.proofBase64});

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'proof_base64': proofBase64,
    };
  }
}
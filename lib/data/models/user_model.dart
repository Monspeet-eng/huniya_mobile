class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
  });

  bool get isOwner => role == 'owner';
  bool get isUser => role == 'user';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }
}

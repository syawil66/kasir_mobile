class UserModel {
  final String id;
  final String username;
  final String name;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      name: map['name'] ?? 'Pengguna',
      role: map['role'] ?? 'kasir',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'role': role,
    };
  }
}
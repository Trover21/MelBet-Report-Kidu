
enum UserRole { admin, employee }

class AppUser {
  final String id;
  final String name;
  final String username;
  final String passwordHash; // bcrypt hash in production
  final UserRole role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        passwordHash: json['passwordHash'] as String,
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.employee,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'passwordHash': passwordHash,
        'role': role == UserRole.admin ? 'admin' : 'employee',
        'isActive': isActive,
      };

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
}

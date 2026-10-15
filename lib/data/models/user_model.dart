
enum UserRole { admin, manager, employee }

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.employee:
        return 'employee';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }

  /// Manager has the same UI privileges as admin
  bool get isPrivileged => this == UserRole.admin || this == UserRole.manager;

  static UserRole fromValue(String v) {
    switch (v) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.employee;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String username;
  final String passwordHash; // only used in mock; API never returns this
  final UserRole role;
  final bool isActive;
  final String? email;
  final bool isApproved;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    this.passwordHash = '',
    required this.role,
    this.isActive = true,
    this.email,
    this.isApproved = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        name: json['name'] as String,
        username: json['username'] as String,
        passwordHash: json['passwordHash'] as String? ?? '',
        role: UserRoleExt.fromValue(json['role'] as String? ?? 'employee'),
        isActive: json['isActive'] as bool? ?? true,
        email: json['email'] as String?,
        isApproved: json['isApproved'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'passwordHash': passwordHash,
        'role': role.value,
        'isActive': isActive,
        'email': email,
        'isApproved': isApproved,
      };

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
    String? email,
    bool? isApproved,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        email: email ?? this.email,
        isApproved: isApproved ?? this.isApproved,
      );
}

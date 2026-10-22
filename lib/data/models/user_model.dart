
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

  String get name => value;

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
  final int teamNumber; // legacy compatibility
  final String teamName; // primary team name (e.g. "Team 1" or custom)
  final List<String> teams; // teams accessible (especially for managers who manage multiple teams)

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    this.passwordHash = '',
    required this.role,
    this.isActive = true,
    this.email,
    this.isApproved = true,
    this.teamNumber = 1,
    this.teamName = 'Team 1',
    this.teams = const ['Team 1'],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final legacyNum = (json['teamNumber'] as num?)?.toInt() ?? 1;
    final parsedTeamName = json['teamName'] as String? ?? 'Team $legacyNum';
    final parsedTeams = (json['teams'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [parsedTeamName];

    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: json['name'] as String,
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String? ?? '',
      role: UserRoleExt.fromValue(json['role'] as String? ?? 'employee'),
      isActive: json['isActive'] as bool? ?? true,
      email: json['email'] as String?,
      isApproved: json['isApproved'] as bool? ?? true,
      teamNumber: legacyNum,
      teamName: parsedTeamName,
      teams: parsedTeams.isNotEmpty ? parsedTeams : [parsedTeamName],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'passwordHash': passwordHash,
        'role': role.value,
        'isActive': isActive,
        'email': email,
        'isApproved': isApproved,
        'teamNumber': teamNumber,
        'teamName': teamName,
        'teams': teams,
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
    int? teamNumber,
    String? teamName,
    List<String>? teams,
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
        teamNumber: teamNumber ?? this.teamNumber,
        teamName: teamName ?? this.teamName,
        teams: teams ?? this.teams,
      );
}

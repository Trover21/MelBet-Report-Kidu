class TeamRequest {
  final String id;
  final String userId;
  final String userName;
  final List<String> requestedTeams;
  final String reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const TeamRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.requestedTeams,
    this.reason = '',
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory TeamRequest.fromJson(Map<String, dynamic> json) => TeamRequest(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        userId: (json['userId'] ?? '') as String,
        userName: (json['userName'] ?? '') as String,
        requestedTeams: (json['requestedTeams'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        reason: (json['reason'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        reviewedBy: json['reviewedBy'] as String?,
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.tryParse(json['reviewedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'requestedTeams': requestedTeams,
        'reason': reason,
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

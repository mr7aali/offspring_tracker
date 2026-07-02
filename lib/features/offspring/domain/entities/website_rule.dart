class WebsiteRule {
  const WebsiteRule({
    required this.id,
    required this.deviceId,
    required this.domain,
    required this.includesSubdomains,
    required this.isBlocked,
    required this.blockedAttempts,
    required this.createdAt,
  });

  final String id;
  final String deviceId;
  final String domain;
  final bool includesSubdomains;
  final bool isBlocked;
  final int blockedAttempts;
  final DateTime createdAt;

  WebsiteRule copyWith({
    String? id,
    String? deviceId,
    String? domain,
    bool? includesSubdomains,
    bool? isBlocked,
    int? blockedAttempts,
    DateTime? createdAt,
  }) {
    return WebsiteRule(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      domain: domain ?? this.domain,
      includesSubdomains: includesSubdomains ?? this.includesSubdomains,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

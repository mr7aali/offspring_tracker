class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.deviceLimit,
    required this.advancedReports,
    required this.websiteBlocking,
    required this.protectedMode,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final String priceLabel;
  final int deviceLimit;
  final bool advancedReports;
  final bool websiteBlocking;
  final bool protectedMode;
  final bool isCurrent;

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? priceLabel,
    int? deviceLimit,
    bool? advancedReports,
    bool? websiteBlocking,
    bool? protectedMode,
    bool? isCurrent,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      priceLabel: priceLabel ?? this.priceLabel,
      deviceLimit: deviceLimit ?? this.deviceLimit,
      advancedReports: advancedReports ?? this.advancedReports,
      websiteBlocking: websiteBlocking ?? this.websiteBlocking,
      protectedMode: protectedMode ?? this.protectedMode,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

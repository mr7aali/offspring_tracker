import '../../domain/entities/website_rule.dart';

class WebsiteRuleModel extends WebsiteRule {
  const WebsiteRuleModel({
    required super.id,
    required super.deviceId,
    required super.domain,
    required super.includesSubdomains,
    required super.isBlocked,
    required super.blockedAttempts,
    required super.createdAt,
  });

  factory WebsiteRuleModel.fromEntity(WebsiteRule rule) {
    return WebsiteRuleModel(
      id: rule.id,
      deviceId: rule.deviceId,
      domain: rule.domain,
      includesSubdomains: rule.includesSubdomains,
      isBlocked: rule.isBlocked,
      blockedAttempts: rule.blockedAttempts,
      createdAt: rule.createdAt,
    );
  }
}

import '../entities/website_rule.dart';
import '../repositories/offspring_repository.dart';

class AddWebsiteRuleUseCase {
  const AddWebsiteRuleUseCase(this._repository);

  final OffspringRepository _repository;

  Future<WebsiteRule> call({
    required String deviceId,
    required String domain,
    required bool includesSubdomains,
  }) {
    return _repository.addWebsiteRule(
      deviceId: deviceId,
      domain: domain,
      includesSubdomains: includesSubdomains,
    );
  }
}

class ToggleWebsiteRuleUseCase {
  const ToggleWebsiteRuleUseCase(this._repository);

  final OffspringRepository _repository;

  Future<WebsiteRule> call({required String ruleId, required bool isBlocked}) {
    return _repository.updateWebsiteRule(ruleId: ruleId, isBlocked: isBlocked);
  }
}

class RemoveWebsiteRuleUseCase {
  const RemoveWebsiteRuleUseCase(this._repository);

  final OffspringRepository _repository;

  Future<void> call(String ruleId) {
    return _repository.removeWebsiteRule(ruleId);
  }
}

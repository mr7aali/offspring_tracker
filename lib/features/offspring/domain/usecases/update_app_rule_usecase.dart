import '../entities/tracked_app.dart';
import '../repositories/offspring_repository.dart';

class UpdateAppRuleUseCase {
  const UpdateAppRuleUseCase(this._repository);

  final OffspringRepository _repository;

  Future<TrackedApp> call({
    required String appId,
    bool? isBlocked,
    int? dailyLimitMinutes,
  }) {
    return _repository.updateAppRule(
      appId: appId,
      isBlocked: isBlocked,
      dailyLimitMinutes: dailyLimitMinutes,
    );
  }
}

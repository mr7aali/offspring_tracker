import '../entities/subscription_plan.dart';
import '../repositories/offspring_repository.dart';

class SelectSubscriptionPlanUseCase {
  const SelectSubscriptionPlanUseCase(this._repository);

  final OffspringRepository _repository;

  Future<SubscriptionPlan> call(String planId) {
    return _repository.selectPlan(planId);
  }
}

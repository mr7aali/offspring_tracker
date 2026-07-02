import '../repositories/offspring_repository.dart';

class MarkNotificationsReadUseCase {
  const MarkNotificationsReadUseCase(this._repository);

  final OffspringRepository _repository;

  Future<void> call() {
    return _repository.markNotificationsRead();
  }
}

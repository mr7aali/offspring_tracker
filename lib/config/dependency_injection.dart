import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/offspring/data/datasources/offspring_local_datasource.dart';
import '../features/offspring/data/repositories/offspring_repository_impl.dart';
import '../features/offspring/domain/usecases/load_dashboard_usecase.dart';
import '../features/offspring/domain/usecases/manage_notifications_usecase.dart';
import '../features/offspring/domain/usecases/manage_subscription_usecase.dart';
import '../features/offspring/domain/usecases/pair_child_device_usecase.dart';
import '../features/offspring/domain/usecases/update_app_rule_usecase.dart';
import '../features/offspring/domain/usecases/update_website_rule_usecase.dart';
import '../features/offspring/presentation/controllers/dashboard_controller.dart';
import '../shared/services/notification_service.dart';
import 'env.dart';

late AppDependencies appDependencies;

void setupDependencies() {
  final authDataSource = AuthLocalDataSource();
  final authRepository = AuthRepositoryImpl(authDataSource);

  final offspringDataSource = OffspringLocalDataSource();
  final offspringRepository = OffspringRepositoryImpl(offspringDataSource);

  appDependencies = AppDependencies(
    appMode: Env.appMode,
    notificationService: const NotificationService(),
    authController: AuthController(
      LoginUseCase(authRepository),
      RegisterUseCase(authRepository),
      LogoutUseCase(authRepository),
    ),
    dashboardController: DashboardController(
      LoadDashboardUseCase(offspringRepository),
      PairChildDeviceUseCase(offspringRepository),
      UpdateAppRuleUseCase(offspringRepository),
      AddWebsiteRuleUseCase(offspringRepository),
      ToggleWebsiteRuleUseCase(offspringRepository),
      RemoveWebsiteRuleUseCase(offspringRepository),
      MarkNotificationsReadUseCase(offspringRepository),
      SelectSubscriptionPlanUseCase(offspringRepository),
    ),
  );
}

class AppDependencies {
  const AppDependencies({
    required this.appMode,
    required this.notificationService,
    required this.authController,
    required this.dashboardController,
  });

  final String appMode;
  final NotificationService notificationService;
  final AuthController authController;
  final DashboardController dashboardController;
}

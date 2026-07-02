import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_snapshot.dart';
import '../../domain/entities/alert_notification.dart';
import '../../domain/entities/child_device.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/tracked_app.dart';
import '../../domain/entities/website_rule.dart';
import '../../domain/usecases/load_dashboard_usecase.dart';
import '../../domain/usecases/manage_notifications_usecase.dart';
import '../../domain/usecases/manage_subscription_usecase.dart';
import '../../domain/usecases/pair_child_device_usecase.dart';
import '../../domain/usecases/update_app_rule_usecase.dart';
import '../../domain/usecases/update_website_rule_usecase.dart';

enum DashboardSection { overview, apps, websites, reports, alerts, admin }

class DashboardController extends ChangeNotifier {
  DashboardController(
    this._loadDashboardUseCase,
    this._pairChildDeviceUseCase,
    this._updateAppRuleUseCase,
    this._addWebsiteRuleUseCase,
    this._toggleWebsiteRuleUseCase,
    this._removeWebsiteRuleUseCase,
    this._markNotificationsReadUseCase,
    this._selectSubscriptionPlanUseCase,
  );

  final LoadDashboardUseCase _loadDashboardUseCase;
  final PairChildDeviceUseCase _pairChildDeviceUseCase;
  final UpdateAppRuleUseCase _updateAppRuleUseCase;
  final AddWebsiteRuleUseCase _addWebsiteRuleUseCase;
  final ToggleWebsiteRuleUseCase _toggleWebsiteRuleUseCase;
  final RemoveWebsiteRuleUseCase _removeWebsiteRuleUseCase;
  final MarkNotificationsReadUseCase _markNotificationsReadUseCase;
  final SelectSubscriptionPlanUseCase _selectSubscriptionPlanUseCase;

  DashboardSection _section = DashboardSection.overview;
  List<ChildDevice> _devices = [];
  ChildDevice? _selectedDevice;
  List<TrackedApp> _apps = [];
  List<WebsiteRule> _websiteRules = [];
  List<AlertNotification> _notifications = [];
  List<SubscriptionPlan> _subscriptionPlans = [];
  DashboardSummary? _summary;
  AdminSnapshot? _adminSnapshot;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSection get section => _section;
  List<ChildDevice> get devices => _devices;
  ChildDevice? get selectedDevice => _selectedDevice;
  List<TrackedApp> get apps => _apps;
  List<WebsiteRule> get websiteRules => _websiteRules;
  List<AlertNotification> get notifications => _notifications;
  List<SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  DashboardSummary? get summary => _summary;
  AdminSnapshot? get adminSnapshot => _adminSnapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({String? selectedDeviceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _loadDashboardUseCase(
        selectedDeviceId: selectedDeviceId ?? _selectedDevice?.id,
      );
      _devices = data.devices;
      _selectedDevice = data.selectedDevice;
      _apps = data.apps;
      _websiteRules = data.websiteRules;
      _notifications = data.notifications;
      _summary = data.summary;
      _adminSnapshot = data.adminSnapshot;
      _subscriptionPlans = data.subscriptionPlans;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
    } catch (_) {
      _errorMessage = 'Unable to load dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void showSection(DashboardSection section) {
    _section = section;
    notifyListeners();
  }

  Future<void> selectDevice(String deviceId) {
    return load(selectedDeviceId: deviceId);
  }

  Future<void> pairDevice({
    required String childName,
    required String deviceName,
    required String pairingCode,
  }) async {
    await _runMutation(() async {
      final device = await _pairChildDeviceUseCase(
        childName: childName,
        deviceName: deviceName,
        pairingCode: pairingCode,
      );
      await load(selectedDeviceId: device.id);
    });
  }

  Future<void> toggleAppBlock(TrackedApp app, bool isBlocked) async {
    await _runMutation(() async {
      await _updateAppRuleUseCase(appId: app.id, isBlocked: isBlocked);
      await load();
    });
  }

  Future<void> updateAppLimit(TrackedApp app, int dailyLimitMinutes) async {
    await _runMutation(() async {
      await _updateAppRuleUseCase(
        appId: app.id,
        dailyLimitMinutes: dailyLimitMinutes,
      );
      await load();
    });
  }

  Future<void> addWebsiteRule({
    required String domain,
    required bool includesSubdomains,
  }) async {
    final deviceId = _selectedDevice?.id;
    if (deviceId == null) {
      return;
    }

    await _runMutation(() async {
      await _addWebsiteRuleUseCase(
        deviceId: deviceId,
        domain: domain,
        includesSubdomains: includesSubdomains,
      );
      await load();
    });
  }

  Future<void> toggleWebsiteRule(WebsiteRule rule, bool isBlocked) async {
    await _runMutation(() async {
      await _toggleWebsiteRuleUseCase(ruleId: rule.id, isBlocked: isBlocked);
      await load();
    });
  }

  Future<void> removeWebsiteRule(WebsiteRule rule) async {
    await _runMutation(() async {
      await _removeWebsiteRuleUseCase(rule.id);
      await load();
    });
  }

  Future<void> markNotificationsRead() async {
    await _runMutation(() async {
      await _markNotificationsReadUseCase();
      await load();
    });
  }

  Future<void> selectSubscriptionPlan(String planId) async {
    await _runMutation(() async {
      await _selectSubscriptionPlanUseCase(planId);
      await load();
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
    } catch (_) {
      _errorMessage = 'Unable to save changes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

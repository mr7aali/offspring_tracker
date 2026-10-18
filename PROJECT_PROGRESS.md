# Offspring Tracker — Project Progress

Updated: October 19, 2026

## Overall status

**Current stage: functional Flutter frontend demo with in-memory data.**

The project supports parent and child navigation, demo authentication, same-session device pairing, and local rule management. The interface covers much of the intended product, but real remote monitoring and parental-control enforcement are not implemented.

This report is based on repository inspection and checks run during the project review. It distinguishes implemented demo behavior from production functionality. No percentage is assigned because the project does not yet have a weighted delivery plan or acceptance criteria.

## Feature progress

| Area | Implemented | Remaining work | Status |
|---|---|---|---|
| App foundation | Flutter entry point, Material theme, routes, shared widgets, manual dependency injection | Production environment configuration and release setup | Foundation implemented |
| Parent authentication | Registration, login, validation, demo account, logout | Backend authentication, persistent sessions, secure credential handling, route protection | Local demo |
| Child connection | Code-only setup, generated pairing codes, validation, connection confirmation | Cross-device pairing, expiring/single-use invitations, authenticated device sessions | Same-session demo |
| Parent dashboard | Device selection, overview, app rules, websites, reports, alerts, settings | Account-scoped data, real synchronization and telemetry | Demo implemented |
| Child dashboard | Device-specific overview, app limits, website rules, alerts and device information | Persistent connection and live device state | Demo implemented |
| Device management | Seeded devices and adding a device through the pairing flow | Actual device enrollment, ownership, heartbeat and permission detection | Local demo |
| Installed apps | Seeded app list, names, packages and categories | Native installed-app discovery and updates | Mock data |
| Usage tracking | Daily/weekly values and report presentation | Native usage collection, history storage and daily reset logic | Mock data |
| App rules | Local block/unblock and daily-limit edits | Remote delivery, offline storage and device-side enforcement | Local demo |
| Website rules | Add, toggle and delete domain rules | ID collision fix, remote synchronization and native filtering | Local demo with verified bug |
| Alerts | Seeded and locally generated records, mark-read action | Real event detection, push/local notification delivery | Local demo |
| Subscription | Plan definitions and local plan selection | Billing, account entitlements and limit enforcement | Local demo |
| Support tickets | Ticket creation, filtering and status changes | Backend storage, account isolation and support workflow | Local demo |
| Account deletion | Information screen and demo acknowledgement | Verified deletion workflow and actual data removal | Placeholder action |
| Protected mode | Status presentation | Native implementation and device validation | Not implemented |

## Architecture progress

The main application follows a feature-based layered structure:

```text
Screens and widgets
  → ChangeNotifier controllers
  → Domain use cases
  → Repository interfaces and implementations
  → In-memory data sources
```

- `lib/features/auth`: parent authentication and child setup entry screens.
- `lib/features/offspring`: dashboards, devices, rules, reports and related screens.
- `lib/core`: theme, constants, routes, validation and network placeholders.
- `lib/shared`: shared widgets and notification-service placeholder.
- `lib/config`: active dependency injection and environment configuration.

Repository boundaries provide a starting point for replacing demo data with persistent services. Several use cases currently delegate directly to repositories; production validation and authorization still need to be designed.

## Verification results

Checks performed during the October 19, 2026 review:

| Check | Result | Notes |
|---|---|---|
| `flutter test` | 4 passed, 1 failed | Parent-generated pairing flow test uses an outdated button label |
| `flutter analyze` | 4 findings; nonzero exit | 2 warnings and 2 deprecation notices |
| Website-rule ID reproduction | Bug confirmed | Deleting a newly added rule can also delete another device's rule |
| Zero-usage report calculation | Bug confirmed | Zero divided by zero clamps to a full progress value |
| Native release builds | Not run | Release packaging is not verified |
| Physical-device monitoring/enforcement | Not tested | Native capabilities are not implemented |

Existing widget tests cover role selection, demo parent entry, demo child navigation, invalid child codes, and an attempted parent-to-child pairing flow. Coverage does not yet establish correctness for account isolation, rule mutations, billing, persistence or native services.

## Verified issues and priorities

### 1. Website-rule ID collision — high priority

Source: `lib/features/offspring/data/datasources/offspring_local_datasource.dart`

Rule IDs use the current list length. Removing `website-1` and adding a rule creates another `website-3`, which already belongs to another device. Deleting the new rule removes both matching records. Updating a duplicate ID can also target the wrong record.

**Next action:** generate stable unique IDs and add a regression test for delete/add/update operations across devices.

### 2. Parent account isolation and route protection — required before production

Sources: `lib/config/dependency_injection.dart`, `lib/core/routes/app_routes.dart`, and `lib/features/offspring/presentation/screens/dashboard_screen.dart`

All parent accounts share the offspring data source. Signing out does not reset dashboard data. Support tickets also use a global list without parent filtering. The parent dashboard route does not check authentication before building.

**Next action:** introduce parent ownership, scope reads and writes to the active account, reset session state appropriately, and guard protected routes. Backend authorization must enforce these boundaries independently of the UI.

### 3. Zero-usage report bars — medium priority

Source: `lib/features/offspring/presentation/widgets/dashboard/dashboard_sections.dart`

Newly paired devices have zero weekly usage. The report divides by a zero maximum, producing a value that clamps to `1.0`, so empty usage appears as a full bar.

**Next action:** return zero progress when the maximum usage is zero.

### 4. Failing pairing test — medium priority

Sources: `test/widget_test.dart` and `lib/features/offspring/presentation/widgets/pair_child_device_dialog.dart`

The test searches for `Generate pairing code`, but the button now reads `Generate code`. The test stops before completing the flow; this failure alone does not demonstrate a pairing implementation failure.

**Next action:** update the finder, preferably using a stable widget key, and rerun the complete flow.

### 5. Subscription rules are not enforced — required before paid release

Plan device limits and feature flags are displayed, but do not restrict pairing or rule operations. New parent accounts are marked Free while the shared offspring data source starts on Premium.

**Next action:** establish one account-scoped entitlement source and enforce limits in the service layer.

### 6. Analyzer findings — cleanup

- Unused `colors` variable in `dashboard_rule_cards.dart`.
- Two deprecated `activeColor` usages in `dashboard_rule_cards.dart`.
- Unreferenced `_AdminPlansSection` in `dashboard_sections.dart`.

**Next action:** resolve the four findings and make static analysis pass.

## Production capabilities still required

- Persistent backend and parent/device ownership model.
- Secure authentication and session lifecycle; demo passwords currently live as plain strings in memory.
- Cross-phone pairing and authenticated synchronization.
- Native installed-app discovery and usage tracking.
- Device-side app restriction and website filtering.
- Background operation, permission handling and real online/offline reporting.
- Offline rule storage and synchronization recovery.
- Real notifications, billing and support storage.
- Actual account/data deletion.
- Release signing and application identity; Android currently uses `com.example.offspring_tracker` and debug signing for release.

The current network client contains only a base URL, the notification service is a no-op, and Android's entry point is a standard `FlutterActivity`. Platform project folders should not be treated as evidence that parental-control capabilities work on those platforms.

## Maintainability work

- Split the 2,527-line child dashboard into focused widgets and sections.
- Reduce shared private scope across the parent dashboard's many `part` files.
- Move support-ticket state and operations out of presentation code.
- Remove or explain the empty root `config` files; active configuration is under `lib/config`.
- Replace the generic README with setup instructions, demo credentials, supported flows, limitations and verification commands.
- Expand tests around account switching, rule mutations, zero-data reports and failure handling.

## Proposed delivery sequence

These milestones are recommendations, not committed dates.

1. **Stabilize the demo:** fix rule IDs, zero-usage reports, the pairing test and analyzer findings. Exit criteria: all existing tests and static analysis pass, with regression coverage for the confirmed bugs.
2. **Build the account and data foundation:** implement authentication, persistence, parent ownership, protected navigation and session cleanup. Exit criteria: accounts cannot read or modify one another's data, and state survives restart.
3. **Implement real device connectivity:** add secure enrollment, cross-device rule synchronization and device status. Exit criteria: separate parent and child devices exchange authenticated updates.
4. **Implement native monitoring and enforcement:** collect actual usage, apply supported restrictions and filtering, and handle offline/background behavior. Exit criteria: behavior is validated on physical devices, including permission loss and restart scenarios.
5. **Prepare for release:** finish entitlements/billing, notifications, support and deletion; configure release identity/signing; broaden automated and device testing.

## Current release assessment

Suitable for demonstrating UI and local workflows. Not ready to provide real remote monitoring, enforce parental controls, or serve multiple families with isolated persistent data.

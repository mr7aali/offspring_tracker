# Offspring Tracker — Project Progress

Updated: October 19, 2026

**Backend decision: Supabase has been selected by the project owner. Integration has not started.**

Task legend: `[x]` = implemented or explicitly decided within the stated scope; `[ ]` = unfinished. A completed demo task does not mean its production equivalent is complete. Validation results below are from the last implementation run, not a new run for this documentation update.

## Overall status

**Current stage: functional Flutter demo with native Android installed-app discovery and in-memory data.**

The project supports parent and child navigation, demo authentication, same-session device pairing, local rule management, and native discovery of launchable apps on the child Android phone. Real remote synchronization, usage monitoring and parental-control enforcement are not implemented.

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
| Installed apps | Native Android launcher-app discovery, names, package IDs, available categories; refresh on entry, resume, package changes and manual action | Physical-device validation, persistent storage and cross-phone synchronization | Implemented locally on Android |
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

Checks performed during the October 19, 2026 review and installed-app implementation:

| Check | Result | Notes |
|---|---|---|
| `flutter test` | 12 passed | Includes reconciliation, channel failures, lifecycle/package refresh, demo isolation and corrected pairing flow |
| `flutter analyze` | 4 findings; nonzero exit | 2 warnings and 2 deprecation notices |
| Website-rule ID reproduction | Bug confirmed | Deleting a newly added rule can also delete another device's rule |
| Zero-usage report calculation | Fixed | Zero maximum now produces zero progress |
| `flutter build apk --debug` | Passed | Kotlin bridge and manifest compiled into the debug APK |
| Native release builds | Not run | Release packaging is not verified |
| Physical-device monitoring/enforcement | Not tested | Native capabilities are not implemented |

Tests cover role selection, demo parent entry, demo child navigation, invalid child codes and the completed parent-to-child pairing flow. New tests verify inventory reconciliation, rule preservation, device isolation, duplicate handling, removal, empty results, failed scans, category fallback, package events, resume refresh and explicit demo isolation. Native channel responses are mocked in Flutter tests; real Android package events still need physical-device validation.

## Installed-app discovery implementation

- Android `PackageManager` discovers enabled launcher apps in the current user/profile, excluding Offspring Tracker itself. This is not an inventory of every background/system package or other Android profiles.
- A method channel reads metadata off the Android UI thread. An event channel observes package installation, removal, replacement and changes while the child dashboard is listening.
- Child dashboard entry, resume and manual refresh also rescan, catching changes made while the app was inactive.
- Inventory reconciliation uses package IDs, preserves existing limits/block rules for retained apps, updates labels/categories, removes absent apps and generates an in-app alert for additions after the initial scan.
- The first native scan clears seeded usage values. New apps have zero usage and an unknown last-opened time; app discovery does not provide usage telemetry.
- Android supplies available categories. Unmapped categories use System for system apps or Other; browser and education categories are not inferred from package-name guesses.
- Failed scans retain the previous list and display a retry message. Empty successful results clear the device inventory.
- `Try demo connection` retains seeded data. Unsupported platforms also retain the demo inventory. Parent dashboard navigation alone never scans the parent's phone.
- App lists and rules remain in memory. A separate parent phone cannot receive the inventory until backend synchronization is implemented.

### How to try it

1. Install/run the Android build on a test phone.
2. Generate a pairing code in the parent flow, then sign out in the same app session.
3. Choose Connect child device, enter that code and continue to the child dashboard. Do not use Try demo connection when testing native discovery.
4. Open Apps to inspect the phone's launcher apps. Install/uninstall a test app, then return to Offspring Tracker or tap Refresh child device.
5. Switch back to the parent flow in the same session to inspect rules for that child device. Restarting the app resets the demo connection and in-memory records.

Implementation references: [Android package visibility](https://developer.android.com/training/package-visibility/declaring) and [ApplicationInfo categories](https://developer.android.com/reference/android/content/pm/ApplicationInfo).

## Verified issues and priorities

### 1. Website-rule ID collision — high priority

Source: `lib/features/offspring/data/datasources/offspring_local_datasource.dart`

Rule IDs use the current list length. Removing `website-1` and adding a rule creates another `website-3`, which already belongs to another device. Deleting the new rule removes both matching records. Updating a duplicate ID can also target the wrong record.

**Next action:** generate stable unique IDs and add a regression test for delete/add/update operations across devices.

### 2. Parent account isolation and route protection — required before production

Sources: `lib/config/dependency_injection.dart`, `lib/core/routes/app_routes.dart`, and `lib/features/offspring/presentation/screens/dashboard_screen.dart`

All parent accounts share the offspring data source. Signing out does not reset dashboard data. Support tickets also use a global list without parent filtering. The parent dashboard route does not check authentication before building.

**Next action:** introduce parent ownership, scope reads and writes to the active account, reset session state appropriately, and guard protected routes. Backend authorization must enforce these boundaries independently of the UI.

### 3. Zero-usage report bars — resolved

Source: `lib/features/offspring/presentation/widgets/dashboard/dashboard_sections.dart`

Newly paired devices have zero weekly usage. The report divides by a zero maximum, producing a value that clamps to `1.0`, so empty usage appears as a full bar.

**Completed:** report bars return zero progress when the maximum usage is zero, which is necessary for newly discovered apps without usage telemetry.

### 4. Failing pairing test — resolved

Sources: `test/widget_test.dart` and `lib/features/offspring/presentation/widgets/pair_child_device_dialog.dart`

The test searches for `Generate pairing code`, but the button now reads `Generate code`. The test stops before completing the flow; this failure alone does not demonstrate a pairing implementation failure.

**Completed:** added a stable generate-button key, corrected the navigation-menu selector and verified the complete flow in the passing test suite.

### 5. Subscription rules are not enforced — required before paid release

Plan device limits and feature flags are displayed, but do not restrict pairing or rule operations. New parent accounts are marked Free while the shared offspring data source starts on Premium.

**Next action:** establish one account-scoped entitlement source and enforce limits in the service layer.

### 6. Analyzer findings — cleanup

- Unused `colors` variable in `dashboard_rule_cards.dart`.
- Two deprecated `activeColor` usages in `dashboard_rule_cards.dart`.
- Unreferenced `_AdminPlansSection` in `dashboard_sections.dart`.

**Next action:** resolve the four findings and make static analysis pass.

## Target architecture and scope

The completion checklist covers the features in `Offspring Tracker.md`, including the proposed admin panel, subscriptions and protected mode. Those larger features may ship in later releases, but are not marked complete or silently excluded.

Recommended first release target: Android child device and Flutter parent experience. The exact supported parent platforms, Android versions and device-management modes still need a decision. Existing iOS, web and desktop folders do not establish feature parity.

```text
Parent Flutter app -> Supabase Auth + authorized database/API -> saved rules
Child Android discovery/services -> local database + upload queue -> Supabase
Saved rules -> child synchronization -> local enforcement -> applied-version acknowledgement
Parent dashboard <- authorized inventory, reports, alerts and acknowledgements
```

Supabase is the chosen backend for authentication, persistent records, authorization and live updates. Native Android code remains responsible for discovery, usage collection and enforcement. Local storage and background synchronization remain separate implementation tasks. The network client and notification service are still placeholders.

## Master completion checklist

### A. Foundation, decisions and code quality

- [x] Create feature-based data/domain/presentation structure.
- [x] Implement Flutter entry point, splash, theme, routes and shared widgets.
- [x] Wire repository interfaces, use cases and ChangeNotifier controllers.
- [x] Implement responsive parent/child dashboard navigation.
- [x] Select Supabase as the backend.
- [x] Fix zero-usage report bars and stale pairing-test selectors.
- [ ] Fix website-rule ID collisions and add a cross-device regression test.
- [ ] Resolve the four existing analyzer findings.
- [ ] Separate demo and production dependency configurations; production must not seed fake accounts or telemetry.
- [ ] Split the large child dashboard and reduce coupling between parent dashboard `part` files.
- [ ] Move support-ticket state from presentation into repository/controller layers.
- [ ] Separate parent and child data access so child screens do not load platform/admin or other-family data.
- [ ] Remove or explain empty root `config` files and unused placeholder code.
- [ ] Define supported platforms, Android versions, release scope and feature acceptance criteria.

### B. Supabase setup and backend delivery

- [ ] Create/configure development and production Supabase environments; choose region and operational budget.
- [ ] Add `supabase_flutter`, initialize it before app startup and configure environment-specific public URL/key values.
- [ ] Keep privileged keys and billing/push credentials in server-side secrets, never in the APK.
- [ ] Introduce versioned SQL migrations, repeatable development seed data and backend configuration in the repository.
- [ ] Add remote repository implementations while retaining explicit demo repositories for previews/tests.
- [ ] Design server-side pairing, inventory reconciliation and privileged account operations.
- [ ] Define API validation, timeouts, error mapping, pagination, retry behavior and idempotency.
- [ ] Configure Android release network access and any required authentication deep links.
- [ ] Establish backend deployment, migration verification and rollback procedures.

### C. Data model, ownership and authorization

Suggested schema below is a design proposal, not an existing database. Finalize names and relationships in migrations.

| Proposed table/group | Responsibility | Intended write access |
|---|---|---|
| `parent_profiles` | Parent identity/profile | Own parent account |
| `devices` | Parent ownership and device enrollment | Controlled enrollment/management operations |
| `device_status` | Permission state, heartbeat, applied rule version | Associated device identity |
| `pairing_invites` | Hashed invitation code, expiry and redemption | Server-controlled operations |
| `installed_apps` | Package metadata and installation state | Associated device identity |
| `app_rules`, `website_rules` | Parent-authored restrictions | Owning parent |
| `usage_daily`, `device_events` | Usage summaries and device events | Associated device, with validated inputs |
| `alerts`, `push_tokens` | Notifications, delivery targets and read state | Explicit device/parent/server permissions |
| `support_tickets`, `support_messages` | Support conversations | Requesting parent and authorized support staff |
| `plans`, `subscriptions` | Catalog and verified entitlements | Server/admin-controlled entitlement updates |
| `admin_roles`, `audit_events` | Privileged access and audit trail | Trusted server/admin operations |

- [ ] Create tables, foreign keys, UUID identifiers, indexes and uniqueness constraints.
- [ ] Add device ownership and authenticated device-identity mappings.
- [ ] Separate child-uploaded app inventory from parent-controlled rules and usage history.
- [ ] Enforce unique `(device_id, package_name)` inventory records and normalized website rules.
- [ ] Preserve app rules across uninstall/reinstall independently of inventory presence.
- [ ] Define timestamps, device timezone, retention periods and deletion/cascade behavior.
- [ ] Implement Row Level Security and least-privilege grants for every exposed table.
- [ ] Restrict each parent to their devices; restrict each child identity to its device and permitted operations.
- [ ] Prevent children from changing rules, ownership, subscriptions or admin permissions.
- [ ] Protect database functions, reporting views and Realtime subscriptions as well as normal table queries.
- [ ] Test unauthorized reads/writes, ownership changes, cross-device access and revoked sessions.

### D. Parent authentication and account lifecycle

- [x] Build registration/login forms, input validation, demo login and logout UI.
- [ ] Replace in-memory password maps with Supabase Auth.
- [ ] Implement email verification, password recovery and authentication callback handling.
- [ ] Restore/refresh sessions on startup and handle expiration or revocation.
- [ ] Add parent/child route guards and separate role-specific access.
- [ ] Clear cached account data, controllers and subscriptions on logout/account switch.
- [ ] Implement profile viewing/editing and verified email/password changes.
- [ ] Make a new account start with no other family's devices, tickets or seeded Premium entitlement.
- [ ] Define and implement session storage appropriate for parent and child devices.
- [ ] Implement account deletion with reauthentication, device revocation and removal of owned records.

### E. Child pairing and device management

- [x] Implement code-only child setup without an email/password form.
- [x] Generate/copy a local pairing code and show connection confirmation.
- [x] Validate local codes and preserve an explicit demo-connection option.
- [ ] Choose the device authentication design; evaluate Supabase anonymous auth versus a dedicated device-credential flow.
- [ ] Generate invitations on the server with expiration, one-time redemption and attempt limits.
- [ ] Redeem invitations atomically and bind the authenticated device identity to the parent's device record.
- [ ] Replace local device-list/code matching with a secure redemption endpoint.
- [ ] Persist the connection across restarts and handle reinstall, session loss and re-pairing.
- [ ] Add QR pairing as specified in the feature plan, using the same secure redemption flow.
- [ ] Implement device rename, unlink/remove, credential revocation and stale-invitation cleanup.
- [ ] Support multiple child devices with correct ownership and enforced plan limits.
- [ ] Validate pairing between two separate physical phones and reject reused/expired/revoked invitations.

### F. Installed-app discovery and synchronization

- [x] Discover current-profile Android launcher apps, excluding Offspring Tracker.
- [x] Read names, package IDs and available Android categories; provide Other fallback.
- [x] Implement native method/event channels and clean up package listeners.
- [x] Refresh on child dashboard entry, resume, package changes and manual action.
- [x] Reconcile local records by package, preserve retained-app rules and remove absent apps.
- [x] Clear seeded usage on the first native scan; avoid inventing last-opened timestamps.
- [x] Retain previous inventory on errors and provide retry feedback.
- [x] Preserve demo/unsupported-platform behavior and avoid scanning the parent's phone during parent navigation.
- [x] Test reconciliation, duplicate metadata, empty inventories, failures and refresh triggers with mocked channels.
- [ ] Validate native discovery and package events on physical Android devices and supported OS versions.
- [ ] Persist inventory locally and upload authenticated snapshots/deltas to Supabase.
- [ ] Make remote reconciliation atomic; partial uploads must not accidentally remove installed apps.
- [ ] Show the child's uploaded inventory on a separate parent phone with last-sync/stale indicators.
- [ ] Move synchronization ownership out of the screen lifecycle so it can run without the child dashboard being open.
- [ ] Verify uninstall/reinstall, app renames/updates, duplicate uploads and interrupted uploads end to end.

### G. Local persistence, synchronization and device status

- [ ] Select a local database and implement schema migrations for rules, inventory and queued events.
- [ ] Build an upload queue with retry/backoff, duplicate protection and bounded storage.
- [ ] Fetch authoritative state on reconnect and reconcile missed updates.
- [ ] Add authorized Realtime subscriptions for active screens; remove listeners on account/device changes.
- [ ] Version rules and distinguish saved, pending, applied and failed states using child acknowledgements.
- [ ] Define conflict handling: parent owns rules; child owns telemetry; server owns membership/entitlements.
- [ ] Implement periodic device heartbeat and derive stale/offline status from timestamps rather than seeded booleans.
- [ ] Report actual usage-access, filtering, service and protected-mode status.
- [ ] Implement Android background scheduling and restart recovery within supported OS constraints.
- [ ] Handle process termination, reboot, battery restrictions, network loss and permission revocation.
- [ ] Make reconnect and lifecycle behavior observable without claiming guaranteed instant background delivery.

### H. Usage tracking, reports and time limits

- [x] Implement daily/weekly report UI and usage/remaining-time calculations using demo values.
- [x] Implement local editing and validation of daily limits.
- [ ] Implement Android usage-access onboarding and actual app-usage collection.
- [ ] Define foreground-time counting, interval boundaries and daily reset behavior.
- [ ] Handle timezone changes, clock changes, midnight boundaries and interrupted sessions.
- [ ] Store usage locally, upload idempotent summaries and aggregate daily/weekly histories on the backend.
- [ ] Implement date-based history, app-wise reports and most-used-app reports with real data.
- [ ] Measure limit consumption locally and apply limits while offline.
- [ ] Distinguish unknown/unavailable usage from genuinely zero usage in the UI.
- [ ] Validate accuracy, duplicate prevention, retention and report performance on physical devices.

### I. App blocking and protected mode

- [x] Build parent block/unblock controls and read-only child rule presentation.
- [ ] Select and validate supported Android enforcement mechanisms before promising blocking behavior.
- [ ] Implement permission/setup flows and device-side block/unblock enforcement.
- [ ] Apply downloaded rules and report enforcement success/failure to the parent.
- [ ] Record blocked-app attempts and limit-reached events without duplicate alerts.
- [ ] Define safe handling for essential system apps and parent-authorized recovery.
- [ ] Implement daily-limit enforcement and offline rule application.
- [ ] Evaluate and document device-owner provisioning requirements for protected mode.
- [ ] Implement supported protected-mode/uninstall-protection behavior, activation, status and authorized removal.
- [ ] Test bypass cases, revoked permissions, restart and battery restrictions; document unsupported scenarios.

### J. Website/domain filtering

- [x] Build local domain add/toggle/delete controls and subdomain option.
- [ ] Fix rule IDs, strengthen domain normalization/validation and enforce database uniqueness.
- [ ] Synchronize domain rules from Supabase to persistent child storage.
- [ ] Design and implement Android local VPN/domain filtering with explicit setup and status.
- [ ] Define exact-domain/subdomain matching and test malformed or internationalized domains.
- [ ] Evaluate private DNS, encrypted DNS, IPv6, alternate browsers and other VPN interactions; document coverage limits.
- [ ] Log real blocked-domain attempts and aggregate counts without excessive logging.
- [ ] Test filtering, service recovery, rule changes and offline behavior on physical devices.

### K. Alerts and notifications

- [x] Build alerts UI and local mark-read behavior.
- [x] Generate local rule-change records and new-install alerts after the first inventory scan.
- [ ] Persist device/parent-scoped alerts and read state in Supabase.
- [ ] Generate real limit, blocked-app/domain, offline-device and permission/service-loss events.
- [ ] Implement push delivery through a selected provider and server-side notification handlers.
- [ ] Register/rotate/revoke device push tokens and request notification permission where required.
- [ ] Implement local notifications, notification channels and authorized navigation from notification taps.
- [ ] Add event deduplication, alert preferences and throttling for repeated events.
- [ ] Test delivery with foreground/background/offline apps and expired sessions.

### L. Subscription and billing

- [x] Define Free/Premium/Family demo plans and plan-selection UI.
- [ ] Finalize plan prices, feature entitlements, device limits and downgrade behavior.
- [ ] Choose billing integration appropriate to the intended release channels.
- [ ] Implement purchase, restore, cancellation, renewal, refund and expiration handling.
- [ ] Verify billing events on the server; make entitlement updates idempotent.
- [ ] Enforce device counts and paid features server-side and consistently in the app.
- [ ] Remove client-controlled entitlement changes and the Free/Premium account mismatch.
- [ ] Test billing in sandbox environments before enabling production purchases.

### M. Support and administration

- [x] Build demo support-ticket form, filters and status UI.
- [x] Provide seeded administrative statistics for the demo.
- [ ] Persist tickets/messages with requester ownership and staff-only administrative actions.
- [ ] Implement ticket replies, lifecycle, notifications and appropriate attachments if included in the final scope.
- [ ] Build the planned admin interface for parent/device management, subscriptions, reports and support.
- [ ] Add server-controlled admin roles, privileged-operation validation and audit records.
- [ ] Replace hardcoded platform statistics with authorized aggregate queries.
- [ ] Ensure parent/child sessions cannot invoke administrative operations.

### N. Product experience and data lifecycle

- [x] Build profile, privacy/help and account-deletion information screens.
- [ ] Replace placeholder actions and demo claims with real behavior and accurate status labels.
- [ ] Provide permission onboarding, retry/recovery flows and readable offline/empty/error states.
- [ ] Validate accessibility, text scaling, keyboard interactions and layouts across supported screen sizes.
- [ ] Finalize parent/child explanations of collected data, monitoring scope and controls.
- [ ] Publish product-specific privacy/support information and define retention/deletion rules for collected records.
- [ ] Implement actual account/device data deletion, including queued local data and server-side cleanup.
- [ ] Define handling of retained backups and support/audit records when an account is deleted.

### O. Testing, operations and release

- [x] Pass the current 12 Flutter tests.
- [x] Build the Android debug APK with the native discovery bridge.
- [ ] Add backend migration, authorization-policy and server-function tests.
- [ ] Add end-to-end tests for two independent families and two physical parent/child phones.
- [ ] Test installation/update/removal, rule delivery, acknowledgement, offline operation and restart recovery.
- [ ] Add usage/enforcement/filtering tests across supported Android versions and representative manufacturers.
- [ ] Test pairing abuse, cross-account access, revocation, account deletion and privileged endpoint access.
- [ ] Measure battery, CPU, memory, network usage, synchronization latency and backend load.
- [ ] Set up CI for formatting checks, analysis, Flutter tests, backend tests and Android builds.
- [ ] Add crash reporting, structured error logs, synchronization health metrics and production alerts.
- [ ] Configure backup/restore procedures and perform a recovery test.
- [ ] Set database/event retention, storage limits and usage/cost alerts.
- [ ] Replace example app identity, finalize branding and configure production signing securely.
- [ ] Build/test a release app bundle and verify the selected store's applicable requirements before submission.
- [ ] Prepare store listing, screenshots, privacy/data declarations and support contact details.
- [ ] Run a limited beta, resolve blocking defects and establish release/rollback procedures.
- [ ] Rewrite README with setup, Supabase migrations, native testing, environments and known limitations.

## Ordered delivery plan and acceptance gates

| Order | Milestone | Complete when |
|---|---|---|
| 1 | Stabilize and configure Supabase | Rule-ID bug fixed; analysis clean; environments and migrations reproducible |
| 2 | Accounts and ownership | Real parent sessions survive restart; policies prevent cross-family access; role guards work |
| 3 | Secure pairing and cross-phone Apps | Separate phones pair securely; child inventory persists and reaches only its parent |
| 4 | Rules, acknowledgements and offline storage | Parent changes reach the child, persist locally and show applied/pending states correctly |
| 5 | Monitoring and device enforcement | Real usage, limits, app/domain restrictions and device status pass physical-device tests |
| 6 | Alerts, billing, support and administration | Real events, verified entitlements and authorized support/admin workflows work end to end |
| 7 | Release hardening | Security, reliability, battery, recovery, release-build and beta acceptance checks pass |

**Recommended next task:** implement Supabase environments, schema and ownership policies, then parent authentication. Do not begin cross-phone inventory uploads before device identity and authorization exist.

Protected mode, admin and paid subscriptions can be scheduled after an initial core release only through an explicit scope decision. They remain unfinished in this full-project checklist.

## Definition of project completion

The full planned project is complete when all required unchecked tasks above are implemented and verified, or explicitly moved out of scope with a recorded reason. In particular:

- Separate parent and child phones pair securely and remain connected across restarts.
- Each family can access only its own records, with distinct parent/device/admin permissions.
- Real apps, usage, status and reports replace seeded data in production.
- Supported restrictions work locally, including documented offline/restart cases, and the parent sees actual application status.
- Notifications, subscriptions, support, account deletion and the planned admin/protected-mode capabilities meet their acceptance criteria.
- Release builds, physical-device tests, recovery procedures and operational monitoring are ready.

Current assessment: suitable for UI/local workflow demonstrations and Android launcher-app discovery. Supabase is selected but not configured or integrated. The project is not yet ready for production remote parental control.

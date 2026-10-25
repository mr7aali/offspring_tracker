# Offspring Tracker — Mode Audit

Updated: October 25, 2026

This report lists what each app mode can do, based on the current code. It complements [PROJECT_PROGRESS.md](PROJECT_PROGRESS.md), which tracks overall delivery status.

**Applies to every mode:** rules are saved and displayed but **not enforced on the device**, and all data is held **in memory only**, so it resets when the app restarts.

## 1. Modes

| Mode | How it is entered | Dashboard | Manages |
|---|---|---|---|
| **Parent** | Start screen → Parent access → sign in or register | Parent dashboard | Any number of child phones |
| **Self mode** | Start screen → Start self mode (no account, no code) | Child dashboard with editing enabled | The phone the app is installed on |
| **Linked child** | Self mode → menu → Connect to a parent → enter the parent's pairing code | Child dashboard, view only | Nothing; the parent manages it |

Self mode is the default for a phone with no parent. It uses the same child dashboard as a linked child, with the parent's rule controls turned on.

## 2. Feature matrix

✅ = can do it · 👁 = view only · — = not available · ⚠️ = present but incomplete

| Feature | Parent | Self mode | Linked child |
|---|---|---|---|
| Overview stats (usage today/week, blocked apps, alerts) | ✅ | ✅ | ✅ |
| Block / unblock apps | ✅ | ✅ | 👁 |
| Set daily app limits | ✅ | ✅ | 👁 |
| Add a blocked website | ✅ | ✅ | — |
| Block / allow a website | ✅ | ✅ | 👁 |
| Delete a website rule | ✅ | ✅ | — |
| Usage report (weekly usage per app, most used) | ✅ Reports tab | ✅ Card on Home | — |
| Alerts list | ✅ | ✅ | ✅ |
| Mark alerts as read | ✅ | ✅ | — |
| Scan installed apps on this phone (Android) | — (never scans the parent's phone) | ✅ | ✅ |
| Refresh / rescan | ✅ | ✅ | ✅ |
| Generate pairing codes | ✅ | — | — |
| Manage several phones (select, switch, list) | ✅ | — | — |
| Connect to a parent | — | ✅ | Already linked |
| Profile | ✅ Parent account | 👁 Device details | 👁 Device details |
| Support tickets | ✅ | — | — |
| Delete account | ⚠️ Information screen only; nothing is deleted | — | — |
| Subscription plans | ⚠️ Not reachable (see finding 2) | — | — |
| Privacy Policy, Terms, Data & permissions, About | ✅ | ✅ | ✅ |
| Sign out | ✅ | ✅ | ✅ |

Self mode does not include the parent's account features (plans, support tickets, account profile, multi-device management) because it has no account.

## 3. Mode transitions

```text
Fresh install ─┬─ Parent access ──► sign in / register ──► Parent dashboard
               └─ Start self mode ──► Self-mode dashboard
                                         │
                                         └─ Connect to a parent (code) ──► Linked child (view only)

Sign out (any mode) ──► start screen
```

- Starting self mode again in the same session reuses the same device record, so its rules are kept.
- A linked child can return to self mode only by signing out.

## 4. Implementation notes

| Concern | Where |
|---|---|
| Start screen and parent sign-in | [auth_screen.dart](lib/features/auth/presentation/screens/auth_screen.dart) |
| Session mode (`self` / `paired`) | [child_session_controller.dart](lib/features/offspring/presentation/controllers/child_session_controller.dart) |
| Creating the self-mode device | [start_self_mode_usecase.dart](lib/features/offspring/domain/usecases/start_self_mode_usecase.dart) |
| Self-mode editing in the child dashboard (`canManage`) | [child_dashboard_screen.dart](lib/features/offspring/presentation/screens/child_dashboard_screen.dart) |
| Limit and website panels shared by parent and self mode | [rule_editor_sheets.dart](lib/features/offspring/presentation/widgets/rule_editor_sheets.dart) |
| Entering a parent's code | [child_pairing_screen.dart](lib/features/auth/presentation/screens/child_pairing_screen.dart) |

- Parent and self mode save rule changes through the same `DashboardController` methods, so they behave identically.
- The self-mode device has an empty pairing code, so it cannot be claimed with a code.
- Tests in [widget_test.dart](test/widget_test.dart) cover self-mode entry, self-mode rule editing (block, limit, add/remove site), the view-only linked child, and parent-to-child pairing.

## 5. Findings

### Working as intended

- Self mode and the parent use the same panels and save paths.
- A linked child sees no switches or edit buttons (covered by a test).
- A self-mode phone cannot be claimed with a pairing code.

### Issues

| # | Issue | Modes affected | Priority |
|---|---|---|---|
| 1 | **Rules are not enforced on the device.** Blocks and limits are stored and shown, but nothing stops an app or website. | All | High (core feature) |
| 2 | **Subscription plans are unreachable.** Plan selection exists only in `_AdminPlansSection`, which is never shown. Plan limits are not enforced. | Parent | Medium |
| 3 | **No separation between accounts or devices.** One shared in-memory store: a parent sees the self-mode phone ("Me / This phone") in their device list, all parents see each other's devices and tickets, and "Mark all read" marks every alert. | All | High (before release) |
| 4 | **No saved data.** A restart wipes accounts, self mode, links and rules. | All | High |
| 5 | **Website-rule ID collision.** Rule IDs are based on list length; deleting a rule after another was removed can also delete a rule on another device. | Parent, self mode | High (quick fix) |
| 6 | **Parent dashboard has no sign-in check.** The route opens without verifying a signed-in parent. | Parent | Medium |
| 7 | **Delete account removes nothing.** It shows a message only. | Parent | Medium |
| 8 | **Usage figures are sample data.** Real usage collection is not built, so reports have no real data. | All | High |

### Recommended order

1. Fix the website-rule ID collision (issue 5).
2. Add Supabase accounts and storage (issues 3, 4 and 6).
3. Build Android usage collection and enforcement (issues 1 and 8).
4. Wire up subscriptions and account deletion (issues 2 and 7).

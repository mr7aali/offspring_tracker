# Flutter Full-Stack Project Folder Structure

**Stack:** Flutter (App UI) · Kotlin (Android control system) · NestJS (Backend) · PostgreSQL (Database) · Firebase (Push Notifications)

This document defines a recommended, production-grade folder structure for a full-stack Flutter application with a native Kotlin control layer and a NestJS/PostgreSQL/Firebase backend.

---

## 1. Repository-Level Layout (Monorepo)

```txt
my-app/
│
├── apps/
│   ├── mobile/              → Flutter app (UI) + Kotlin (Android)
│   └── backend/              → NestJS server
│
├── packages/                 → Shared code across apps (optional but recommended)
│   ├── shared-types/         → DTOs / API contracts shared between Flutter & NestJS
│   └── shared-constants/
│
├── infra/                    → DevOps, deployment, database infra
│   ├── docker/
│   ├── ci-cd/
│   └── postgres/
│
├── docs/                     → Architecture docs, API docs, ERDs
│
└── README.md
```

**Why a monorepo:** Keeping mobile and backend in one repo (even without a tool like Nx/Turborepo/Melos) keeps API contracts in sync and avoids duplicating types by hand.

---

## 2. Flutter App — `apps/mobile/lib/`

```txt
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routes/
│   ├── network/               → Dio/HTTP client for NestJS API
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── controllers/
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── notifications/          → FCM handling UI/logic
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── device_control/         → talks to Kotlin via platform channels
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   ├── widgets/
│   └── services/
│       ├── fcm_service.dart              → Firebase push notification handling
│       └── platform_channel_service.dart → bridge to Kotlin
│
└── config/
    ├── env.dart
    └── dependency_injection.dart
```

### Root Files

- **`main.dart`** — App entry point, calls `runApp()`.
- **`app.dart`** — `MaterialApp` setup: theme, routes, global config.

### `core/` — Cross-cutting app-wide code

| Folder       | Purpose                                 |
| ------------ | --------------------------------------- |
| `constants/` | Colors, strings, asset paths, sizes     |
| `theme/`     | App theme + text styles                 |
| `routes/`    | Route names + route table               |
| `network/`   | API client, endpoints, interceptors     |
| `errors/`    | Failures, exceptions, error handler     |
| `utils/`     | Validators, formatters, logger, helpers |

### `features/` — One folder per feature/module

Each feature follows Clean Architecture's three layers:

- **`data/`** — models, repository implementations, remote/local datasources
- **`domain/`** — entities, abstract repository contracts, usecases
- **`presentation/`** — screens, feature-specific widgets, controllers (Provider/Riverpod/Bloc/GetX)

> **Note:** For small/medium apps, the `domain/` layer is often optional overhead. Consider skipping usecases unless a feature has genuinely complex business logic worth isolating.

### `shared/` — Reused across features

- `widgets/` — buttons, text fields, loaders, app bars
- `services/` — FCM service, platform channel bridge, storage, permissions

### `config/` — App-level setup

- `env.dart` — base URL, environment values
- `dependency_injection.dart` — service/repository registration

---

## 3. Android Native Layer — `apps/mobile/android/`

```txt
android/
└── app/src/main/kotlin/com/yourorg/yourapp/
    ├── MainActivity.kt
    ├── channels/
    │   ├── DeviceControlChannel.kt      → MethodChannel handlers
    │   └── SensorChannel.kt
    ├── services/
    │   ├── ForegroundControlService.kt
    │   └── FirebaseMessagingService.kt  → native FCM receiver
    └── utils/
```

**Key idea:** Kotlin is not a separate project — it lives inside `mobile/android/`. Flutter communicates with it via **Platform Channels** (`MethodChannel` / `EventChannel`). Keep a `channels/` folder on both the Dart side and the Kotlin side so each channel name has one clear home on each end.

`FirebaseMessagingService.kt` handles background push delivery reliably when the app is killed — Dart-side FCM handling alone isn't sufficient in that state.

---

## 4. Backend — `apps/backend/src/` (NestJS)

```txt
backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── dto/
│   │   │   └── guards/
│   │   │
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── entities/
│   │   │   │   └── user.entity.ts        → TypeORM/Prisma model → PostgreSQL
│   │   │   └── dto/
│   │   │
│   │   └── notifications/
│   │       ├── notifications.module.ts
│   │       ├── notifications.controller.ts
│   │       ├── notifications.service.ts   → sends via Firebase Admin SDK
│   │       └── entities/
│   │           └── device_token.entity.ts
│   │
│   ├── common/
│   │   ├── filters/          → exception filters
│   │   ├── interceptors/
│   │   ├── guards/
│   │   ├── decorators/
│   │   └── pipes/
│   │
│   ├── config/
│   │   ├── database.config.ts     → PostgreSQL connection config
│   │   ├── firebase.config.ts     → Firebase Admin init
│   │   └── env.validation.ts
│   │
│   └── database/
│       ├── migrations/
│       └── seeds/
│
├── test/
├── .env
└── package.json
```

**Key idea:** Each NestJS module mirrors a Flutter `features/` folder (`auth`, `users`, `notifications`), so it's easy to map a mobile feature to its backend counterpart.

---

## 5. How Firebase Fits (Push Notifications Only)

Firebase's job here is limited to push notifications — avoid letting it become a shadow database or auth system unless intentionally designed that way.

| Layer                                            | Responsibility                                                                                      |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| **Flutter** (`shared/services/fcm_service.dart`) | Request permissions, get device token, handle foreground/background messages, send token to backend |
| **Kotlin** (`FirebaseMessagingService.kt`)       | Native background delivery when app is killed                                                       |
| **NestJS** (`notifications` module)              | Store device tokens in PostgreSQL, trigger sends via `firebase-admin`                               |

---

## 6. PostgreSQL

Lives entirely in the backend — Flutter never accesses it directly.

- `entities/` — co-located per module, not a single dumping folder
- `database/migrations/` — tracked via TypeORM/Prisma migration tooling
- `database.config.ts` — centralizes the DB connection

---

## 7. Naming Conventions

```txt
login_screen.dart
auth_controller.dart
user_model.dart
auth_repository.dart
login_usecase.dart
custom_button.dart

users.controller.ts
users.service.ts
user.entity.ts
create-user.dto.ts
```

- Use lowercase with underscores (Dart) or kebab-case (NestJS convention).
- File names should clearly describe their purpose.
- Keep feature-specific code inside its feature/module folder.
- Keep global reusable code inside `shared/` (Flutter) or `common/` (NestJS).

---

## 8. Best Practices

- **Separate UI from business logic** — screens/controllers only handle UI; logic lives in services, usecases, or repositories.
- **Keep each feature/module independent** — easier to maintain and onboard new developers.
- **Avoid one big folder** — don't dump all screens, models, or services together.
- **Centralize constants** — colors, strings, asset paths, and routes belong in `core/constants/`, not hardcoded in widgets.
- **Handle errors properly** — API, validation, and network errors belong in `core/errors/` (Flutter) and `common/filters/` (NestJS).
- **Don't over-engineer small apps** — skip the `domain/` layer and complex DTO structures until real complexity justifies them.

---

## 9. Scope Note

This structure is calibrated for a **production app built by a team**. For a **solo project or MVP**, simplify by:

- Dropping the `domain/` layer in Flutter features
- Skipping separate DTO folders in NestJS until validation complexity requires them
- Using a single `services/` folder in the backend instead of full module boilerplate for very small domains

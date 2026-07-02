# Flutter Project Folder Structure Documentation

## 1. Overview

This document explains the recommended folder structure for a professional Flutter application. The structure follows a **feature-based clean architecture** approach, which helps keep the project scalable, maintainable, and easy to understand.

This structure is suitable for medium to large Flutter applications such as e-commerce apps, loan management apps, booking apps, social apps, admin apps, and production-level client projects.

---

## 2. Main Folder Structure

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
│   ├── network/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   ├── widgets/
│   └── services/
│
└── config/
    ├── env.dart
    └── dependency_injection.dart
```

---

## 3. Root Files

### `main.dart`

This is the entry point of the Flutter application. It is responsible for starting the app.

Example:

```dart
void main() {
  runApp(const MyApp());
}
```

### `app.dart`

This file contains the main app widget, MaterialApp configuration, theme, routes, and global app setup.

Example:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
```

---

## 4. Core Folder

The `core/` folder contains common files that are used across the full application.

```txt
core/
├── constants/
├── theme/
├── routes/
├── network/
├── errors/
└── utils/
```

### `core/constants/`

This folder stores static values used throughout the app.

Example files:

```txt
app_colors.dart
app_strings.dart
app_assets.dart
app_sizes.dart
```

Example:

```dart
class AppStrings {
  static const String appName = 'My Flutter App';
}
```

### `core/theme/`

This folder contains the app theme configuration.

Example files:

```txt
app_theme.dart
app_text_styles.dart
```

Example:

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    fontFamily: 'Poppins',
  );
}
```

### `core/routes/`

This folder manages app navigation and route names.

Example files:

```txt
app_routes.dart
route_names.dart
```

Example:

```dart
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
}
```

### `core/network/`

This folder handles API-related configuration.

Example files:

```txt
api_client.dart
api_endpoints.dart
dio_client.dart
network_info.dart
```

Use this folder for API base URL, headers, interceptors, and HTTP request handling.

### `core/errors/`

This folder contains error and failure handling classes.

Example files:

```txt
failures.dart
exceptions.dart
error_handler.dart
```

### `core/utils/`

This folder contains helper functions and reusable utility classes.

Example files:

```txt
validators.dart
helpers.dart
date_formatter.dart
app_logger.dart
```

---

## 5. Features Folder

The `features/` folder contains the main modules of the application. Each feature has its own separate folder.

Example:

```txt
features/
├── auth/
├── home/
├── profile/
├── product/
├── cart/
└── payment/
```

Each feature should follow this structure:

```txt
feature_name/
├── data/
├── domain/
└── presentation/
```

---

## 6. Feature Layer Explanation

### 6.1 Data Layer

The `data/` layer handles API calls, local database operations, models, and repository implementations.

```txt
data/
├── models/
├── repositories/
└── datasources/
```

#### `data/models/`

Contains data models used for API response and request mapping.

Example:

```dart
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
```

#### `data/datasources/`

Contains remote and local data sources.

Example files:

```txt
auth_remote_datasource.dart
auth_local_datasource.dart
```

Remote datasource is used for API calls.
Local datasource is used for local storage, cache, or database.

#### `data/repositories/`

Contains repository implementation files.

Example:

```txt
auth_repository_impl.dart
```

---

### 6.2 Domain Layer

The `domain/` layer contains the business logic of the application.

```txt
domain/
├── entities/
├── repositories/
└── usecases/
```

#### `domain/entities/`

Entities represent the main business objects of the app.

Example:

```dart
class UserEntity {
  final String id;
  final String name;
  final String email;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

#### `domain/repositories/`

Contains abstract repository contracts.

Example:

```dart
abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
}
```

#### `domain/usecases/`

Contains application-specific business actions.

Example files:

```txt
login_usecase.dart
register_usecase.dart
logout_usecase.dart
```

Example:

```dart
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call(String email, String password) {
    return repository.login(email, password);
  }
}
```

---

### 6.3 Presentation Layer

The `presentation/` layer contains UI and state management files.

```txt
presentation/
├── screens/
├── widgets/
└── controllers/
```

#### `presentation/screens/`

Contains full pages or screens.

Example:

```txt
login_screen.dart
register_screen.dart
forgot_password_screen.dart
```

#### `presentation/widgets/`

Contains widgets used only inside that specific feature.

Example:

```txt
login_form.dart
social_login_button.dart
auth_header.dart
```

#### `presentation/controllers/`

Contains state management files such as Provider, Riverpod, Bloc, Cubit, or GetX controllers.

Example:

```txt
auth_controller.dart
auth_provider.dart
auth_bloc.dart
```

---

## 7. Shared Folder

The `shared/` folder contains reusable components and services used across multiple features.

```txt
shared/
├── widgets/
└── services/
```

### `shared/widgets/`

Contains global reusable widgets.

Example files:

```txt
custom_button.dart
custom_text_field.dart
loading_widget.dart
empty_state_widget.dart
custom_app_bar.dart
```

These widgets should be independent and reusable in any feature.

### `shared/services/`

Contains common services used throughout the app.

Example files:

```txt
storage_service.dart
notification_service.dart
permission_service.dart
location_service.dart
```

---

## 8. Config Folder

The `config/` folder contains app-level configuration files.

```txt
config/
├── env.dart
└── dependency_injection.dart
```

### `env.dart`

Used for environment values such as API base URL, app mode, and third-party keys.

Example:

```dart
class Env {
  static const String baseUrl = 'https://api.example.com';
}
```

### `dependency_injection.dart`

Used to register dependencies such as repositories, services, API clients, and use cases.

Example:

```dart
void setupDependencies() {
  // Register services, repositories, and controllers here
}
```

---

## 9. Example Auth Feature Structure

```txt
features/auth/
├── data/
│   ├── models/
│   │   └── user_model.dart
│   │
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   │
│   └── datasources/
│       ├── auth_remote_datasource.dart
│       └── auth_local_datasource.dart
│
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   │
│   ├── repositories/
│   │   └── auth_repository.dart
│   │
│   └── usecases/
│       ├── login_usecase.dart
│       ├── register_usecase.dart
│       └── logout_usecase.dart
│
└── presentation/
    ├── screens/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── forgot_password_screen.dart
    │
    ├── widgets/
    │   ├── login_form.dart
    │   └── auth_button.dart
    │
    └── controllers/
        └── auth_controller.dart
```

---

## 10. Naming Convention

Use clear and consistent file naming.

Recommended style:

```txt
login_screen.dart
auth_controller.dart
user_model.dart
auth_repository.dart
login_usecase.dart
custom_button.dart
```

### Rules

* Use lowercase letters.
* Use underscores between words.
* File names should clearly describe their purpose.
* Keep feature-specific widgets inside the feature folder.
* Keep global reusable widgets inside `shared/widgets/`.

---

## 11. Best Practices

### Keep UI and business logic separate

Screens should only handle UI. Business logic should be handled inside controllers, providers, blocs, use cases, or repositories.

### Keep each feature independent

Each feature should have its own data, domain, and presentation layers. This makes the project easier to maintain.

### Avoid putting everything in one folder

Do not keep all screens, models, and services together in one large folder. It becomes hard to manage when the project grows.

### Use reusable widgets

Common UI components like buttons, text fields, loaders, and app bars should be placed inside `shared/widgets/`.

### Use constants

Avoid hardcoding colors, text, asset paths, and route names directly inside widgets. Store them inside the `core/constants/` folder.

### Use proper error handling

Handle API errors, validation errors, and network errors properly inside the `core/errors/` folder.

---

## 12. When to Use This Structure

This structure is recommended for:

* Production-level Flutter apps
* Client projects
* E-commerce apps
* Loan management apps
* Admin apps
* Booking apps
* Social apps
* Apps with API integration
* Apps that may grow in the future

---

## 13. Simple Folder Structure for Small Apps

For small apps, you can use a simpler structure:

```txt
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routes/
│   └── utils/
│
├── screens/
│   ├── auth/
│   ├── home/
│   └── profile/
│
├── widgets/
├── models/
├── services/
├── controllers/
└── providers/
```

This structure is easier for beginners, but it may become difficult to manage when the app becomes large.

---

## 14. Final Recommendation

For professional Flutter development, the best approach is to use a **feature-based clean architecture** folder structure.

It keeps the project clean, scalable, and easy to maintain. It also helps developers work on separate features without affecting the whole application.

Recommended structure:

```txt
lib/
├── core/
├── features/
├── shared/
├── config/
├── app.dart
└── main.dart
```

This structure is suitable for real-world Flutter apps and long-term project maintenance.

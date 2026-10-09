import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_logo.dart';
import 'child_pairing_screen.dart';

enum _LoginRole { parent, child }

extension _LoginRoleUi on _LoginRole {
  String get headline {
    switch (this) {
      case _LoginRole.parent:
        return 'Parent access';
      case _LoginRole.child:
        return 'Child device setup';
    }
  }

  String get subtitle {
    switch (this) {
      case _LoginRole.parent:
        return 'Manage child devices, rules, reports, alerts, and account settings.';
      case _LoginRole.child:
        return 'Connect this phone to a parent using a pairing code. No child account needed.';
    }
  }

  IconData get icon {
    switch (this) {
      case _LoginRole.parent:
        return Icons.supervisor_account_outlined;
      case _LoginRole.child:
        return Icons.phone_android_outlined;
    }
  }

  Color get color {
    switch (this) {
      case _LoginRole.parent:
        return AppColors.primary;
      case _LoginRole.child:
        return AppColors.secondary;
    }
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _openRole(BuildContext context, _LoginRole role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => role == _LoginRole.child
            ? const ChildPairingScreen()
            : const _RoleAuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RoleSelectionHeader(),
                  const SizedBox(height: 24),
                  _RoleChoiceCard(
                    role: _LoginRole.parent,
                    onTap: () => _openRole(context, _LoginRole.parent),
                  ),
                  const SizedBox(height: AppSizes.cardGap),
                  _RoleChoiceCard(
                    role: _LoginRole.child,
                    onTap: () => _openRole(context, _LoginRole.child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionHeader extends StatelessWidget {
  const _RoleSelectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogoMark(
          size: 56,
          padding: 0,
          backgroundColor: Colors.white,
          borderRadius: AppSizes.radius,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to continue',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Parents sign in to manage their family. Child phones connect with a pairing code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({required this.role, required this.onTap});

  final _LoginRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Icon(role.icon, color: role.color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      role == _LoginRole.parent
                          ? 'Parent sign in'
                          : 'Connect child device',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: role.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: role.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleAuthScreen extends StatefulWidget {
  const _RoleAuthScreen();

  @override
  State<_RoleAuthScreen> createState() => _RoleAuthScreenState();
}

class _RoleAuthScreenState extends State<_RoleAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (appDependencies.authController.isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authController = appDependencies.authController;
    final success = _isRegisterMode
        ? await authController.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await authController.login(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted || !success) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.dashboard, (_) => false);
  }

  Future<void> _useDemoParentAccount() async {
    final success = await appDependencies.authController.useDemoAccount();
    if (!mounted || !success) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.dashboard, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Parent access'),
        leading: IconButton(
          tooltip: 'Choose role',
          onPressed: () {
            appDependencies.authController.clearError();
            appDependencies.childSessionController.clearError();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RoleAuthHeader(role: _LoginRole.parent),
                  const SizedBox(height: 18),
                  _AuthFormPanel(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isRegisterMode: _isRegisterMode,
                    obscurePassword: _obscurePassword,
                    onModeChanged: (value) {
                      setState(() => _isRegisterMode = value);
                      appDependencies.authController.clearError();
                    },
                    onObscureChanged: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    onSubmit: _submit,
                    onUseDemoParent: _useDemoParentAccount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleAuthHeader extends StatelessWidget {
  const _RoleAuthHeader({required this.role});

  final _LoginRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Icon(role.icon, color: role.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == _LoginRole.parent
                    ? 'Parent sign in'
                    : 'Connect child device',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                role.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isRegisterMode,
    required this.obscurePassword,
    required this.onModeChanged,
    required this.onObscureChanged,
    required this.onSubmit,
    required this.onUseDemoParent,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isRegisterMode;
  final bool obscurePassword;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onObscureChanged;
  final VoidCallback onSubmit;
  final VoidCallback onUseDemoParent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appDependencies.authController,
      builder: (context, _) {
        final parentController = appDependencies.authController;
        final isLoading = parentController.isLoading;
        final errorMessage = parentController.errorMessage;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRegisterMode ? 'Create parent account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRegisterMode
                        ? 'Register a parent profile to start pairing child devices.'
                        : 'Sign in to manage devices and parental control rules.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.login),
                          label: Text('Sign in'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.person_add_alt_1),
                          label: Text('Register'),
                        ),
                      ],
                      selected: {isRegisterMode},
                      onSelectionChanged: isLoading
                          ? null
                          : (values) => onModeChanged(values.first),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (isRegisterMode) ...[
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Parent name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          Validators.requiredText(value, 'Parent name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...[
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: onObscureChanged,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) => onSubmit(),
                      validator: Validators.password,
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: errorMessage),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onSubmit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isRegisterMode ? Icons.person_add : Icons.login),
                    label: Text(isRegisterMode ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: isLoading ? null : onUseDemoParent,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Use demo parent'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

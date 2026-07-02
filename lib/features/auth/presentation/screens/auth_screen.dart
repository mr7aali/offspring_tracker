import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: AppStrings.demoEmail);
  final _passwordController = TextEditingController(
    text: AppStrings.demoPassword,
  );

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
    Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
  }

  Future<void> _useDemoAccount() async {
    final success = await appDependencies.authController.useDemoAccount();
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = MediaQuery.sizeOf(context).width >= 900;
                final form = _AuthFormPanel(
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
                  onUseDemo: _useDemoAccount,
                );

                if (!isWide) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        const _BrandPanel(compact: true),
                        const SizedBox(height: 18),
                        form,
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: _BrandPanel()),
                      const SizedBox(width: 28),
                      Expanded(child: form),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 58 : 72,
          height: compact ? 58 : 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Icon(
            Icons.family_restroom,
            size: compact ? 32 : 40,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: compact ? 14 : 24),
        Text(
          AppStrings.appName,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manage child devices, app limits, website rules, reports, and alerts from one parent dashboard.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.muted,
            height: 1.35,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeatureBadge(icon: Icons.devices, label: 'Device pairing'),
              _FeatureBadge(icon: Icons.lock, label: 'App blocking'),
              _FeatureBadge(icon: Icons.public_off, label: 'Domain filters'),
              _FeatureBadge(icon: Icons.bar_chart, label: 'Usage reports'),
            ],
          ),
        ],
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
    required this.onUseDemo,
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
  final VoidCallback onUseDemo;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appDependencies.authController,
      builder: (context, _) {
        final controller = appDependencies.authController;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
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
                    onSelectionChanged: controller.isLoading
                        ? null
                        : (values) => onModeChanged(values.first),
                  ),
                  const SizedBox(height: 18),
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
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: controller.errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: controller.isLoading ? null : onSubmit,
                    icon: controller.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isRegisterMode ? Icons.person_add : Icons.login),
                    label: Text(isRegisterMode ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: controller.isLoading ? null : onUseDemo,
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

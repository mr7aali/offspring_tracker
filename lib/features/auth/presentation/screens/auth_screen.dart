import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/auth_widgets.dart';
import 'child_pairing_screen.dart';

/// Layouts switch to a two-column design from this width.
const double _wideBreakpoint = 900;

const List<AuthFeature> _parentFeatures = [
  AuthFeature(
    Icons.timer_outlined,
    'Daily app limits',
    'Set healthy screen-time limits for each app.',
  ),
  AuthFeature(
    Icons.language_rounded,
    'Website rules',
    'Allow or block sites on every child device.',
  ),
  AuthFeature(
    Icons.insights_rounded,
    'Reports & alerts',
    'See usage trends and get notified about changes.',
  ),
];

enum _LoginRole { parent, child }

extension _LoginRoleUi on _LoginRole {
  String get headline => switch (this) {
    _LoginRole.parent => 'Parent access',
    _LoginRole.child => 'Child device setup',
  };

  String get subtitle => switch (this) {
    _LoginRole.parent =>
      'Manage child devices, rules, reports, alerts, and account settings.',
    _LoginRole.child =>
      'Connect this phone to a parent using a pairing code. No child account needed.',
  };

  String get actionLabel => switch (this) {
    _LoginRole.parent => 'Parent sign in',
    _LoginRole.child => 'Connect child device',
  };

  IconData get icon => switch (this) {
    _LoginRole.parent => Icons.family_restroom_rounded,
    _LoginRole.child => Icons.phone_android_rounded,
  };

  Color get color => switch (this) {
    _LoginRole.parent => AppColors.primary,
    _LoginRole.child => AppColors.secondary,
  };

  LinearGradient get gradient => switch (this) {
    _LoginRole.parent => AuthPalette.parent,
    _LoginRole.child => AuthPalette.child,
  };

  List<(IconData, String)> get highlights => switch (this) {
    _LoginRole.parent => const [
      (Icons.timer_outlined, 'App limits'),
      (Icons.language_rounded, 'Website rules'),
      (Icons.insights_rounded, 'Reports'),
    ],
    _LoginRole.child => const [
      (Icons.dialpad_rounded, 'Code only'),
      (Icons.no_accounts_outlined, 'No account'),
      (Icons.bolt_rounded, 'Quick setup'),
    ],
  };
}

void _clearAuthErrors() {
  appDependencies.authController.clearError();
  appDependencies.childSessionController.clearError();
}

// ---------------------------------------------------------------------------
// Role selection
// ---------------------------------------------------------------------------

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
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _wideBreakpoint) {
              return Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: AuthBrandPanel(
                      headline: 'Healthy screen habits for the whole family',
                      description:
                          'One place to guide how your children use their phones.',
                      features: _parentFeatures,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _RoleChoices(
                              showHeading: true,
                              onOpen: (role) => _openRole(context, role),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const _RoleHero(),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: _RoleChoices(
                            showHeading: false,
                            onOpen: (role) => _openRole(context, role),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleHero extends StatelessWidget {
  const _RoleHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return AuthHeroBackground(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, topInset + 36, 24, 84),
          child: Column(
            children: [
              const AuthEntrance(child: AuthLogoBadge(size: 76)),
              const SizedBox(height: 20),
              AuthEntrance(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AuthEntrance(
                delay: const Duration(milliseconds: 140),
                child: Column(
                  children: [
                    Text(
                      'Choose how you want to continue',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        'Parents sign in to manage their family. Child phones connect with a pairing code.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoices extends StatelessWidget {
  const _RoleChoices({required this.showHeading, required this.onOpen});

  final bool showHeading;
  final ValueChanged<_LoginRole> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            'Choose how you want to continue',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parents sign in to manage their family. Child phones connect with a pairing code.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
        ],
        AuthEntrance(
          delay: const Duration(milliseconds: 200),
          child: _RoleChoiceCard(
            role: _LoginRole.parent,
            onTap: () => onOpen(_LoginRole.parent),
          ),
        ),
        const SizedBox(height: 16),
        AuthEntrance(
          delay: const Duration(milliseconds: 280),
          child: _RoleChoiceCard(
            role: _LoginRole.child,
            onTap: () => onOpen(_LoginRole.child),
          ),
        ),
        const SizedBox(height: 24),
        const AuthEntrance(
          delay: Duration(milliseconds: 360),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _FootNote(
                icon: Icons.verified_user_outlined,
                label: 'Parents set every rule',
              ),
              _FootNote(
                icon: Icons.child_care_outlined,
                label: 'No child account needed',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RoleChoiceCard extends StatefulWidget {
  const _RoleChoiceCard({required this.role, required this.onTap});

  final _LoginRole role;
  final VoidCallback onTap;

  @override
  State<_RoleChoiceCard> createState() => _RoleChoiceCardState();
}

class _RoleChoiceCardState extends State<_RoleChoiceCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(22);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: _hovered
                ? role.color.withValues(alpha: 0.45)
                : AppColors.border.withValues(alpha: 0.8),
          ),
          boxShadow: AuthPalette.cardShadow(strength: _hovered ? 1.3 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: role.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: role.color.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(role.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.headline,
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role.subtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icon, label) in role.highlights)
                        _HighlightChip(icon: icon, label: label),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: role.color.withValues(
                        alpha: _hovered ? 0.14 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            role.actionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: role.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: Offset(_hovered ? 0.25 : 0, 0),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: role.color,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
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

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuthPalette.fieldFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Parent sign in / register
// ---------------------------------------------------------------------------

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

  void _setMode(bool isRegister) {
    if (isRegister == _isRegisterMode) return;
    HapticFeedback.selectionClick();
    setState(() => _isRegisterMode = isRegister);
    appDependencies.authController.clearError();
  }

  void _openChildSetup() {
    _clearAuthErrors();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ChildPairingScreen()),
    );
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

  Widget _buildForm({required bool showTitle}) {
    return _AuthFormCard(
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      isRegisterMode: _isRegisterMode,
      obscurePassword: _obscurePassword,
      showTitle: showTitle,
      onModeChanged: _setMode,
      onObscureChanged: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmit: _submit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearAuthErrors();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void back() => Navigator.of(context).maybePop();

              if (constraints.maxWidth >= _wideBreakpoint) {
                return Row(
                  children: [
                    const Expanded(
                      flex: 5,
                      child: AuthBrandPanel(
                        headline: 'Stay close to what matters',
                        description:
                            'Sign in to guide screen time, websites and alerts for every child device.',
                        features: _parentFeatures,
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(40),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildForm(showTitle: true),
                                      const SizedBox(height: 12),
                                      _ChildSetupLink(onTap: _openChildSetup),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: IconButton.filledTonal(
                                tooltip: 'Choose role',
                                onPressed: back,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _LoginHero(isRegisterMode: _isRegisterMode, onBack: back),
                    Transform.translate(
                      offset: const Offset(0, -44),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthEntrance(
                                  delay: const Duration(milliseconds: 120),
                                  child: _buildForm(showTitle: false),
                                ),
                                const SizedBox(height: 12),
                                _ChildSetupLink(onTap: _openChildSetup),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _formTitle(bool isRegisterMode) =>
    isRegisterMode ? 'Create your account' : 'Welcome back';

String _formSubtitle(bool isRegisterMode) => isRegisterMode
    ? 'Register a parent profile to start pairing child devices.'
    : 'Sign in to manage devices and parental control rules.';

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.isRegisterMode, required this.onBack});

  final bool isRegisterMode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return AuthHeroBackground(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 12, 24, 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AuthGlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Choose role',
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.family_restroom_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Parent access',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthEntrance(child: AuthLogoBadge(size: 60)),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      layoutBuilder: _topLeftLayout,
                      child: Column(
                        key: ValueKey(isRegisterMode),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formTitle(isRegisterMode),
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formSubtitle(isRegisterMode),
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _topLeftLayout(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.topLeft,
    children: [...previousChildren, ?currentChild],
  );
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isRegisterMode,
    required this.obscurePassword,
    required this.showTitle,
    required this.onModeChanged,
    required this.onObscureChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isRegisterMode;
  final bool obscurePassword;
  final bool showTitle;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onObscureChanged;
  final VoidCallback onSubmit;

  static const _sizeDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: appDependencies.authController,
      builder: (context, _) {
        final controller = appDependencies.authController;
        final isLoading = controller.isLoading;
        final errorMessage = controller.errorMessage;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            boxShadow: AuthPalette.cardShadow(),
          ),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTitle) ...[
                    Text(
                      _formTitle(isRegisterMode),
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formSubtitle(isRegisterMode),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _ModeSwitch(
                    isRegisterMode: isRegisterMode,
                    enabled: !isLoading,
                    onChanged: onModeChanged,
                  ),
                  const SizedBox(height: 22),
                  AnimatedSize(
                    duration: _sizeDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: isRegisterMode
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: TextFormField(
                              controller: nameController,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: _fieldDecoration(
                                label: 'Parent name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) =>
                                  Validators.requiredText(value, 'Parent name'),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  TextFormField(
                    controller: emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: _fieldDecoration(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      hint: 'you@example.com',
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    enabled: !isLoading,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      isRegisterMode
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: _fieldDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        tooltip: obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: onObscureChanged,
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: Validators.password,
                  ),
                  AnimatedSize(
                    duration: _sizeDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: isRegisterMode
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _PasswordStrengthMeter(
                              controller: passwordController,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  AnimatedSize(
                    duration: _sizeDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _ErrorBanner(message: errorMessage),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 24),
                  AuthGradientButton(
                    label: isRegisterMode ? 'Create account' : 'Sign in',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: isLoading,
                    onPressed: onSubmit,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isRegisterMode
                            ? 'Already have an account?'
                            : 'New to ${AppStrings.appName}?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => onModeChanged(!isRegisterMode),
                        child: Text(
                          isRegisterMode
                              ? 'Sign in instead'
                              : 'Create an account',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
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

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  String? hint,
  Widget? suffix,
}) {
  OutlineInputBorder border([Color? color, double width = 1.6]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: AuthPalette.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(),
    enabledBorder: border(),
    disabledBorder: border(),
    focusedBorder: border(AppColors.primary),
    errorBorder: border(AppColors.danger.withValues(alpha: 0.6), 1.2),
    focusedErrorBorder: border(AppColors.danger),
  );
}

/// Segmented "Sign in / Register" control with a sliding indicator.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.isRegisterMode,
    required this.enabled,
    required this.onChanged,
  });

  final bool isRegisterMode;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AuthPalette.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: isRegisterMode
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AuthPalette.shadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ModeTab(
                  label: 'Sign in',
                  icon: Icons.login_rounded,
                  selected: !isRegisterMode,
                  onTap: enabled ? () => onChanged(false) : null,
                ),
              ),
              Expanded(
                child: _ModeTab(
                  label: 'Register',
                  icon: Icons.person_add_alt_1_rounded,
                  selected: isRegisterMode,
                  onTap: enabled ? () => onChanged(true) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.controller});

  final TextEditingController controller;

  static (int, String, Color) _evaluate(String text) {
    var score = 0;
    if (text.length >= 8) score++;
    if (RegExp('[a-z]').hasMatch(text) && RegExp('[A-Z]').hasMatch(text)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(text)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(text)) score++;
    if (text.length < 8 && score > 1) score = 1;

    return switch (score) {
      <= 1 => (score, 'Weak', AppColors.danger),
      2 => (score, 'Fair', AppColors.accent),
      3 => (score, 'Good', AppColors.primary),
      _ => (score, 'Strong', AppColors.secondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final (score, label, color) = _evaluate(text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: text.isNotEmpty && i < score.clamp(1, 4)
                            ? color
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text.isEmpty
                  ? 'Use 8+ characters with a mix of letters, numbers and symbols.'
                  : 'Password strength: $label',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: text.isEmpty ? AppColors.muted : color,
                fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
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
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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

class _ChildSetupLink extends StatelessWidget {
  const _ChildSetupLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: AppColors.muted),
        icon: const Icon(Icons.phone_android_rounded, size: 18),
        label: const Text("Setting up a child's phone instead?"),
      ),
    );
  }
}

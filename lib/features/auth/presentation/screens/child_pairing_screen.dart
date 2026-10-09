import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Frontend preview. Uses the existing in-memory demo connection only.
class ChildPairingScreen extends StatefulWidget {
  const ChildPairingScreen({super.key});

  @override
  State<ChildPairingScreen> createState() => _ChildPairingScreenState();
}

class _ChildPairingScreenState extends State<ChildPairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    appDependencies.childSessionController.clearError();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final controller = appDependencies.childSessionController;
    if (controller.isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await controller.connect(pairingCode: _codeController.text);
    if (mounted && success) setState(() => _connected = true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = appDependencies.childSessionController;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Child device setup')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _connected
                        ? _buildConnected(context)
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Center(child: AppLogoMark(size: 56)),
                                const SizedBox(height: 20),
                                Text(
                                  'Connect to your parent',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No email or password needed on this phone. Ask your parent to help with setup.',
                                ),
                                const SizedBox(height: 24),
                                const _SetupStep(
                                  number: '1',
                                  title: 'On the parent phone',
                                  detail:
                                      'Sign in, tap Pair device, and generate a pairing code.',
                                ),
                                const SizedBox(height: 16),
                                const _SetupStep(
                                  number: '2',
                                  title: 'On this child phone',
                                  detail:
                                      'Enter that code below to connect to your parent.',
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _codeController,
                                  enabled: !controller.isLoading,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 8,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[a-zA-Z0-9]'),
                                    ),
                                  ],
                                  style: const TextStyle(
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Pairing code',
                                    hintText: 'ABCD1234',
                                    prefixIcon: Icon(Icons.link),
                                    counterText: '',
                                  ),
                                  validator: (value) =>
                                      (value?.trim().length ?? 0) < 5
                                      ? 'Enter the code shown on the parent phone'
                                      : null,
                                  onFieldSubmitted: (_) => _connect(),
                                  onChanged: (_) {
                                    if (controller.errorMessage != null) {
                                      controller.clearError();
                                    }
                                  },
                                ),
                                if (controller.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    controller.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: controller.isLoading
                                      ? null
                                      : _connect,
                                  icon: controller.isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.link),
                                  label: Text(
                                    controller.isLoading
                                        ? 'Connecting…'
                                        : 'Connect this device',
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.isLoading
                                      ? null
                                      : () {
                                          _codeController.text = 'MAYA7';
                                          _connect();
                                        },
                                  child: const Text('Try demo connection'),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Demo preview: pairing works only within this app session. Connecting separate phones will be available with the live service.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnected(BuildContext context) {
    final device = appDependencies.childSessionController.currentDevice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 20),
        Text(
          'Device connected',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          '${device.childName} • ${device.deviceName}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'You can view app limits, website rules, and device status. Your parent manages the rules.',
        ),
        const SizedBox(height: 12),
        const Text(
          'This is a demo connection. It resets when the app restarts.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RouteNames.childDashboard, (_) => false),
          icon: const Icon(Icons.phone_android),
          label: const Text('Continue to my device'),
        ),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.detail,
  });
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.secondary.withValues(alpha: .12),
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    ],
  );
}

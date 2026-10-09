import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/dashboard_controller.dart';

/// Demonstrates the parent invitation flow using the existing local demo data.
class PairChildDeviceDialog extends StatefulWidget {
  const PairChildDeviceDialog({super.key, required this.controller});
  final DashboardController controller;

  @override
  State<PairChildDeviceDialog> createState() => _PairChildDeviceDialogState();
}

class _PairChildDeviceDialogState extends State<PairChildDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _childController = TextEditingController();
  final _deviceController = TextEditingController();
  String? _code;
  String? _error;
  bool _isLoading = false;
  bool _copied = false;

  @override
  void dispose() {
    _childController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    String code;
    do {
      code = List.generate(
        8,
        (_) => alphabet[random.nextInt(alphabet.length)],
      ).join();
    } while (widget.controller.devices.any(
      (device) => device.pairingCode == code,
    ));
    await widget.controller.pairDevice(
      childName: _childController.text,
      deviceName: _deviceController.text,
      pairingCode: code,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = widget.controller.errorMessage;
      if (_error == null) _code = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_isLoading,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _code == null ? Icons.add_link : Icons.qr_code,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _code == null ? 'Connect a child phone' : 'Your pairing code',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (_code == null)
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add your child’s details, then generate a code to enter on their phone. Your child does not need an account.',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _childController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Child name',
                          prefixIcon: const Icon(Icons.child_care),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        validator: (value) =>
                            Validators.requiredText(value, 'Child name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deviceController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Device name',
                          hintText: 'Child’s Android phone',
                          prefixIcon: const Icon(Icons.smartphone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        validator: (value) =>
                            Validators.requiredText(value, 'Device name'),
                        onFieldSubmitted: (_) => _generate(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Demo preview: this adds a device to this app session only.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isLoading ? null : _generate,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.link),
                              label: Text(
                                _isLoading ? 'Generating…' : 'Generate code',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_childController.text.trim()} • ${_deviceController.text.trim()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: SelectableText(
                        _code!,
                        key: const ValueKey('generated-pairing-code'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          await Clipboard.setData(ClipboardData(text: _code!));
                          if (mounted) setState(() => _copied = true);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not copy. Select the code to copy it manually.'),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(_copied ? Icons.check : Icons.copy),
                      label: Text(
                        _copied ? 'Copied' : 'Copy code',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'On the child phone, open the app, choose Connect child device, and enter this code.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'For this demo, sign out and choose Connect child device in the same app. Cross-phone pairing, code expiry, and saved connections are not active yet.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) => PopScope(
    canPop: !_isLoading,
    child: AlertDialog(
      title: Text(
        _code == null ? 'Connect a child phone' : 'Your pairing code',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: _code == null
              ? Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add your child’s details, then generate a code to enter on their phone. Your child does not need an account.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _childController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Child name',
                          prefixIcon: Icon(Icons.child_care),
                        ),
                        validator: (value) =>
                            Validators.requiredText(value, 'Child name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deviceController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Device name',
                          hintText: 'Child’s Android phone',
                          prefixIcon: Icon(Icons.smartphone),
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
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_childController.text.trim()} • ${_deviceController.text.trim()}',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _code!,
                        key: const ValueKey('generated-pairing-code'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await Clipboard.setData(ClipboardData(text: _code!));
                          if (mounted) setState(() => _copied = true);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not copy. Select the code to copy it manually.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(_copied ? Icons.check : Icons.copy),
                      label: Text(_copied ? 'Copied' : 'Copy code'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'On the child phone, open the app, choose Connect child device, and enter this code.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'For this demo, sign out and choose Connect child device in the same app. Cross-phone pairing, code expiry, and saved connections are not active yet.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
        ),
      ),
      actions: _code != null
          ? [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _generate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  _isLoading ? 'Generating…' : 'Generate pairing code',
                ),
              ),
            ],
    ),
  );
}

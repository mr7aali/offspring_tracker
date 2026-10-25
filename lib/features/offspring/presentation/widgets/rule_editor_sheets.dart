import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/tracked_app.dart';

/// Rule editors shared by the parent dashboard and the self-mode dashboard.

typedef WebsiteRuleDraft = ({String domain, bool includesSubdomains});

/// Asks for a daily limit in minutes. Returns null when dismissed.
Future<int?> showAppLimitSheet(
  BuildContext context, {
  required TrackedApp app,
  required IconData icon,
  required Color color,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppLimitSheet(app: app, icon: icon, color: color),
  );
}

/// Asks for a domain to block. Returns null when dismissed.
Future<WebsiteRuleDraft?> showAddWebsiteSheet(BuildContext context) {
  return showModalBottomSheet<WebsiteRuleDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddWebsiteSheet(),
  );
}

// Each sheet owns its text controller so it stays valid while the sheet
// animates closed, and is disposed with the sheet.

class _AppLimitSheet extends StatefulWidget {
  const _AppLimitSheet({
    required this.app,
    required this.icon,
    required this.color,
  });

  final TrackedApp app;
  final IconData icon;
  final Color color;

  @override
  State<_AppLimitSheet> createState() => _AppLimitSheetState();
}

class _AppLimitSheetState extends State<_AppLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _minutesController = TextEditingController(
    text: widget.app.dailyLimitMinutes.toString(),
  );

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(int.parse(_minutesController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            icon: widget.icon,
            color: widget.color,
            title: 'Set limit for ${widget.app.name}',
            subtitle: 'Daily screen time allowance',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Daily minutes',
                prefixIcon: const Icon(Icons.timer_outlined),
                suffixText: 'min',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onFieldSubmitted: (_) => _save(),
              validator: (value) {
                final minutes = int.tryParse(value ?? '');
                if (minutes == null || minutes < 0 || minutes > 1440) {
                  return 'Enter 0 to 1440 minutes';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in const [
                ('No limit', 0),
                ('15m', 15),
                ('30m', 30),
                ('1h', 60),
                ('2h', 120),
              ])
                ActionChip(
                  onPressed: () => _minutesController.text = value.toString(),
                  label: Text(label),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: colors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(height: 32),
          _SheetPrimaryButton(label: 'Save Limit', onPressed: _save),
        ],
      ),
    );
  }
}

class _AddWebsiteSheet extends StatefulWidget {
  const _AddWebsiteSheet();

  @override
  State<_AddWebsiteSheet> createState() => _AddWebsiteSheetState();
}

class _AddWebsiteSheetState extends State<_AddWebsiteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  bool _includesSubdomains = true;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop((
        domain: _domainController.text.trim(),
        includesSubdomains: _includesSubdomains,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            icon: Icons.public,
            color: colors.primary,
            title: 'Add blocked domain',
            subtitle: 'Block access to a website',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _domainController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Domain',
                    hintText: 'example.com',
                    prefixIcon: const Icon(Icons.language),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onFieldSubmitted: (_) => _save(),
                  validator: Validators.domain,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _includesSubdomains,
                    onChanged: (value) {
                      setState(() => _includesSubdomains = value ?? true);
                    },
                    title: const Text(
                      'Block subdomains',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'e.g. news.example.com',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SheetPrimaryButton(label: 'Add Domain', onPressed: _save),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

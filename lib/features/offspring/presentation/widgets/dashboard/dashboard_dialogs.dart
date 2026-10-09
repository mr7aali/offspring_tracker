part of '../../screens/dashboard_screen.dart';

Future<void> _showPairDeviceDialog(
  BuildContext context,
  DashboardController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PairChildDeviceDialog(controller: controller),
  );
}

Future<void> _showLimitDialog(
  BuildContext context,
  DashboardController controller,
  TrackedApp app,
) async {
  final textController = TextEditingController(
    text: app.dailyLimitMinutes.toString(),
  );
  final formKey = GlobalKey<FormState>();

  final minutes = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
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
                          color: _categoryColor(app.category).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon(app.category), color: _categoryColor(app.category)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set limit for ${app.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Daily screen time allowance',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Input Form
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: textController,
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
                  // Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetChip(label: 'No limit', value: 0, textController: textController),
                      _PresetChip(label: '15m', value: 15, textController: textController),
                      _PresetChip(label: '30m', value: 30, textController: textController),
                      _PresetChip(label: '1h', value: 60, textController: textController),
                      _PresetChip(label: '2h', value: 120, textController: textController),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Actions
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).pop(int.parse(textController.text));
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Limit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  if (minutes != null) {
    await controller.updateAppLimit(app, minutes);
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.value,
    required this.textController,
  });

  final String label;
  final int value;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {
        textController.text = value.toString();
      },
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

Future<void> _showWebsiteDialog(
  BuildContext context,
  DashboardController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final domainController = TextEditingController();
  var includesSubdomains = true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
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
                        child: Icon(Icons.public, color: colors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add blocked domain',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Block access to a website',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Input Form
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: domainController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Domain',
                            hintText: 'example.com',
                            prefixIcon: const Icon(Icons.language),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: Validators.domain,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: CheckboxListTile(
                            value: includesSubdomains,
                            onChanged: (value) {
                              setState(() => includesSubdomains = value ?? true);
                            },
                            title: const Text(
                              'Block subdomains',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              'e.g. news.example.com',
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Actions
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Domain',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  if (result == true) {
    await controller.addWebsiteRule(
      domain: domainController.text,
      includesSubdomains: includesSubdomains,
    );
  }
}

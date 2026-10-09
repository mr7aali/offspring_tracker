part of '../../screens/dashboard_screen.dart';

Future<void> _showPairDeviceDialog(
  BuildContext context,
  DashboardController controller,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
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

  final minutes = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Set ${app.name} limit'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily minutes',
                prefixIcon: Icon(Icons.timer_outlined),
                helperText: 'Use 0 for no limit',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(int.parse(textController.text));
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (minutes != null) {
    await controller.updateAppLimit(app, minutes);
  }
  textController.dispose();
}

Future<void> _showWebsiteDialog(
  BuildContext context,
  DashboardController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final domainController = TextEditingController();
  var includesSubdomains = true;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add blocked domain'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: domainController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        hintText: 'example.com',
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: Validators.domain,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: includesSubdomains,
                      onChanged: (value) {
                        setState(() => includesSubdomains = value ?? true);
                      },
                      title: const Text('Block subdomains'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == true) {
    await controller.addWebsiteRule(
      domain: domainController.text,
      includesSubdomains: includesSubdomains,
    );
  }
  domainController.dispose();
}

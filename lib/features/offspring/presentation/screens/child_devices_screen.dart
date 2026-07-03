part of 'dashboard_screen.dart';

void _openChildDevicesScreen(
  BuildContext context,
  DashboardController controller,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => _ChildDevicesScreen(controller: controller),
    ),
  );
}

class _ChildDevicesScreen extends StatelessWidget {
  const _ChildDevicesScreen({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child devices'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FilledButton.icon(
                onPressed: () => _showPairDeviceDialog(context, controller),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Pair'),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final selectedDevice = controller.selectedDevice;
          final onlineDevices = controller.devices
              .where((device) => device.isOnline)
              .length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SettingsPageHeader(
                        icon: Icons.devices_other_outlined,
                        title: 'Manage child devices',
                        subtitle:
                            'Choose the active device once and the dashboard will use it everywhere.',
                      ),
                      const SizedBox(height: AppSizes.sectionGap),
                      _MetricGrid(
                        children: [
                          MetricCard(
                            label: 'Paired',
                            value: '${controller.devices.length}',
                            icon: Icons.devices,
                            color: AppColors.primary,
                          ),
                          MetricCard(
                            label: 'Online',
                            value: '$onlineDevices',
                            icon: Icons.wifi,
                            color: AppColors.secondary,
                          ),
                          MetricCard(
                            label: 'Active device',
                            value: selectedDevice?.childName ?? 'None',
                            icon: Icons.smartphone,
                            color: AppColors.accent,
                          ),
                          MetricCard(
                            label: 'Protections',
                            value:
                                '${selectedDevice?.enabledProtectionCount ?? 0}/4',
                            icon: Icons.verified_user_outlined,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sectionGap),
                      if (controller.devices.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.devices_other,
                          title: 'No devices paired',
                          message:
                              'Pair a child Android device before managing rules or reports.',
                          action: FilledButton.icon(
                            onPressed: () =>
                                _showPairDeviceDialog(context, controller),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Pair device'),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 820;
                            final selector = _DevicePickerCard(
                              controller: controller,
                            );
                            final status = _ProtectionStatusCard(
                              device: selectedDevice,
                            );

                            if (!isWide) {
                              return Column(
                                children: [
                                  selector,
                                  const SizedBox(height: AppSizes.cardGap),
                                  status,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: selector),
                                const SizedBox(width: AppSizes.cardGap),
                                Expanded(child: status),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

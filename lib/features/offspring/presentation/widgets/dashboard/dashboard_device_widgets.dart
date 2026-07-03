part of '../../screens/dashboard_screen.dart';

class _GlobalDeviceButton extends StatelessWidget {
  const _GlobalDeviceButton({required this.controller, required this.compact});

  final DashboardController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final device = controller.selectedDevice;
    if (compact) {
      return IconButton(
        tooltip: device == null
            ? 'Manage child devices'
            : 'Active device: ${device.childName}',
        onPressed: () => _openChildDevicesScreen(context, controller),
        icon: Badge(
          isLabelVisible: device?.isOnline ?? false,
          smallSize: 8,
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.smartphone),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          device?.isOnline ?? false ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: device?.isOnline ?? false
              ? AppColors.secondary
              : AppColors.muted,
        ),
        label: Text(
          device == null
              ? 'Child devices'
              : '${device.childName} - ${device.deviceName}',
          overflow: TextOverflow.ellipsis,
        ),
        tooltip: 'Manage child devices',
        onPressed: () => _openChildDevicesScreen(context, controller),
      ),
    );
  }
}

class _ActiveDeviceBanner extends StatelessWidget {
  const _ActiveDeviceBanner({
    required this.controller,
    this.message = 'This section follows the active child device.',
  });

  final DashboardController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    final device = controller.selectedDevice;
    if (device == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final title = Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  device.childName.isEmpty ? '?' : device.childName[0],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${device.childName} - ${device.deviceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = TextButton.icon(
            onPressed: () => _openChildDevicesScreen(context, controller),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Change'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), action],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _DevicePickerCard extends StatelessWidget {
  const _DevicePickerCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active child device',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showPairDeviceDialog(context, controller),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pair'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose once here. Apps, websites, reports, and protection status will use this device.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final device in controller.devices) ...[
              _DevicePickerTile(
                device: device,
                selected: device.id == controller.selectedDevice?.id,
                onTap: () => controller.selectDevice(device.id),
              ),
              if (device != controller.devices.last)
                const Divider(height: 12, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _DevicePickerTile extends StatelessWidget {
  const _DevicePickerTile({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final ChildDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${device.deviceName} - ${device.platform}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OnlineStatusPill(isOnline: device.isOnline),
          ],
        ),
      ),
    );
  }
}

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice? device;

  @override
  Widget build(BuildContext context) {
    final currentDevice = device;
    if (currentDevice == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child device protection',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentDevice.deviceName} last synced ${DateFormatter.relative(currentDevice.lastSyncAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _ProtectionRow(
              label: 'Usage access',
              enabled: currentDevice.usageAccessEnabled,
              icon: Icons.query_stats,
            ),
            _ProtectionRow(
              label: 'VPN/domain filter',
              enabled: currentDevice.vpnFilterEnabled,
              icon: Icons.vpn_lock_outlined,
            ),
            _ProtectionRow(
              label: 'Background service',
              enabled: currentDevice.backgroundServiceRunning,
              icon: Icons.sync,
            ),
            _ProtectionRow(
              label: 'Protected mode',
              enabled: currentDevice.protectedModeEnabled,
              icon: Icons.admin_panel_settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.label,
    required this.enabled,
    required this.icon,
  });

  final String label;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final title = Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.secondary : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
          final status = StatusPill(
            label: enabled ? 'Active' : 'Needs setup',
            icon: enabled ? Icons.check_circle : Icons.info_outline,
            color: enabled ? AppColors.secondary : AppColors.accent,
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), status],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 10),
              status,
            ],
          );
        },
      ),
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paired devices',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final device in controller.devices) ...[
              InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                onTap: () => controller.selectDevice(device.id),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${device.deviceName} - ${device.platform}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: isCompact
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: device.id == controller.selectedDevice?.id
                                  ? 0.18
                                  : 0.08,
                            ),
                            child: Text(
                              device.childName.isEmpty
                                  ? '?'
                                  : device.childName[0],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isCompact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      details,
                                      const SizedBox(height: 8),
                                      OnlineStatusPill(
                                        isOnline: device.isOnline,
                                      ),
                                    ],
                                  )
                                : details,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 10),
                            OnlineStatusPill(isOnline: device.isOnline),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (device != controller.devices.last)
                const Divider(height: 12, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}
